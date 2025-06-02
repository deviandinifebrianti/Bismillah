<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class VektorPegawaiModel extends CI_Model
{
    protected $table = 'vektor_pegawai';
    protected $primary_key = 'id';

    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Get all vector data with optional filters
     * 
     * @param array $filters Optional filters
     * @param int $limit Optional limit
     * @param int $offset Optional offset
     * @return array
     */
    public function getAll($filters = [], $limit = null, $offset = null)
    {
        $this->db->select('vp.*, p.nama, p.nip, p.unit_kerja');
        $this->db->from($this->table . ' vp');
        $this->db->join('pegawai p', 'p.id = vp.pegawai_id', 'left');
        $this->db->where('vp.status', 'active');

        // Apply filters
        if (!empty($filters['pegawai_id'])) {
            $this->db->where('vp.pegawai_id', $filters['pegawai_id']);
        }

        if (!empty($filters['vektor_type'])) {
            $this->db->where('vp.vektor_type', $filters['vektor_type']);
        }

        if (!empty($filters['search'])) {
            $this->db->group_start();
            $this->db->like('p.nama', $filters['search']);
            $this->db->or_like('p.nip', $filters['search']);
            $this->db->or_like('p.unit_kerja', $filters['search']);
            $this->db->group_end();
        }

        if (!empty($filters['date_from'])) {
            $this->db->where('DATE(vp.created_at) >=', $filters['date_from']);
        }

        if (!empty($filters['date_to'])) {
            $this->db->where('DATE(vp.created_at) <=', $filters['date_to']);
        }

        $this->db->order_by('vp.created_at', 'DESC');

        if ($limit) {
            $this->db->limit($limit, $offset);
        }

        return $this->db->get()->result();
    }

    /**
     * Get vector data by ID
     * 
     * @param int $id
     * @return object|null
     */
    public function getById($id)
    {
        $this->db->select('vp.*, p.nama, p.nip, p.unit_kerja');
        $this->db->from($this->table . ' vp');
        $this->db->join('pegawai p', 'p.id = vp.pegawai_id', 'left');
        $this->db->where('vp.id', $id);
        $this->db->where('vp.status', 'active');

        return $this->db->get()->row();
    }

    /**
     * Get vector data by pegawai ID
     * 
     * @param int $pegawai_id
     * @return array
     */
    public function getByPegawaiId($pegawai_id)
    {
        $this->db->select('*');
        $this->db->from($this->table);
        $this->db->where('pegawai_id', $pegawai_id);
        $this->db->where('status', 'active');
        $this->db->order_by('created_at', 'DESC');

        return $this->db->get()->result();
    }

    /**
     * Get vector data by pegawai ID and vector type
     * 
     * @param int $pegawai_id
     * @param string $vektor_type
     * @return object|null
     */
    public function getByPegawaiAndType($pegawai_id, $vektor_type)
    {
        $this->db->select('*');
        $this->db->from($this->table);
        $this->db->where('pegawai_id', $pegawai_id);
        $this->db->where('vektor_type', $vektor_type);
        $this->db->where('status', 'active');

        return $this->db->get()->row();
    }

    /**
     * Count vector data by pegawai ID
     * 
     * @param int $pegawai_id
     * @return int
     */
    public function countByPegawai($pegawai_id)
    {
        $this->db->from($this->table);
        $this->db->where('pegawai_id', $pegawai_id);
        $this->db->where('status', 'active');

        return $this->db->count_all_results();
    }

    /**
     * Get vector statistics by type
     * 
     * @return array
     */
    public function getStatsByType()
    {
        $this->db->select('vektor_type, COUNT(*) as total');
        $this->db->from($this->table);
        $this->db->where('status', 'active');
        $this->db->group_by('vektor_type');
        $this->db->order_by('total', 'DESC');

        return $this->db->get()->result();
    }

    /**
     * Get employees with vector counts
     * 
     * @param string $search Optional search term
     * @return array
     */
    public function getEmployeesWithVectorCount($search = null)
    {
        $this->db->select('
            p.id,
            p.nama,
            p.nip,
            p.unit_kerja,
            COUNT(vp.id) as jumlah_vektor,
            10 as max_vektor,
            MAX(vp.updated_at) as last_update
        ');
        $this->db->from('pegawai p');
        $this->db->join($this->table . ' vp', 'p.id = vp.pegawai_id AND vp.status = "active"', 'left');
        $this->db->where('p.status', 'aktif');

        if ($search) {
            $this->db->group_start();
            $this->db->like('p.nama', $search);
            $this->db->or_like('p.nip', $search);
            $this->db->or_like('p.unit_kerja', $search);
            $this->db->group_end();
        }

        $this->db->group_by('p.id, p.nama, p.nip, p.unit_kerja');
        $this->db->order_by('p.nama', 'ASC');

        return $this->db->get()->result();
    }

    /**
     * Insert new vector data
     * 
     * @param array $data
     * @return int|bool Insert ID on success, false on failure
     */
    public function insert($data)
    {
        // Validate required fields
        $required_fields = ['pegawai_id', 'vektor_type', 'vektor_data'];
        foreach ($required_fields as $field) {
            if (empty($data[$field])) {
                return false;
            }
        }

        // Set default values
        $data['status'] = isset($data['status']) ? $data['status'] : 'active';
        $data['confidence_level'] = isset($data['confidence_level']) ? $data['confidence_level'] : 0.85;
        $data['created_at'] = date('Y-m-d H:i:s');

        if ($this->db->insert($this->table, $data)) {
            return $this->db->insert_id();
        }

        return false;
    }

    /**
     * Update vector data
     * 
     * @param int $id
     * @param array $data
     * @return bool
     */
    public function update($id, $data)
    {
        if (empty($id)) {
            return false;
        }

        $data['updated_at'] = date('Y-m-d H:i:s');

        $this->db->where('id', $id);
        return $this->db->update($this->table, $data);
    }

    /**
     * Soft delete vector data
     * 
     * @param int $id
     * @param int $deleted_by
     * @return bool
     */
    public function softDelete($id, $deleted_by = null)
    {
        $data = [
            'status' => 'inactive',
            'deleted_at' => date('Y-m-d H:i:s')
        ];

        if ($deleted_by) {
            $data['deleted_by'] = $deleted_by;
        }

        $this->db->where('id', $id);
        return $this->db->update($this->table, $data);
    }

    /**
     * Hard delete vector data (permanent)
     * 
     * @param int $id
     * @return bool
     */
    public function delete($id)
    {
        $this->db->where('id', $id);
        return $this->db->delete($this->table);
    }

    /**
     * Bulk insert vector data
     * 
     * @param array $data_batch
     * @return bool
     */
    public function bulkInsert($data_batch)
    {
        if (empty($data_batch)) {
            return false;
        }

        // Add timestamps to all records
        foreach ($data_batch as &$data) {
            $data['status'] = isset($data['status']) ? $data['status'] : 'active';
            $data['confidence_level'] = isset($data['confidence_level']) ? $data['confidence_level'] : 0.85;
            $data['created_at'] = date('Y-m-d H:i:s');
        }

        return $this->db->insert_batch($this->table, $data_batch);
    }

    /**
     * Get vector data for matching/comparison
     * 
     * @param string $vektor_type
     * @param float $min_confidence
     * @return array
     */
    public function getForMatching($vektor_type, $min_confidence = 0.7)
    {
        $this->db->select('vp.*, p.nama, p.nip');
        $this->db->from($this->table . ' vp');
        $this->db->join('pegawai p', 'p.id = vp.pegawai_id', 'left');
        $this->db->where('vp.vektor_type', $vektor_type);
        $this->db->where('vp.confidence_level >=', $min_confidence);
        $this->db->where('vp.status', 'active');
        $this->db->where('p.status', 'aktif');

        return $this->db->get()->result();
    }

    /**
     * Update confidence level
     * 
     * @param int $id
     * @param float $confidence_level
     * @return bool
     */
    public function updateConfidence($id, $confidence_level)
    {
        $data = [
            'confidence_level' => $confidence_level,
            'updated_at' => date('Y-m-d H:i:s')
        ];

        $this->db->where('id', $id);
        return $this->db->update($this->table, $data);
    }

    /**
     * Get vector data with pagination
     * 
     * @param int $limit
     * @param int $offset
     * @param array $filters
     * @return array
     */
    public function getPaginated($limit, $offset, $filters = [])
    {
        $data['records'] = $this->getAll($filters, $limit, $offset);
        $data['total'] = $this->countAll($filters);
        $data['limit'] = $limit;
        $data['offset'] = $offset;

        return $data;
    }

    /**
     * Count all records with filters
     * 
     * @param array $filters
     * @return int
     */
    public function countAll($filters = [])
    {
        $this->db->from($this->table . ' vp');
        $this->db->join('pegawai p', 'p.id = vp.pegawai_id', 'left');
        $this->db->where('vp.status', 'active');

        // Apply same filters as getAll()
        if (!empty($filters['pegawai_id'])) {
            $this->db->where('vp.pegawai_id', $filters['pegawai_id']);
        }

        if (!empty($filters['vektor_type'])) {
            $this->db->where('vp.vektor_type', $filters['vektor_type']);
        }

        if (!empty($filters['search'])) {
            $this->db->group_start();
            $this->db->like('p.nama', $filters['search']);
            $this->db->or_like('p.nip', $filters['search']);
            $this->db->or_like('p.unit_kerja', $filters['search']);
            $this->db->group_end();
        }

        if (!empty($filters['date_from'])) {
            $this->db->where('DATE(vp.created_at) >=', $filters['date_from']);
        }

        if (!empty($filters['date_to'])) {
            $this->db->where('DATE(vp.created_at) <=', $filters['date_to']);
        }

        return $this->db->count_all_results();
    }

    /**
     * Get dashboard statistics
     * 
     * @return array
     */
    public function getDashboardStats()
    {
        $stats = [];

        // Total active vectors
        $this->db->from($this->table);
        $this->db->where('status', 'active');
        $stats['total_vectors'] = $this->db->count_all_results();

        // Total employees with vectors
        $this->db->select('DISTINCT pegawai_id');
        $this->db->from($this->table);
        $this->db->where('status', 'active');
        $stats['employees_with_vectors'] = $this->db->count_all_results();

        // Vectors by type
        $stats['vectors_by_type'] = $this->getStatsByType();

        // Recent activity (last 7 days)
        $this->db->from($this->table);
        $this->db->where('status', 'active');
        $this->db->where('created_at >=', date('Y-m-d H:i:s', strtotime('-7 days')));
        $stats['recent_vectors'] = $this->db->count_all_results();

        return $stats;
    }

    /**
     * Validate vector data format
     * 
     * @param string $vektor_data
     * @param string $vektor_type
     * @return bool
     */
    public function validateVectorFormat($vektor_data, $vektor_type)
    {
        switch ($vektor_type) {
            case 'face_encoding':
                $decoded = json_decode($vektor_data, true);
                return is_array($decoded) && count($decoded) === 128;
                
            case 'fingerprint':
                return base64_decode($vektor_data) !== false && strlen($vektor_data) > 100;
                
            case 'voice_pattern':
                $decoded = json_decode($vektor_data, true);
                return is_array($decoded) && count($decoded) >= 12;
                
            case 'iris_pattern':
                return base64_decode($vektor_data) !== false && strlen($vektor_data) > 200;
                
            case 'hand_geometry':
                $decoded = json_decode($vektor_data, true);
                return is_array($decoded) && count($decoded) >= 20;
                
            default:
                return !empty($vektor_data);
        }
    }

    /**
     * Get available vector types
     * 
     * @return array
     */
    public function getVectorTypes()
    {
        return [
            'face_encoding' => 'Face Encoding',
            'fingerprint' => 'Fingerprint Vector',
            'voice_pattern' => 'Voice Pattern',
            'iris_pattern' => 'Iris Pattern',
            'hand_geometry' => 'Hand Geometry'
        ];
    }

    /**
     * Clean up old inactive records
     * 
     * @param int $days_old
     * @return bool
     */
    public function cleanupOldRecords($days_old = 30)
    {
        $this->db->where('status', 'inactive');
        $this->db->where('deleted_at <', date('Y-m-d H:i:s', strtotime("-{$days_old} days")));
        
        return $this->db->delete($this->table);
    }

    /**
     * Reactivate soft deleted record
     * 
     * @param int $id
     * @return bool
     */
    public function reactivate($id)
    {
        $data = [
            'status' => 'active',
            'deleted_at' => null,
            'deleted_by' => null,
            'updated_at' => date('Y-m-d H:i:s')
        ];

        $this->db->where('id', $id);
        return $this->db->update($this->table, $data);
    }
}

?>