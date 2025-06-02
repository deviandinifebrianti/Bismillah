<?php
// Model Biometrik (application/models/Biometrik_model.php)
class Biometrik_model extends CI_Model {
    
    private $table = 'sipreti_biometrik';
    private $table_pegawai = 'pegawai';
    
    public function __construct() {
        parent::__construct();
    }
    
    // Ambil semua data biometrik dengan join pegawai dan grouping
    public function get_all_biometrik($search = null) {
        $this->db->select('b.*, p.nama as nama_pegawai, p.nip, p.id_jabatan, p.id_unit_kerja, p.image as foto_pegawai');
        $this->db->from($this->table . ' b');
        $this->db->join($this->table_pegawai . ' p', 'b.id_pegawai = p.id_pegawai', 'left');
        
        if ($search) {
            $this->db->group_start();
            $this->db->like('p.nama', $search);
            $this->db->or_like('p.nip', $search);
            $this->db->or_like('b.name', $search);
            $this->db->or_like('b.face_id', $search);
            $this->db->group_end();
        }
        
        $this->db->order_by('b.created_at', 'DESC');
        return $this->db->get();
    }
    
    // Ambil data biometrik berdasarkan ID
    public function get_biometrik_by_id($id) {
        $this->db->select('b.*, p.nama as nama_pegawai, p.nip');
        $this->db->from($this->table . ' b');
        $this->db->join($this->table_pegawai . ' p', 'b.id_pegawai = p.id_pegawai', 'left');
        $this->db->where('b.id', $id);
        return $this->db->get();
    }
    
    // Simpan data biometrik baru
    public function insert_biometrik($data) {
        $data['created_at'] = date('Y-m-d H:i:s');
        return $this->db->insert($this->table, $data);
    }
    
    // Update data biometrik
    public function update_biometrik($id, $data) {
        $data['updated_at'] = date('Y-m-d H:i:s');
        $this->db->where('id', $id);
        return $this->db->update($this->table, $data);
    }
    
    // Hapus data biometrik (hard delete karena tidak ada soft delete)
    public function delete_biometrik($id) {
        $this->db->where('id', $id);
        return $this->db->delete($this->table);
    }
    
    // Cek apakah pegawai sudah memiliki data biometrik
    public function check_existing_biometrik($id_pegawai, $id = null) {
        $this->db->where('id_pegawai', $id_pegawai);
        
        if ($id) {
            $this->db->where('id !=', $id);
        }
        
        $query = $this->db->get($this->table);
        return $query->num_rows() > 0;
    }
    
    // Ambil data pegawai untuk dropdown
    public function get_all_pegawai() {
        $this->db->select('id_pegawai, nama, nip');
        $this->db->from($this->table_pegawai);
        $this->db->order_by('nama', 'ASC');
        return $this->db->get();
    }
    
    // Validasi face vector (opsional untuk pengecekan format)
    public function validate_face_vector($face_vector) {
        // Implementasi validasi sesuai format yang dibutuhkan
        // Contoh: cek apakah berupa JSON atau format tertentu
        if (empty($face_vector)) {
            return false;
        }
        
        // Cek apakah valid JSON jika menggunakan format JSON
        json_decode($face_vector);
        return (json_last_error() == JSON_ERROR_NONE);
    }

    public function get_biometrik_with_details($id) {
    $this->db->select('
        sb.*,
        p.nama,
        p.nip,
        j.nama_jabatan,
        uk.nama_unit_kerja
    ');
    $this->db->from('sipreti_biometrik sb');
    $this->db->join('pegawai p', 'sb.id_pegawai = p.id_pegawai', 'left');
    $this->db->join('jabatan j', 'p.id_jabatan = j.id_jabatan', 'left');
    $this->db->join('unit_kerja uk', 'p.id_unit_kerja = uk.id_unit_kerja', 'left');
    $this->db->where('sb.id', $id);
    
    return $this->db->get();
}

// Method untuk mendapatkan semua biometrik dengan detail
public function get_all_biometrik_with_details($search = null) {
    $this->db->select('
        sb.*,
        p.nama,
        p.nip,
        j.nama_jabatan,
        uk.nama_unit_kerja
    ');
    $this->db->from('sipreti_biometrik sb');
    $this->db->join('pegawai p', 'sb.id_pegawai = p.id_pegawai', 'left');
    $this->db->join('jabatan j', 'p.id_jabatan = j.id_jabatan', 'left');
    $this->db->join('unit_kerja uk', 'p.id_unit_kerja = uk.id_unit_kerja', 'left');
    
    if (!empty($search)) {
        $this->db->group_start();
        $this->db->like('p.nama', $search);
        $this->db->or_like('p.nip', $search);
        $this->db->or_like('j.nama_jabatan', $search);
        $this->db->or_like('uk.nama_unit_kerja', $search);
        $this->db->or_like('sb.name', $search);
        $this->db->or_like('sb.face_id', $search);
        $this->db->group_end();
    }
    
    $this->db->order_by('sb.created_at', 'DESC');
    return $this->db->get();
}

// Method untuk mendapatkan semua pegawai dengan detail jabatan dan unit kerja
public function get_all_pegawai_with_details() {
    $this->db->select('
        p.*,
        j.nama_jabatan,
        uk.nama_unit_kerja
    ');
    $this->db->from('pegawai p');
    $this->db->join('jabatan j', 'p.id_jabatan = j.id_jabatan', 'left');
    $this->db->join('unit_kerja uk', 'p.id_unit_kerja = uk.id_unit_kerja', 'left');
    $this->db->order_by('p.nama', 'ASC');
    
    return $this->db->get();
}

// Method untuk mendapatkan detail pegawai berdasarkan ID
public function get_pegawai_with_details($id_pegawai) {
    $this->db->select('
        p.*,
        j.nama_jabatan,
        uk.nama_unit_kerja
    ');
    $this->db->from('pegawai p');
    $this->db->join('jabatan j', 'p.id_jabatan = j.id_jabatan', 'left');
    $this->db->join('unit_kerja uk', 'p.id_unit_kerja = uk.id_unit_kerja', 'left');
    $this->db->where('p.id_pegawai', $id_pegawai);
    
    return $this->db->get();
}
}