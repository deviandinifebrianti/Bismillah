<?php

if (!defined('BASEPATH'))
	exit('No direct script access allowed');

class User_android_model extends CI_Model
{
	public $table = 'user_android';
	public $id = 'id_user_android';
	public $order = 'DESC';

	function __construct()
	{
		parent::__construct();
	}

	// get all dengan JOIN ke tabel pegawai
	function get_all() {
		$this->db->select('ua.*, p.email as pegawai_email, p.nama as nama_pegawai');
		$this->db->from('user_android ua');
		$this->db->join('pegawai p', 'ua.id_pegawai = p.id_pegawai', 'left');
		$this->db->order_by('ua.username', 'ASC');
		return $this->db->get()->result();
	}

	// get data by id dengan JOIN
	function get_by_id($id)
	{
		$this->db->select('ua.*, p.email as pegawai_email, p.nama as nama_pegawai');
		$this->db->from('user_android ua');
		$this->db->join('pegawai p', 'ua.id_pegawai = p.id_pegawai', 'left');
		$this->db->where('ua.'.$this->id, $id);
		return $this->db->get()->row();
	}

	// get total rows dengan JOIN dan search
	function total_rows($q = NULL, $onlyActive = FALSE)
	{
		$this->db->select('ua.*, p.email as pegawai_email, p.nama as nama_pegawai');
		$this->db->from('user_android ua');
		$this->db->join('pegawai p', 'ua.id_pegawai = p.id_pegawai', 'left');
		
		if ($q) {
			$this->db->group_start();
			$this->db->like('ua.username', $q);
			$this->db->or_like('ua.email', $q);
			$this->db->or_like('p.email', $q);
			$this->db->or_like('p.nama', $q);
			$this->db->or_like('ua.no_hp', $q);
			$this->db->group_end();
		}
		
		if ($onlyActive) {
			$this->db->where('(ua.deleted_at IS NULL OR ua.deleted_at = "")');
		}
		
		return $this->db->count_all_results();
	}

	// get data with limit and search dengan JOIN
	public function get_limit_data($limit, $start = 0, $q = NULL, $onlyActive = FALSE)
	{
		$this->db->select('ua.*, p.email as pegawai_email, p.nama as nama_pegawai');
		$this->db->from('user_android ua');
		$this->db->join('pegawai p', 'ua.id_pegawai = p.id_pegawai', 'left');
		
		if ($q) {
			$this->db->group_start();
			$this->db->like('ua.username', $q);
			$this->db->or_like('ua.email', $q);
			$this->db->or_like('p.email', $q);
			$this->db->or_like('p.nama', $q);
			$this->db->or_like('ua.no_hp', $q);
			$this->db->group_end();
		}
		
		if ($onlyActive) {
			$this->db->where('(ua.deleted_at IS NULL OR ua.deleted_at = "")');
		}
		
		$this->db->limit($limit, $start);
		$this->db->order_by('ua.username', 'ASC');
		return $this->db->get()->result();
	}

	// insert data
	function insert($data)
	{
		$this->db->insert($this->table, $data);
		if ($this->db->affected_rows() > 0) {
			return $this->db->insert_id();
		}
		return FALSE;
	}

	// update data
	function update($id, $data)
	{
		$this->db->where($this->id, $id);
		$this->db->update($this->table, $data);
		return $this->db->affected_rows();
	}

	// delete data (soft delete)
	function delete($id)
	{
		$data = array('deleted_at' => date('Y-m-d H:i:s'));
		$this->db->where($this->id, $id);
		$this->db->update($this->table, $data);
		return $this->db->affected_rows();
	}
}