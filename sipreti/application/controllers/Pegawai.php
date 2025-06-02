<?php

if (!defined('BASEPATH')) exit('No direct script access allowed');

class Pegawai extends CI_Controller
{
    private $django_server = 'http://192.168.1.14:8000'; // Sesuaikan dengan server Django Anda
    
    function __construct()
    {
        parent::__construct();
        $this->load->model('Pegawai_model');
        $this->load->model('Jabatan_model');        // ⬅️ Tambahkan ini
        $this->load->model('Unit_kerja_model');
        $this->load->library('form_validation');
        $this->load->library('upload');
    }

    public function index()
    {
        $q = urldecode($this->input->get('q', TRUE));
        $start = intval($this->input->get('start'));
        
        if ($q <> '') {
            $config['base_url'] = base_url() . 'pegawai?q=' . urlencode($q);
            $config['first_url'] = base_url() . 'pegawai?q=' . urlencode($q);
        } else {
            $config['base_url'] = base_url() . 'pegawai';
            $config['first_url'] = base_url() . 'pegawai';
        }

        $config['per_page'] = 10;
        $config['page_query_string'] = TRUE;
        $config['total_rows'] = $this->Pegawai_model->total_rows($q);
        $pegawai = $this->Pegawai_model->get_limit_data($config['per_page'], $start, $q);

        $this->load->library('pagination');
        $this->pagination->initialize($config);

        $data = array(
            'pegawai_data' => $pegawai,
            'q' => $q,
            'pagination' => $this->pagination->create_links(),
            'total_rows' => $config['total_rows'],
            'start' => $start,
        );
        $this->load->view('pegawai/pegawai_list', $data);
    }

    public function create()
    {
        $data = array(
            'button' => 'Tambah',
            'action' => site_url('pegawai/create_action'),
            'id_pegawai' => set_value('id_pegawai'),
            'nama' => set_value('nama'),
            'nip' => set_value('nip'),
            'email' => set_value('email'),
            'no_hp' => set_value('no_hp'),
            'id_jabatan' => set_value('id_jabatan'),
            'id_unit_kerja' => set_value('id_unit_kerja'), 
            'image' => set_value('image'),

            // ✅ Tambahkan ini
            'jabatan' => $this->Jabatan_model->get_all(),
            'unit_kerja' => $this->Unit_kerja_model->get_all(),
            'selected_unit' => set_value('id_unit_kerja'),
        );

        $this->load->view('pegawai/pegawai_form', $data);
    }

    public function create_action()
    {
        $this->_rules();

        if ($this->form_validation->run() == FALSE) {
            $this->create();
        } else {
            // Insert pegawai data terlebih dahulu untuk mendapatkan ID
            $data = array(
                'id_jabatan' => $this->input->post('id_jabatan', TRUE),
                'id_unit_kerja' => $this->input->post('id_unit_kerja', TRUE),
                'nip' => $this->input->post('nip', TRUE),
                'nama' => $this->input->post('nama', TRUE),
                'image' => '', // Akan diupdate setelah upload ke Django
                'email' => $this->input->post('email', TRUE),
                'no_hp' => $this->input->post('no_hp', TRUE),
                'created_at' => date('Y-m-d H:i:s'),
                'updated_at' => date('Y-m-d H:i:s')
            );

            // TAMBAHKAN INI untuk password di create
            $password = $this->input->post('password', TRUE);
            if (!empty($password)) {
                $data['password'] = $password;
            }
            
            // Handle photo upload ke Django jika ada
            if (!empty($_FILES['photo']['name'])) {
                $upload_result = $this->_upload_to_django($id_pegawai, $_FILES['photo']);
                
                if ($upload_result['success']) {
                    // Update image path di database lokal
                    $this->Pegawai_model->update($id_pegawai, array(
                        'image' => $upload_result['file_path'],
                        'updated_at' => date('Y-m-d H:i:s')
                    ));
                    
                    $this->session->set_flashdata('message', 'Data pegawai berhasil ditambahkan dengan foto');
                } else {
                    $this->session->set_flashdata('message', 'Data pegawai berhasil ditambahkan, namun foto gagal diupload: ' . $upload_result['error']);
                }
            } else {
                $this->session->set_flashdata('message', 'Data pegawai berhasil ditambahkan');
            }

            redirect(site_url('pegawai'));
        }
    }

    public function update($id)
    {
        $row = $this->Pegawai_model->get_by_id($id);

        if ($row) {
            $data = array(
                'button' => 'Ubah',
                'action' => site_url('pegawai/update_action'),
                'id_pegawai' => set_value('id_pegawai', $row->id_pegawai),
                'nama' => set_value('nama', $row->nama),
                'nip' => set_value('nip', $row->nip),
                'email' => set_value('email', $row->email),
                'no_hp' => set_value('no_hp', $row->no_hp),
                'id_jabatan' => set_value('id_jabatan', $row->id_jabatan),
                'id_unit_kerja' => set_value('id_unit_kerja', $row->id_unit_kerja),
                'image' => set_value('image', $row->image),
                'password' => '', // Jangan tampilkan password lama di form untuk security
                'jabatan' => $this->Jabatan_model->get_all(),
                'unit_kerja' => $this->Unit_kerja_model->get_all(),
                'selected_unit' => set_value('id_unit_kerja'),
            );
            $this->load->view('pegawai/pegawai_form', $data);
        } else {
            $this->session->set_flashdata('message', 'Data tidak ditemukan');
            redirect(site_url('pegawai'));
        }
    }

    public function update_action()
    {
        $this->_rules();

        if ($this->form_validation->run() == FALSE) {
            $this->update($this->input->post('id_pegawai', TRUE));
        } else {
            $id_pegawai = $this->input->post('id_pegawai', TRUE);
            $existing_data = $this->Pegawai_model->get_by_id($id_pegawai);
            
            $data = array(
                'id_jabatan' => $this->input->post('id_jabatan', TRUE),
                'id_unit_kerja' => $this->input->post('id_unit_kerja', TRUE),
                'nip' => $this->input->post('nip', TRUE),
                'nama' => $this->input->post('nama', TRUE),
                'email' => $this->input->post('email', TRUE),
                'no_hp' => $this->input->post('no_hp', TRUE),
                'updated_at' => date('Y-m-d H:i:s')
            );

            // TAMBAHKAN INI untuk handle password
            $password = $this->input->post('password', TRUE);
            if (!empty($password)) {
                // Bisa di-hash jika mau: $data['password'] = password_hash($password, PASSWORD_DEFAULT);
                $data['password'] = $password; // Atau langsung simpan plain text
            }

            // Handle photo upload ke Django jika ada file baru
            if (!empty($_FILES['photo']['name'])) {
                $upload_result = $this->_upload_to_django($id_pegawai, $_FILES['photo']);
                
                if ($upload_result['success']) {
                    $data['image'] = $upload_result['file_path'];
                    $message = 'Data pegawai berhasil diupdate dengan foto baru';
                } else {
                    $message = 'Data pegawai berhasil diupdate, namun foto gagal diupload: ' . $upload_result['error'];
                }
            } else {
                // Check if user wants to remove existing photo
                if (empty($this->input->post('existing_image', TRUE)) && !empty($existing_data->image)) {
                    // Delete photo from Django server
                    $this->_delete_from_django($id_pegawai);
                    $data['image'] = '';
                }
                $message = 'Data pegawai berhasil diupdate';
            }

            $this->Pegawai_model->update($id_pegawai, $data);
            $this->session->set_flashdata('message', $message);
            redirect(site_url('pegawai'));
        }
    }

    public function read($id)
    {
        $row = $this->Pegawai_model->get_by_id($id);
        if ($row) {
            $data = array(
                'id_pegawai' => $row->id_pegawai,
                'id_jabatan' => $row->id_jabatan,
                'id_unit_kerja' => $row->id_unit_kerja,
                'nip' => $row->nip,
                'nama' => $row->nama,
                'image' => $row->image,
                'email' => $row->email,
                'no_hp' => $row->no_hp,
            );
            $this->load->view('pegawai/pegawai_read', $data);
        } else {
            $this->session->set_flashdata('message', 'Record Not Found');
            redirect(site_url('pegawai'));
        }
    }

    public function delete($id)
    {
        $row = $this->Pegawai_model->get_by_id($id);

        if ($row) {
            // Delete photo from Django server if exists
            if (!empty($row->image)) {
                $this->_delete_from_django($id);
            }
            
            $this->Pegawai_model->delete($id);
            $this->session->set_flashdata('message', 'Data pegawai berhasil dihapus');
        } else {
            $this->session->set_flashdata('message', 'Data tidak ditemukan');
        }

        redirect(site_url('pegawai'));
    }

    // Upload foto ke Django server
    private function _upload_to_django($id_pegawai, $file_data)
    {
        try {
            // Create temporary file
            $temp_file = $file_data['tmp_name'];
            
            if (!file_exists($temp_file)) {
                return array(
                    'success' => false,
                    'error' => 'File temporary tidak ditemukan'
                );
            }

            // Prepare CURL request
            $cfile = new CURLFile($temp_file, $file_data['type'], $file_data['name']);
            
            $curl = curl_init();
            curl_setopt_array($curl, array(
                CURLOPT_URL => $this->django_server . '/sipreti/upload_profile_photo/',
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => array(
                    'id_pegawai' => $id_pegawai,
                    'profile_image' => $cfile
                ),
                CURLOPT_TIMEOUT => 30,
                CURLOPT_CONNECTTIMEOUT => 10
            ));

            $response = curl_exec($curl);
            $http_code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
            $curl_error = curl_error($curl);
            curl_close($curl);

            if ($curl_error) {
                return array(
                    'success' => false,
                    'error' => 'CURL Error: ' . $curl_error
                );
            }

            if ($http_code !== 200) {
                return array(
                    'success' => false,
                    'error' => 'HTTP Error: ' . $http_code
                );
            }

            $result = json_decode($response, true);
            
            if ($result && $result['status'] === 'success') {
                return array(
                    'success' => true,
                    'file_path' => $result['data']['file_path'],
                    'foto_url' => $result['data']['foto_url']
                );
            } else {
                $error_message = isset($result['message']) ? $result['message'] : 'Unknown error';
                return array(
                    'success' => false,
                    'error' => $error_message
                );
            }

        } catch (Exception $e) {
            return array(
                'success' => false,
                'error' => 'Exception: ' . $e->getMessage()
            );
        }
    }

    // Delete foto dari Django server
    private function _delete_from_django($id_pegawai)
    {
        try {
            $curl = curl_init();
            curl_setopt_array($curl, array(
                CURLOPT_URL => $this->django_server . '/sipreti/delete_profile_photo/' . $id_pegawai . '/',
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CUSTOMREQUEST => 'DELETE',
                CURLOPT_TIMEOUT => 30,
                CURLOPT_CONNECTTIMEOUT => 10
            ));

            $response = curl_exec($curl);
            $http_code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
            curl_close($curl);

            // Log result (optional)
            if ($http_code === 200) {
                log_message('info', "Photo deleted from Django server for pegawai ID: $id_pegawai");
            } else {
                log_message('error', "Failed to delete photo from Django server for pegawai ID: $id_pegawai, HTTP Code: $http_code");
            }

        } catch (Exception $e) {
            log_message('error', "Exception while deleting photo from Django: " . $e->getMessage());
        }
    }

    public function _rules()
    {
        $this->form_validation->set_rules('id_jabatan', 'ID Jabatan', 'trim|required');
        $this->form_validation->set_rules('id_unit_kerja', 'ID Unit Kerja', 'trim|required');
        $this->form_validation->set_rules('nip', 'NIP', 'trim|required');
        $this->form_validation->set_rules('nama', 'Nama', 'trim|required');
        $this->form_validation->set_rules('email', 'Email', 'trim|valid_email');
        $this->form_validation->set_rules('no_hp', 'No HP', 'trim');
        
        // TAMBAHKAN INI untuk password validation
        $this->form_validation->set_rules('password', 'Password', 'trim|min_length[6]');
        
        $this->form_validation->set_rules('id_pegawai', 'id_pegawai', 'trim');
        $this->form_validation->set_error_delimiters('<span class="error-text">', '</span>');
    }

    // API endpoint untuk Flutter - proxy ke Django
    public function get_profile_photo($id_pegawai)
    {
        try {
            $curl = curl_init();
            curl_setopt_array($curl, array(
                CURLOPT_URL => $this->django_server . '/sipreti/get_profile_photo/' . $id_pegawai . '/',
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 10,
                CURLOPT_CONNECTTIMEOUT => 5
            ));

            $response = curl_exec($curl);
            $http_code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
            curl_close($curl);

            if ($http_code === 200) {
                // Forward response dari Django
                header('Content-Type: application/json');
                echo $response;
            } else {
                // Fallback: check database lokal
                $pegawai = $this->Pegawai_model->get_by_id($id_pegawai);
                
                $response = array(
                    'status' => 'success',
                    'data' => array(
                        'has_photo' => !empty($pegawai->image),
                        'foto_url' => !empty($pegawai->image) ? 
                            $this->django_server . '/media/' . $pegawai->image : null,
                        'filename' => $pegawai->image ?? null
                    )
                );
                
                header('Content-Type: application/json');
                echo json_encode($response);
            }

        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'message' => $e->getMessage()
            );
            header('Content-Type: application/json');
            echo json_encode($response);
        }
    }
}