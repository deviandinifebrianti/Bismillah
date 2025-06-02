<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Kompresi_model extends CI_Model {
    
    public function __construct() {
        parent::__construct();
        $this->load->database();
    }
    
    // Ambil semua data kompresi
    public function get_all_kompresi() {
        $this->db->order_by('created_at', 'DESC');
        $query = $this->db->get('kompresi_huffman');
        return $query->result_array();
    }
    
    // Ambil data kompresi berdasarkan ID
    public function get_kompresi($id) {
        $query = $this->db->get_where('kompresi_huffman', ['id' => $id]);
        return $query->row_array();
    }
}