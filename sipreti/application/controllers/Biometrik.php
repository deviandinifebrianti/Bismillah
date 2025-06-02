<?php
// Controller Biometrik (application/controllers/Biometrik.php)
defined('BASEPATH') OR exit('No direct script access allowed');

class Biometrik extends CI_Controller {
    
    public function __construct() {
        parent::__construct();
        $this->load->model('Biometrik_model');
        $this->load->library('form_validation');
        $this->load->helper(array('form', 'url', 'file'));
        
        // Cek session login jika diperlukan
        // if (!$this->session->userdata('logged_in')) {
        //     redirect('login');
        // }
    }
    
    // Halaman utama - list biometrik
    public function index() {
        $search = $this->input->get('search');
        $data['title'] = 'Biometrik Pegawai';
        $data['biometrik'] = $this->Biometrik_model->get_all_biometrik_with_details($search)->result();
        $data['search'] = $search;
        
        $this->load->view('biometrik/biometrik_list', $data);
    }
    
    // Halaman form tambah biometrik (YANG LAMA - tetap dipertahankan)
    public function biometrik_form() {
        $data['title'] = 'Tambah Data Biometrik';
        $data['pegawai'] = $this->Biometrik_model->get_all_pegawai_with_details()->result();
        $data['action'] = 'add';
        
        // Jika ada parameter id_pegawai dari URL (untuk integrasi dengan halaman kelola)
        $id_pegawai = $this->input->get('id_pegawai');
        if ($id_pegawai) {
            $data['selected_pegawai'] = $id_pegawai;
        }
        
        $this->load->view('biometrik/tambah_biometrik', $data);
    }
    
    // BARU: Halaman form tambah foto dengan Django processing
    public function tambah_foto() {
        $data['title'] = 'Tambah Foto Biometrik';
        $data['pegawai'] = $this->Biometrik_model->get_all_pegawai_with_details()->result();
        $data['action'] = 'add_photo';
        
        // Jika ada parameter id_pegawai dari URL
        $id_pegawai = $this->input->get('id_pegawai');
        if ($id_pegawai) {
            $data['selected_pegawai'] = $id_pegawai;
        }
        
        // PASTIKAN menggunakan view yang benar
        $this->load->view('biometrik/tambah_biometrik', $data);
    }
    
    // TAMBAHAN: Method tambah_biometrik (sesuai link yang Anda buat)
    public function tambah_biometrik() {
        $data['title'] = 'Tambah Foto Biometrik';
        $data['pegawai'] = $this->Biometrik_model->get_all_pegawai_with_details()->result();
        $data['action'] = 'add_photo';
        
        // Jika ada parameter id_pegawai dari URL
        $id_pegawai = $this->input->get('id_pegawai');
        if ($id_pegawai) {
            $data['selected_pegawai'] = $id_pegawai;
        }
        
        // Gunakan view dengan nama yang konsisten
        $this->load->view('biometrik/tambah_biometrik', $data);
    }
    
    // Halaman kelola biometrik (untuk multiple foto) - YANG DIMODIFIKASI
    public function kelola($id) {
        // Ambil data biometrik dengan detail pegawai, jabatan, dan unit kerja
        $biometrik = $this->Biometrik_model->get_biometrik_with_details($id);
        
        if ($biometrik->num_rows() == 0) {
            show_404();
        }
        
        $data['title'] = 'Kelola Biometrik';
        $data['biometrik'] = $biometrik->row();
        
        // Ambil semua foto biometrik untuk pegawai ini
        $this->db->where('id_pegawai', $data['biometrik']->id_pegawai);
        $data['all_biometrik'] = $this->db->get('sipreti_biometrik')->result();
        
        // DEBUG: Cek data foto
        foreach ($data['all_biometrik'] as $foto) {
            $file_path = './uploads/biometrik/' . $foto->image;
            error_log("Foto ID: " . $foto->id . " | Image: " . $foto->image . " | File exists: " . (file_exists($file_path) ? 'Yes' : 'No'));
        }
        
        $this->load->view('biometrik/kelola_biometrik', $data);
    }
    
    // Export CSV - DIMODIFIKASI UNTUK INCLUDE JABATAN DAN UNIT KERJA
    public function export_csv() {
        $this->load->helper('download');
        
        $biometrik = $this->Biometrik_model->get_all_biometrik_with_details()->result_array();
        
        $csv_content = "No,Nama,NIP,Jabatan,Unit Kerja,Face ID,Tanggal Dibuat\n";
        $no = 1;
        foreach ($biometrik as $row) {
            $csv_content .= $no++ . ",";
            $csv_content .= '"' . ($row['nama'] ? $row['nama'] : $row['name']) . '",';
            $csv_content .= '"' . ($row['nip'] ? $row['nip'] : $row['id_pegawai']) . '",';
            $csv_content .= '"' . ($row['nama_jabatan'] ? $row['nama_jabatan'] : '-') . '",';
            $csv_content .= '"' . ($row['nama_unit_kerja'] ? $row['nama_unit_kerja'] : '-') . '",';
            $csv_content .= '"' . $row['face_id'] . '",';
            $csv_content .= '"' . date('d-m-Y H:i:s', strtotime($row['created_at'])) . '"';
            $csv_content .= "\n";
        }
        
        force_download('data_biometrik_' . date('Y-m-d') . '.csv', $csv_content);
    }
    
    // Import CSV (halaman form)
    public function import_csv() {
        $data['title'] = 'Import CSV Biometrik';
        $this->load->view('biometrik/import', $data);
    }
    
    // Edit foto biometrik individual - DIMODIFIKASI
    public function edit_foto($id) {
        $biometrik = $this->Biometrik_model->get_biometrik_with_details($id);
        
        if ($biometrik->num_rows() == 0) {
            show_404();
        }
        
        $data['title'] = 'Edit Foto Biometrik';
        $data['biometrik'] = $biometrik->row();
        $data['pegawai'] = $this->Biometrik_model->get_all_pegawai_with_details()->result();
        $data['action'] = 'edit';
        
        // PERBAIKAN: Gunakan view yang benar
        $this->load->view('biometrik/biometrik_form', $data);
    }
    
    // Proses simpan data (YANG LAMA - tetap dipertahankan untuk backward compatibility)
    public function save() {
        $this->_set_validation_rules();
        
        if ($this->form_validation->run() == FALSE) {
            $this->session->set_flashdata('error', validation_errors());
            redirect('biometrik/biometrik_form');
        }
        
        // Cek duplikasi pegawai
        if ($this->Biometrik_model->check_existing_biometrik($this->input->post('id_pegawai'))) {
            $this->session->set_flashdata('error', 'Pegawai sudah memiliki data biometrik!');
            redirect('biometrik/biometrik_form');
        }
        
        $data = array(
            'id_pegawai' => $this->input->post('id_pegawai'),
            'name' => $this->input->post('name'),
            'face_id' => $this->input->post('face_id'),
            'face_vector' => $this->input->post('face_vector'),
            'created_at' => date('Y-m-d H:i:s')
        );
        
        // Handle upload gambar
        if (!empty($_FILES['image']['name'])) {
            $upload_result = $this->_upload_image();
            if ($upload_result['status']) {
                $data['image'] = $upload_result['file_name'];
            } else {
                $this->session->set_flashdata('error', $upload_result['message']);
                redirect('biometrik/biometrik_form');
            }
        }
        
        if ($this->Biometrik_model->insert_biometrik($data)) {
            $this->session->set_flashdata('success', 'Data biometrik berhasil disimpan!');
        } else {
            $this->session->set_flashdata('error', 'Gagal menyimpan data biometrik!');
        }
        
        redirect('biometrik');
    }
    
    public function save_photo() {
    // Session lock
    $last_upload = $this->session->userdata('uploading_photo');
    if ($last_upload && (time() - $last_upload) < 300) { // 5 menit
        $this->session->set_flashdata('error', 'Proses sedang berlangsung, tunggu 5 menit!');
        redirect('biometrik/tambah_biometrik');
        return;
    }
    $this->session->set_userdata('uploading_photo', time());
    
    // Validasi
    $this->form_validation->set_rules('id_pegawai', 'Pegawai', 'required');
    if ($this->form_validation->run() == FALSE) {
        $this->session->unset_userdata('uploading_photo');
        $this->session->set_flashdata('error', validation_errors());
        redirect('biometrik/tambah_biometrik');
        return;
    }
    
    $id_pegawai = $this->input->post('id_pegawai');
    
    // Validasi file upload
    if (empty($_FILES['image']['name'])) {
        $this->session->unset_userdata('uploading_photo');
        $this->session->set_flashdata('error', 'Foto harus diupload!');
        redirect('biometrik/tambah_biometrik');
        return;
    }
    
    // Get pegawai data
    $pegawai = $this->Biometrik_model->get_pegawai_with_details($id_pegawai)->row();
    if (!$pegawai) {
        $this->session->unset_userdata('uploading_photo');
        $this->session->set_flashdata('error', 'Data pegawai tidak ditemukan!');
        redirect('biometrik/tambah_biometrik');
        return;
    }
    
    // KIRIM LANGSUNG KE DJANGO (tidak simpan di CI)
    $django_result = $this->_send_to_django('', $pegawai);
    
    if ($django_result['status']) {
        // Django berhasil memproses dan menyimpan
        $this->session->unset_userdata('uploading_photo');
        $this->session->set_flashdata('success', 'Foto berhasil diupload! Face ID: ' . $django_result['data']['face_id']);
        redirect('biometrik');
    } else {
        // Django gagal
        $this->session->unset_userdata('uploading_photo');
        $this->session->set_flashdata('error', 'Gagal memproses foto: ' . $django_result['message']);
        redirect('biometrik/tambah_biometrik');
    }
}

// PERBAIKAN: Method _send_to_django - LANGSUNG KIRIM $_FILES KE DJANGO
private function _send_to_django($image_filename, $pegawai_data) {
    // Konfigurasi URL Django
    $django_url = 'http://localhost:8000/sipreti/sipreti_add_image';
    
    // Validasi file upload
    if (empty($_FILES['image']['tmp_name']) || !file_exists($_FILES['image']['tmp_name'])) {
        return array(
            'status' => false,
            'message' => 'File tidak valid'
        );
    }
    
    // Generate Face ID unik
    $face_id = $pegawai_data->id_pegawai . '.' . time() . '.' . rand(100, 999);
    $foto_name = $pegawai_data->nama . ' - Foto ' . date('Y-m-d H:i:s');
    
    // Prepare data untuk dikirim ke Django - LANGSUNG DARI $_FILES
    $data = array(
        'image' => new CURLFile($_FILES['image']['tmp_name'], $_FILES['image']['type'], $_FILES['image']['name']),
        'id_pegawai' => $pegawai_data->id_pegawai,
        'face_id' => $face_id,
        'name' => $foto_name
    );
    
    // Initialize cURL
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $django_url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 120); // 120 second timeout
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        'Accept: application/json'
    ));
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curl_error = curl_error($ch);
    curl_close($ch);
    
    // Handle cURL errors
    if ($response === false) {
        return array(
            'status' => false,
            'message' => 'Tidak dapat terhubung ke server pemrosesan wajah: ' . $curl_error
        );
    }
    
    // Parse response
    $result = json_decode($response, true);
    
    if ($http_code == 200 && $result && isset($result['status']) && $result['status'] == 1) {
        return array(
            'status' => true,
            'data' => array(
                'name' => $foto_name,
                'face_id' => $face_id,
                'face_vector' => isset($result['face_vector']) ? $result['face_vector'] : '',
                'image_url' => isset($result['image_url']) ? $result['image_url'] : ''
            )
        );
    } else {
        $error_message = isset($result['message']) ? $result['message'] : 'Gagal memproses wajah';
        return array(
            'status' => false,
            'message' => $error_message
        );
    }
}

    
    // Proses update data
    public function update($id) {
        $this->_set_validation_rules();
        
        if ($this->form_validation->run() == FALSE) {
            $this->session->set_flashdata('error', validation_errors());
            redirect('biometrik/edit_foto/' . $id);
        }
        
        // Cek duplikasi pegawai (kecuali data sendiri)
        if ($this->Biometrik_model->check_existing_biometrik($this->input->post('id_pegawai'), $id)) {
            $this->session->set_flashdata('error', 'Pegawai sudah memiliki data biometrik!');
            redirect('biometrik/edit_foto/' . $id);
        }
        
        $data = array(
            'id_pegawai' => $this->input->post('id_pegawai'),
            'name' => $this->input->post('name'),
            'face_id' => $this->input->post('face_id'),
            'face_vector' => $this->input->post('face_vector'),
            'updated_at' => date('Y-m-d H:i:s')
        );
        
        // Handle upload gambar baru
        if (!empty($_FILES['image']['name'])) {
            $upload_result = $this->_upload_image();
            if ($upload_result['status']) {
                // Hapus gambar lama jika ada
                $old_data = $this->Biometrik_model->get_biometrik_by_id($id)->row();
                if (!empty($old_data->image) && file_exists('./uploads/biometrik/' . $old_data->image)) {
                    unlink('./uploads/biometrik/' . $old_data->image);
                }
                $data['image'] = $upload_result['file_name'];
                
                // BARU: Jika ada foto baru, proses ulang dengan Django
                $pegawai = $this->Biometrik_model->get_pegawai_with_details($this->input->post('id_pegawai'))->row();
                if ($pegawai) {
                    $django_result = $this->_send_to_django($upload_result['file_name'], $pegawai);
                    if ($django_result['status']) {
                        $data['name'] = $django_result['data']['name'];
                        $data['face_id'] = $django_result['data']['face_id'];
                        $data['face_vector'] = $django_result['data']['face_vector'];
                    }
                }
            } else {
                $this->session->set_flashdata('error', $upload_result['message']);
                redirect('biometrik/edit_foto/' . $id);
            }
        }
        
        if ($this->Biometrik_model->update_biometrik($id, $data)) {
            $this->session->set_flashdata('success', 'Data biometrik berhasil diupdate!');
            redirect('biometrik/kelola_biometrik/' . $id);
        } else {
            $this->session->set_flashdata('error', 'Gagal mengupdate data biometrik!');
            redirect('biometrik/edit_foto/' . $id);
        }
    }
    
    // Hapus data biometrik
   public function delete() {
    $id = $this->input->post('id');
    
    if ($this->Biometrik_model->delete_biometrik($id)) {
        $this->session->set_flashdata('success', 'Berhasil dihapus!');
    } else {
        $this->session->set_flashdata('error', 'Gagal dihapus!');
    }
    
    redirect('biometrik');
}
    
    
    // BARU: Fungsi untuk edit foto via Django
    public function _edit_image_django($face_id, $name, $image_url) {
        $django_url = 'http://localhost:8000/sipreti/edit_image'; // Sesuaikan dengan URL Django
        
        $data = array(
            'face_id' => $face_id,
            'name' => $name,
            'url_image' => $image_url
        );
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $django_url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 120);
        
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($response === false) {
            return array('status' => false, 'message' => 'Connection failed');
        }
        
        $result = json_decode($response, true);
        
        if ($http_code == 200 && $result && isset($result['status']) && $result['status'] == 1) {
            return array('status' => true, 'face_id' => $result['face_id']);
        } else {
            $error_message = isset($result['message']) ? $result['message'] : 'Edit failed';
            return array('status' => false, 'message' => $error_message);
        }
    }
    
    // AJAX untuk mendapatkan data pegawai - DIMODIFIKASI
    public function get_pegawai_data($id_pegawai) {
        $pegawai = $this->Biometrik_model->get_all_pegawai_with_details()->result();
        
        foreach ($pegawai as $p) {
            if ($p->id_pegawai == $id_pegawai) {
                echo json_encode($p);
                return;
            }
        }
        
        echo json_encode(null);
    }
}