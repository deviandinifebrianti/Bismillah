<?php

if (!defined('BASEPATH')) exit('No direct script access allowed');

class Pegawai_model extends CI_Model
{
    public $table = 'pegawai';
    public $id = 'id_pegawai';
    public $order = 'DESC';

    function __construct()
    {
        parent::__construct();
    }

    // Get all pegawai data - Method yang sering dipanggil
   function get_all()
{
    $this->db->select('
        pegawai.*,
        jabatan.nama_jabatan,
        unit_kerja.nama_unit_kerja
    ');
    $this->db->from($this->table);
    $this->db->join('jabatan', 'jabatan.id_jabatan = pegawai.id_jabatan', 'left');
    $this->db->join('unit_kerja', 'unit_kerja.id_unit_kerja = pegawai.id_unit_kerja', 'left');
    $this->db->order_by('pegawai.' . $this->id, $this->order);
    return $this->db->get()->result();
}

    // Alias untuk get_all - untuk konsistensi penamaan
    function get_all_pegawai()
{
    return $this->get_all();
}

function get_all_data()
{
    return $this->get_all();
}

    // Get pegawai by id
    function get_by_id($id)
    {
        // TAMBAHKAN JOIN DISINI JUGA
        $this->db->select('
            pegawai.*,
            jabatan.nama_jabatan,
            unit_kerja.nama_unit_kerja
        ');
        $this->db->from($this->table);
        $this->db->join('jabatan', 'jabatan.id_jabatan = pegawai.id_jabatan', 'left');
        $this->db->join('unit_kerja', 'unit_kerja.id_unit_kerja = pegawai.id_unit_kerja', 'left');
        $this->db->where('pegawai.' . $this->id, $id);
        return $this->db->get()->row();
    }

    // Get unit kerja untuk dropdown
function get_unit_kerja_dropdown()
{
    $this->db->select('id_unit_kerja, nama_unit_kerja');
    $this->db->from('unit_kerja');
    $this->db->order_by('nama_unit_kerja', 'ASC');
    $query = $this->db->get();

    $dropdown = array();
    $dropdown[''] = '-- Pilih Unit Kerja --';
    
    foreach ($query->result() as $row) {
        $dropdown[$row->id_unit_kerja] = $row->nama_unit_kerja;
    }

    return $dropdown;
}


    // Get total records
function total_rows($q = NULL)
{
    $this->db->from($this->table);
    $this->db->join('jabatan', 'jabatan.id_jabatan = pegawai.id_jabatan', 'left');
    $this->db->join('unit_kerja', 'unit_kerja.id_unit_kerja = pegawai.id_unit_kerja', 'left');
    
    if ($q) {
        $this->db->like('pegawai.nama', $q);
        $this->db->or_like('pegawai.nip', $q);
        $this->db->or_like('jabatan.nama_jabatan', $q);
        $this->db->or_like('unit_kerja.nama_unit_kerja', $q);
    }
    
    return $this->db->count_all_results();
}

    // Get data with limit for pagination
function get_limit_data($limit, $start = 0, $q = NULL)
{
    // TAMBAHKAN JOIN DISINI
    $this->db->select('
        pegawai.*,
        jabatan.nama_jabatan,
        unit_kerja.nama_unit_kerja
    ');
    $this->db->from($this->table);
    $this->db->join('jabatan', 'jabatan.id_jabatan = pegawai.id_jabatan', 'left');
    $this->db->join('unit_kerja', 'unit_kerja.id_unit_kerja = pegawai.id_unit_kerja', 'left');
    
    if ($q) {
        $this->db->like('pegawai.nama', $q);
        $this->db->or_like('pegawai.nip', $q);
        $this->db->or_like('jabatan.nama_jabatan', $q);
        $this->db->or_like('unit_kerja.nama_unit_kerja', $q);
    }
    
    $this->db->order_by('pegawai.' . $this->id, $this->order);
    $this->db->limit($limit, $start);
    return $this->db->get()->result();
}
    // Insert new pegawai
    function insert($data)
    {
        $this->db->insert($this->table, $data);
        return $this->db->insert_id();
    }

    // Update pegawai
    function update($id, $data)
    {
        $this->db->where($this->id, $id);
        $this->db->update($this->table, $data);
    }

    // Delete pegawai
    function delete($id)
    {
        $this->db->where($this->id, $id);
        $this->db->delete($this->table);
    }

    // Get active pegawai only (jika ada field status)
    function get_active_pegawai()
    {
        $this->db->where('status', 'active'); // sesuaikan dengan field status Anda
        $this->db->order_by('nama', 'ASC');
        return $this->db->get($this->table)->result();
    }

    // Get pegawai untuk dropdown
    function get_pegawai_dropdown()
    {
        $this->db->select('id_pegawai, nama');
        $this->db->order_by('nama', 'ASC');
        $query = $this->db->get($this->table);
        
        $dropdown = array();
        $dropdown[''] = '-- Pilih Pegawai --';
        
        foreach ($query->result() as $row) {
            $dropdown[$row->id_pegawai] = $row->nama;
        }
        
        return $dropdown;
    }

    // Get pegawai by NIP
    function get_by_nip($nip)
    {
        $this->db->where('nip', $nip);
        return $this->db->get($this->table)->row();
    }

    // Check if NIP exists (untuk validasi)
    function is_nip_exists($nip, $exclude_id = null)
    {
        $this->db->where('nip', $nip);
        if ($exclude_id) {
            $this->db->where($this->id . ' !=', $exclude_id);
        }
        $query = $this->db->get($this->table);
        return $query->num_rows() > 0;
    }

    // Get pegawai by jabatan
    function get_by_jabatan($jabatan)
    {
        $this->db->where('jabatan', $jabatan);
        $this->db->order_by('nama', 'ASC');
        return $this->db->get($this->table)->result();
    }

    // Search pegawai
    function search($keyword)
    {
        $this->db->like('nama', $keyword);
        $this->db->or_like('nip', $keyword);
        $this->db->or_like('jabatan', $keyword);
        $this->db->order_by('nama', 'ASC');
        return $this->db->get($this->table)->result();
    }

    // Get pegawai count
    function get_count()
    {
        return $this->db->count_all($this->table);
    }

    // Get latest pegawai
    function get_latest($limit = 5)
    {
        $this->db->order_by($this->id, 'DESC');
        $this->db->limit($limit);
        return $this->db->get($this->table)->result();
    }
}