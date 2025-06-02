<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Api extends CI_Controller {
    
    public function __construct() {
        parent::__construct();
        // Load libraries yang diperlukan
        $this->load->helper(['form', 'url']);
        $this->load->library('upload');
    }
    
    // Endpoint untuk menerima request dari aplikasi lain atau Postman
    public function add_image() {
        // Set header response sebagai JSON
        header('Content-Type: application/json');
        
        // Cek apakah ini request POST
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            echo json_encode(['status' => 0, 'message' => 'Method not allowed']);
            return;
        }
        
        // Cek apakah file dikirim
        if (!isset($_FILES['image_file']) || $_FILES['image_file']['error'] != 0) {
            // Coba cek jika gambar dikirim sebagai base64
            if (!isset($_POST['url_image'])) {
                echo json_encode(['status' => 0, 'message' => 'No image provided']);
                return;
            }
            
            // Gunakan gambar base64 jika ada
            $base64_image = $_POST['url_image'];
        } else {
            // Jika file gambar dikirim, proses upload dahulu
            $config['upload_path'] = './uploads/biometrik/';
            $config['allowed_types'] = 'gif|jpg|jpeg|png';
            $config['max_size'] = 2048;
            
            $this->upload->initialize($config);
            
            if (!$this->upload->do_upload('image_file')) {
                echo json_encode(['status' => 0, 'message' => $this->upload->display_errors('', '')]);
                return;
            }
            
            $upload_data = $this->upload->data();
            $file_path = $config['upload_path'] . $upload_data['file_name'];
            
            // Konversi gambar ke base64
            $image_data = file_get_contents($file_path);
            $base64_image = base64_encode($image_data);
        }
        
        // Ambil data lainnya
        $id_pegawai = $this->input->post('id_pegawai');
        $name = $this->input->post('name');
        
        if (!$id_pegawai || !$name) {
            echo json_encode(['status' => 0, 'message' => 'Missing required parameters']);
            return;
        }
        
        // Data untuk dikirim ke Django
        $post_data = [
            'url_image' => $base64_image,
            'id_pegawai' => $id_pegawai,
            'name' => $name
        ];
        
        // Kirim ke Django API
        $response = $this->send_to_django_api($post_data);
        
        // Kembalikan response dari Django
        echo json_encode($response);
    }
    
    private function send_to_django_api($data) {
        $django_api_url = 'http://localhost:8000/add_image/'; // Sesuaikan dengan URL Django
        
        $ch = curl_init($django_api_url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/x-www-form-urlencoded',
            'Accept: application/json'
        ]);
        
        $response = curl_exec($ch);
        
        if (curl_errno($ch)) {
            $error_msg = curl_error($ch);
            curl_close($ch);
            return ['status' => 0, 'message' => 'Curl error: ' . $error_msg];
        }
        
        curl_close($ch);
        return json_decode($response, true);
    }
}