<?php

if (!defined('BASEPATH')) exit('No direct script access allowed');

class Vektor_pegawai extends CI_Controller
{
	function __construct()
	{
		parent::__construct();
		$this->load->model('Vektor_pegawai_model');
		$this->load->model('Pegawai_model');
		$this->load->library('form_validation');
	}

	// Halaman utama daftar pegawai
	public function index()
	{
		$result = $this->Vektor_pegawai_model->get_all_pegawai(false);

		$grouped = [];
		foreach ($result as $row) {
			$id = $row->id_pegawai;

			if (!isset($grouped[$id])) {
				$grouped[$id] = [
					'id_pegawai' => $row->id_pegawai,
					'nama' => $row->nama,
					'created_at' => $row->created_at,
					'foto_list' => [],
					'id_vektor_pegawai' => $row->id_vektor_pegawai
				];
			}
			$grouped[$id]['foto_list'][] = $row->image;
		}

		$data['vektor_pegawai'] = array_values($grouped);
		$this->load->view('vektor_pegawai/vektor_pegawai_list', $data);
	}

	// Form tambah
	public function create()
	{
		$data = [
			'action' => site_url('vektor_pegawai/create_action'),
			'button' => 'Tambah',
			'id_vektor_pegawai' => set_value('id_vektor_pegawai'),
			'id_pegawai' => set_value('id_pegawai'),
			'image' => set_value('image'),
			'face_embeddings' => set_value('face_embeddings'),
			'pegawai_list' => $this->Pegawai_model->get_all_pegawai()
		];
		$this->load->view('vektor_pegawai/vektor_pegawai_form', $data);
	}

	// Simpan data
	public function create_action() {
		$id_pegawai = $this->input->post('id_pegawai');
		$tanggal_jam = date('Ymd_His');
		$ext = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
		$nama_file = 'pegawai' . $id_pegawai . '_' . $tanggal_jam . '.' . $ext;
	
		// Upload ke lokal (sementara)
		$config['upload_path'] = './uploads/';
		$config['allowed_types'] = 'jpg|jpeg|png';
		$config['file_name'] = $nama_file;
		$config['max_size'] = 2048;
	
		$this->load->library('upload', $config);
	
		if (!$this->upload->do_upload('image')) {
			$this->session->set_flashdata('message', $this->upload->display_errors());
			redirect(site_url('vektor_pegawai/create'));
			return;
		}
	
		$upload_data = $this->upload->data();
		$lokal_path = './uploads/' . $upload_data['file_name'];
	
		// Mengirim file sebagai file biner, bukan hanya URL path
$cfile = new CURLFile(realpath($lokal_path), $upload_data['file_type'], $upload_data['file_name']);

$curl = curl_init();
curl_setopt_array($curl, array(
    CURLOPT_URL => 'http://127.0.0.1:8000/sipreti/add_image/', // URL API Django
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => array(
        'id_pegawai' => $id_pegawai,
        'image' => $cfile  // Pastikan key 'image' di backend Django sesuai
    ),
));

$response = curl_exec($curl);
curl_close($curl);

$result = json_decode($response, true);

if ($result['status'] == 1) {
    // Simpan ke CI DB juga (opsional)
    $this->Vektor_pegawai_model->insert([
        'id_pegawai' => $id_pegawai,
        'image' => $upload_data['file_name'],
        'face_embeddings' => null,
        'created_at' => date('Y-m-d H:i:s'),
        'updated_at' => date('Y-m-d H:i:s'),
        'deleted_at' => null,
    ]);

    $this->session->set_flashdata('message', 'Berhasil kirim ke Django dan simpan ke DB!');
} else {
    $this->session->set_flashdata('message', 'Gagal: ' . $result['message']);
}
	
		redirect(site_url('vektor_pegawai'));
	}
	
	// Hapus foto dari folder dan tandai deleted_at
	public function hapus_foto($filename)
	{
		$path = FCPATH . 'uploads/' . $filename;

		if (file_exists($path)) {
			unlink($path);
			$this->db->where('image', $filename);
			$this->db->update('vektor_pegawai', [
				'deleted_at' => date('Y-m-d H:i:s')
			]);
			$this->session->set_flashdata('message', 'Foto berhasil dihapus.');
		} else {
			$this->session->set_flashdata('message', 'Foto tidak ditemukan.');
		}

		redirect(site_url('vektor_pegawai'));
	}

	// Detail data
	public function read($id)
	{
		$row = $this->Vektor_pegawai_model->get_by_id($id);

		if ($row && empty($row->deleted_at)) {
			$data = (array) $row;
			$this->load->view('vektor_pegawai/vektor_pegawai_read', $data);
		} else {
			$this->session->set_flashdata('message', 'Record Not Found');
			redirect(site_url('vektor_pegawai'));
		}
	}

	// Hapus vektor pegawai
	public function delete($id)
	{
		$row = $this->Vektor_pegawai_model->get_by_id($id);

		if ($row) {
			$this->Vektor_pegawai_model->delete($id);
			$this->session->set_flashdata('message', 'Data berhasil dihapus');
		} else {
			$this->session->set_flashdata('message', 'Data tidak ditemukan');
		}
		redirect(site_url('vektor_pegawai'));
	}

	// Lihat vektor dari API
	public function lihat_vektor($id_pegawai)
	{
		$url = "http://192.168.1.14:8000/sipreti/face_vector/" . $id_pegawai;
		$ch = curl_init($url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		$response = curl_exec($ch);
		curl_close($ch);

		$data = json_decode($response, true);
		$face_vector = isset($data['face_vector']) ? $data['face_vector'] : null;

		$this->load->view('halaman_vektor_pegawai', [
			'face_vector' => $face_vector,
			'id_pegawai' => $id_pegawai
		]);
	}

	public function kirim_ke_django() {
		$id_pegawai = $this->input->post('id_pegawai');
		$file_path = $_FILES['image']['tmp_name'];
		$file_name = $_FILES['image']['name'];
	
		$cfile = new CURLFile($file_path, $_FILES['image']['type'], $file_name);
	
		$curl = curl_init();
	
		curl_setopt_array($curl, array(
			CURLOPT_URL => 'http://192.168.1.14:8000/enroll_face/',
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_POST => true,
			CURLOPT_POSTFIELDS => array(
				'id_pegawai' => $id_pegawai,
				'image' => $cfile
			),
		));
	
		$response = curl_exec($curl);
		curl_close($curl);
	
		$result = json_decode($response, true);
	
		if ($result['status'] == 1) {
			// Tambahkan ke log atau update status vektor berhasil
			$this->db->insert('log_vektor_pegawai', [
				'id_pegawai' => $id_pegawai,
				'face_id' => $result['face_id'],
				'image' => $result['url'],
				'waktu_sync' => date('Y-m-d H:i:s'),
			]);
	
			$this->session->set_flashdata('message', 'Vektor berhasil dibuat dan disimpan!');
		} else {
			$this->session->set_flashdata('message', 'Gagal: ' . $result['message']);
		}
	
		redirect(site_url('vektor_pegawai'));
	}
	
}
