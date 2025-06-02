<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Verifikasi extends CI_Controller {
    
    public function __construct() {
        parent::__construct();
        // Load model yang diperlukan
        $this->load->model('kompresi_model');
        $this->load->model('biometrik_model');
        // Load helper
        $this->load->helper('url');
        $this->load->helper('file');
    }
    
    // Halaman utama verifikasi
    public function index() {
        // Ambil data kompresi untuk ditampilkan di daftar
        $data['kompresi_data'] = $this->kompresi_model->get_all_kompresi();
        $data['title'] = 'Verifikasi Dekompresi Wajah';
        
        // Load view
        $this->load->view('header', $data);
        $this->load->view('verifikasi/index', $data);
        $this->load->view('footer');
    }
    
    // Halaman detail dengan ID kompresi tertentu
    public function detail($kompresi_id = NULL) {
        if ($kompresi_id === NULL) {
            redirect('verifikasi');
        }
        
        // Ambil data kompresi
        $data['kompresi'] = $this->kompresi_model->get_kompresi($kompresi_id);
        if (empty($data['kompresi'])) {
            show_error('Data kompresi tidak ditemukan');
        }
        
        $data['title'] = 'Detail Verifikasi #' . $kompresi_id;
        
        // Load view
        $this->load->view('header', $data);
        $this->load->view('verifikasi/detail', $data);
        $this->load->view('footer');
    }
    
    // Endpoint untuk menampilkan gambar hasil dekompresi
    public function tampilkan_hasil($kompresi_id) {
        // Ambil data kompresi
        $kompresi = $this->kompresi_model->get_kompresi($kompresi_id);
        if (empty($kompresi)) {
            show_error('Data kompresi tidak ditemukan');
        }
        
        // Lakukan dekompresi
        $image_data = $this->dekompresi_huffman($kompresi);
        
        // Output gambar
        $this->output
            ->set_content_type('image/png')
            ->set_output($image_data);
    }
    
    // API endpoint untuk proses verifikasi
    public function proses_verifikasi($kompresi_id) {
        // Cek apakah request adalah AJAX
        if (!$this->input->is_ajax_request()) {
            show_error('Hanya menerima request AJAX');
        }
        
        // Ambil data kompresi
        $kompresi = $this->kompresi_model->get_kompresi($kompresi_id);
        if (empty($kompresi)) {
            $this->output
                ->set_content_type('application/json')
                ->set_output(json_encode([
                    'status' => 0,
                    'message' => 'Data kompresi tidak ditemukan'
                ]));
            return;
        }
        
        $start_time = microtime(true);
        
        try {
            // Lakukan dekompresi
            $dekompresi_start = microtime(true);
            $image_data = $this->dekompresi_huffman($kompresi);
            $dekompresi_time = microtime(true) - $dekompresi_start;
            
            // Simpan gambar ke file sementara
            $temp_folder = FCPATH . 'uploads/verification/' . $kompresi['id_pegawai'];
            if (!file_exists($temp_folder)) {
                mkdir($temp_folder, 0755, true);
            }
            
            $temp_file = $temp_folder . '/' . time() . '.png';
            write_file($temp_file, $image_data);
            
            // Verifikasi wajah
            $verifikasi_start = microtime(true);
            $hasil_verifikasi = $this->verifikasi_wajah($temp_file, $kompresi['id_pegawai']);
            $verifikasi_time = microtime(true) - $verifikasi_start;
            
            // Hapus file sementara
            if (file_exists($temp_file)) {
                unlink($temp_file);
            }
            
            // Buat response
            $response = [
                'status' => $hasil_verifikasi ? 1 : 0,
                'message' => $hasil_verifikasi ? 'Wajah terverifikasi (COCOK)' : 'Wajah tidak terverifikasi (TIDAK COCOK)',
                'kompresi_id' => $kompresi_id,
                'id_pegawai' => $kompresi['id_pegawai'],
                'dekompresi_time_ms' => round($dekompresi_time * 1000),
                'verifikasi_time_ms' => round($verifikasi_time * 1000),
                'total_time_ms' => round((microtime(true) - $start_time) * 1000)
            ];
            
            $this->output
                ->set_content_type('application/json')
                ->set_output(json_encode($response));
                
        } catch (Exception $e) {
            $this->output
                ->set_content_type('application/json')
                ->set_output(json_encode([
                    'status' => 0,
                    'message' => 'Error: ' . $e->getMessage(),
                    'kompresi_id' => $kompresi_id,
                    'id_pegawai' => $kompresi['id_pegawai']
                ]));
        }
    }
    
    // Fungsi untuk melakukan dekompresi Huffman
    private function dekompresi_huffman($kompresi) {
        // Implementasi algoritma dekompresi Huffman
        // Ini adalah pseudocode yang perlu disesuaikan dengan implementasi PHP
        
        // Load library untuk image processing
        $this->load->library('image_lib');
        
        // Parse frequency model (JSON)
        $frequencies = json_decode($kompresi['frequency_model'], true);
        
        // Bangun pohon Huffman
        $root = $this->build_huffman_tree($frequencies);
        
        // Dekode data
        $compressed_data = $kompresi['compressed_file'];
        $decoded_pixels = $this->decode_huffman($compressed_data, $root, $kompresi['original_length']);
        
        // Buat gambar dari pixel
        $width = $kompresi['width'];
        $height = $kompresi['height'];
        
        // Gunakan GD library untuk membuat gambar
        $image = imagecreatetruecolor($width, $height);
        
        // Isi pixel ke gambar
        $index = 0;
        for ($y = 0; $y < $height; $y++) {
            for ($x = 0; $x < $width; $x++) {
                $gray = $decoded_pixels[$index++];
                $color = imagecolorallocate($image, $gray, $gray, $gray);
                imagesetpixel($image, $x, $y, $color);
            }
        }
        
        // Konversi gambar ke PNG
        ob_start();
        imagepng($image);
        $image_data = ob_get_clean();
        imagedestroy($image);
        
        return $image_data;
    }
    
    // Fungsi untuk membangun pohon Huffman
    private function build_huffman_tree($frequencies) {
        // Implementasi pembangunan pohon Huffman
        // ...
    }
    
    // Fungsi untuk mendekode data yang dikompresi
    private function decode_huffman($compressed_data, $root, $original_length) {
        // Implementasi dekode Huffman
        // ...
    }
    
    // Fungsi untuk verifikasi wajah
    private function verifikasi_wajah($image_path, $id_pegawai) {
        // Hubungkan ke sistem verifikasi wajah yang sudah ada
        // Ini perlu disesuaikan dengan implementasi CI Anda
        
        // Contoh panggilan fungsi verifikasi (pseudocode)
        // return verify_face($image_path, $id_pegawai);
        
        // Untuk sementara, kita bisa simulasikan hasilnya
        return (rand(0, 1) == 1); // 50% chance cocok
    }
}