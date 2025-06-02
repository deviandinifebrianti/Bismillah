<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Daftar Log Absensi - Sipreti</title>
  <link rel="stylesheet" href="<?php echo base_url('assets/bootstrap/css/bootstrap.min.css') ?>"/>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.0/font/bootstrap-icons.css">
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      background-color: #f8f9fa;
    }
    
    /* Header navbar styling */
    .navbar {
      background-color: #4B0082;
      padding: 10px 20px;
      display: flex;
      align-items: center;
    }
    
    .navbar-brand {
      display: flex;
      align-items: center;
      color: white;
      font-weight: bold;
      font-size: 18px;
      margin-right: 20px;
      text-decoration: none;
    }
    
    .navbar-brand img {
      height: 30px;
      margin-right: 10px;
    }
    
    .navbar-menu {
      display: flex;
      align-items: center;
      margin-left: auto;
    }
    
    .nav-link {
      color: white;
      text-decoration: none;
      padding: 10px 15px;
      margin: 0 2px;
      font-size: 0.9rem;
      display: inline-block;
      transition: background-color 0.3s;
    }
    
    .nav-link:hover {
      background-color: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
    }
    
    .content-header {
      background-color: #4CAF50;
      color: white;
      padding: 12px 15px;
      margin-bottom: 20px;
    }
    
    .content-header h2 {
      font-size: 22px;
      margin: 0;
      font-weight: 600;
    }
    
    .search-container {
      margin-bottom: 15px;
      display: flex;
      justify-content: space-between;
    }
    
    .search-box {
      display: flex;
      max-width: 350px;
    }
    
    .search-box input {
      border-top-right-radius: 0;
      border-bottom-right-radius: 0;
      border-right: none;
    }
    
    .search-box button {
      border-top-left-radius: 0;
      border-bottom-left-radius: 0;
    }
    
    .add-button {
      background-color: #9C27B0;
      color: white;
      border: none;
    }
    
    .table th {
      background-color: #330066;
      color: white;
      text-align: center;
      padding: 10px;
      font-weight: 600;
      border: 1px solid #ddd;
    }
    
    .table td {
      padding: 8px 10px;
      border: 1px solid #ddd;
      text-align: center;
      vertical-align: middle;
    }
    
    .action-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 30px;
      height: 30px;
      margin: 0 2px;
      color: white;
      border-radius: 4px;
      text-decoration: none;
    }
    
    .view-btn { background-color: #6cb33f; }
    .edit-btn { background-color: #17a2b8; }
    .delete-btn { background-color: #dc3545; }
    
    .table-responsive {
      overflow-x: auto;
    }
    
    /* CSS-ONLY MODAL - NO JAVASCRIPT NEEDED! */
    .photo-modal {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.9);
      z-index: 9999;
      opacity: 0;
      visibility: hidden;
      transition: all 0.3s ease;
    }
    
    .photo-modal:target {
      opacity: 1;
      visibility: visible;
    }
    
    .photo-modal-content {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      max-width: 90%;
      max-height: 90%;
      text-align: center;
    }
    
    .photo-modal img {
      max-width: 100%;
      max-height: 80vh;
      border-radius: 10px;
      box-shadow: 0 8px 30px rgba(255, 255, 255, 0.1);
    }
    
    .photo-modal-info {
      color: white;
      margin-top: 15px;
      background: rgba(0, 0, 0, 0.7);
      padding: 10px 20px;
      border-radius: 25px;
      display: inline-block;
    }
    
    .photo-modal-close {
      position: absolute;
      top: 20px;
      right: 30px;
      color: white;
      font-size: 40px;
      font-weight: bold;
      text-decoration: none;
      z-index: 10000;
      transition: color 0.3s;
    }
    
    .photo-modal-close:hover {
      color: #ff6b6b;
      text-decoration: none;
    }
    
    .photo-modal-buttons {
      margin-top: 20px;
    }
    
    .photo-modal-btn {
      background: #007bff;
      color: white;
      padding: 10px 20px;
      margin: 0 10px;
      border-radius: 25px;
      text-decoration: none;
      display: inline-block;
      transition: background 0.3s;
    }
    
    .photo-modal-btn:hover {
      background: #0056b3;
      color: white;
      text-decoration: none;
    }
    
    .photo-modal-btn.download {
      background: #28a745;
    }
    
    .photo-modal-btn.download:hover {
      background: #1e7e34;
    }
    
    /* Foto thumbnail styling */
    .foto-thumb {
      width: 70px;
      height: 70px;
      object-fit: cover;
      border: 2px solid #ddd;
      border-radius: 8px;
      transition: all 0.3s ease;
      text-decoration: none;
      display: inline-block;
    }
    
    .foto-thumb:hover {
      transform: scale(1.1);
      border-color: #007bff;
      box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    }
    
    .no-foto {
      width: 70px;
      height: 70px;
      display: flex;
      align-items: center;
      justify-content: center;
      background-color: #f8f9fa;
      border: 2px dashed #ddd;
      border-radius: 8px;
      color: #6c757d;
      flex-direction: column;
    }
    
    /* Simple hover preview */
    .foto-container {
      position: relative;
      display: inline-block;
    }
    
    .foto-preview {
      position: absolute;
      top: -120px;
      left: 50%;
      transform: translateX(-50%);
      width: 200px;
      height: 150px;
      object-fit: cover;
      border: 3px solid white;
      border-radius: 10px;
      box-shadow: 0 8px 25px rgba(0,0,0,0.3);
      opacity: 0;
      visibility: hidden;
      transition: all 0.3s ease;
      z-index: 1000;
    }
    
    .foto-container:hover .foto-preview {
      opacity: 1;
      visibility: visible;
    }
    
    @media (max-width: 768px) {
      .photo-modal-content {
        max-width: 95%;
        padding: 20px;
      }
      
      .photo-modal-close {
        top: 10px;
        right: 15px;
        font-size: 30px;
      }
      
      .foto-preview {
        display: none; /* Hide preview on mobile */
      }
    }
  </style>
</head>
<body>

<!-- Header dengan Navbar -->
<nav class="navbar">
  <a href="<?php echo site_url('welcome'); ?>" class="navbar-brand">
    <img src="<?= base_url('assets/datatables/images/logo.jpg') ?>" alt="Logo"> Sipreti
  </a>
  
  <div class="navbar-menu">
    <a href="<?php echo site_url('welcome'); ?>" class="nav-link">Dashboard</a>
    <a href="<?php echo site_url('pegawai'); ?>" class="nav-link">Pegawai</a>
    <a href="<?php echo site_url('jabatan'); ?>" class="nav-link">Jabatan</a>
    <a href="<?php echo site_url('radius_absen'); ?>" class="nav-link">Radius Absen</a>
    <a href="<?php echo site_url('log_absensi'); ?>" class="nav-link">Log Absensi</a>
    <a href="<?php echo site_url('unit_kerja'); ?>" class="nav-link">Unit Kerja</a>
    <a href="<?php echo site_url('user_android'); ?>" class="nav-link">User Android</a>
    <a href="<?php echo site_url('biometrik'); ?>" class="nav-link">Tambah Gambar</a>
  </div>
</nav>

<!-- Header -->
<div class="content-header">
  <h2>Daftar Log Absensi</h2>
</div>

<!-- Konten -->
<div class="container-fluid">
  <div class="search-container">
    <form action="<?php echo site_url('log_absensi/index'); ?>" class="search-box" method="get">
      <input type="text" class="form-control" name="q" value="<?php echo $q; ?>" placeholder="Cari log absensi...">
      <button class="btn btn-primary" type="submit">Cari</button>
      <?php if ($q != '') { ?>
        <a href="<?php echo site_url('log_absensi'); ?>" class="btn btn-secondary ms-2">Reset</a>
      <?php } ?>
    </form>
    <a href="<?php echo site_url('log_absensi/create'); ?>" class="btn add-button">+ Tambah Log</a>
  </div>

  <!-- Pesan Notifikasi -->
  <?php if ($this->session->userdata('message') != ''): ?>
  <div class="alert alert-success alert-dismissible fade show mb-3">
    <?php echo $this->session->userdata('message'); ?>
    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
  </div>
  <?php endif; ?>

  <!-- Tabel -->
  <div class="table-responsive">
    <table class="table table-bordered">
      <thead>
        <tr>
          <th>No</th>
          <th>Id Pegawai</th>
          <th>Jenis Absensi</th>
          <th>Check Mode</th>
          <th>Waktu Absensi</th>
          <th>Foto Absensi</th>
          <th>Latitude</th>
          <th>Longitude</th>
          <th>Nama Lokasi</th>
          <th>Aksi</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($log_absensi_data as $log_absensi): ?>
        <tr>
          <td width="80px"><?php echo ++$start ?></td>
          <td><?php echo $log_absensi->id_pegawai ?></td>
          <td><?php echo $log_absensi->jenis_absensi ? $log_absensi->jenis_absensi : 'Regular'; ?></td>
          <td><?php 
            if($log_absensi->check_mode == 0) {
              echo "Check In";
            } else if($log_absensi->check_mode == 1) {
              echo "Check Out";
            } else {
              echo "Unknown";
            }
          ?></td>
          <td><?php echo $log_absensi->waktu_absensi ?></td>
          
          <!-- Kolom Foto Absensi - CSS ONLY MODAL -->
          <td>
            <?php 
              // Generate URL foto dari Django - ambil foto TERBARU di hari yang sama
              $waktu_absensi = $log_absensi->waktu_absensi;
              $date = date('Ymd', strtotime($waktu_absensi));
              
              $django_media_path = "D:/ABSENSI DEVI/lancar/pemkot/media/huffman_images/";
              $foto_path = $django_media_path . $log_absensi->id_pegawai . "/";
              $pattern = $foto_path . $date . "*_decoded.jpg";
              $files = glob($pattern);
              
              if (!empty($files)) {
                // Sort files berdasarkan nama (yang mengandung timestamp)
                // File terbaru akan berada di urutan terakhir
                usort($files, function($a, $b) {
                  return strcmp(basename($a), basename($b));
                });
                
                // Ambil file TERAKHIR (paling terbaru)
                $foto_file = basename(end($files));
              } else {
                $foto_file = null;
              }
              
              if ($foto_file): 
                $web_url = "http://localhost:8000/media/huffman_images/" . $log_absensi->id_pegawai . "/" . $foto_file;
                $photo_info = "ID Pegawai: " . $log_absensi->id_pegawai . " | Waktu: " . date('d-m-Y H:i:s', strtotime($waktu_absensi)) . " | Foto: " . $foto_file;
                $modal_id = "modal_" . $log_absensi->id_log_absensi;
            ?>
              <div class="foto-container">
                <!-- Foto thumbnail yang bisa diklik -->
                <a href="#<?php echo $modal_id; ?>" class="foto-thumb">
                  <img src="<?php echo $web_url; ?>" 
                       alt="Foto Absensi" 
                       style="width: 100%; height: 100%; object-fit: cover; border-radius: 6px;">
                </a>
                
                <!-- Preview saat hover -->
                <img src="<?php echo $web_url; ?>" 
                     alt="Preview" 
                     class="foto-preview">
              </div>
              
              <!-- CSS-Only Modal untuk foto ini -->
              <div id="<?php echo $modal_id; ?>" class="photo-modal">
                <a href="#" class="photo-modal-close">&times;</a>
                <div class="photo-modal-content">
                  <img src="<?php echo $web_url; ?>" alt="Foto Absensi Besar">
                  <div class="photo-modal-info">
                    <?php echo $photo_info; ?>
                  </div>
                  <div class="photo-modal-buttons">
                    <a href="#" class="photo-modal-btn">Tutup</a>
                    <a href="<?php echo $web_url; ?>" download="<?php echo $foto_file; ?>" class="photo-modal-btn download">Download</a>
                    <a href="<?php echo $web_url; ?>" target="_blank" class="photo-modal-btn">Buka Tab Baru</a>
                  </div>
                </div>
              </div>
              
            <?php else: ?>
              <div class="no-foto">
                <i class="bi bi-camera" style="font-size: 20px;"></i>
                <small>No Photo</small>
              </div>
            <?php endif; ?>
          </td>
          
          <td><?php echo $log_absensi->latitude ?></td>
          <td><?php echo $log_absensi->longitude ?></td>
          <td>
            <span id="lokasi_<?php echo $log_absensi->id_log_absensi; ?>">
              <?php 
                if(!empty($log_absensi->nama_lokasi)) {
                  echo $log_absensi->nama_lokasi;
                } else {
                  // Tampilkan loading, nanti akan diupdate via JavaScript
                  echo '<span class="text-muted"><i class="bi bi-geo-alt"></i> Loading lokasi...</span>';
                }
              ?>
            </span>
          </td>
          <td>
            <a href="<?php echo site_url('log_absensi/read/'.$log_absensi->id_log_absensi); ?>" class="action-btn view-btn" title="Lihat"><i class="bi bi-eye-fill"></i></a>
            <a href="<?php echo site_url('log_absensi/update/'.$log_absensi->id_log_absensi); ?>" class="action-btn edit-btn" title="Edit"><i class="bi bi-pencil-fill"></i></a>
            <a href="<?php echo site_url('log_absensi/delete/'.$log_absensi->id_log_absensi); ?>" class="action-btn delete-btn" title="Hapus" onclick="return confirm('Yakin ingin menghapus data ini?')"><i class="bi bi-trash-fill"></i></a>
          </td>
        </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>

  <!-- Pagination -->
  <div class="row">
    <div class="col-md-6">
      <p>Total Record: <?php echo $total_rows; ?></p>
    </div>
    <div class="col-md-6 text-end">
      <?php echo $pagination; ?>
    </div>
  </div>
</div>

<!-- NO JAVASCRIPT NEEDED! Pure CSS + HTML Only -->

<script>
// Function untuk mendapatkan nama lokasi dari koordinat menggunakan Reverse Geocoding
async function getLocationName(lat, lng, elementId) {
  try {
    // Delay untuk menghindari rate limiting
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Menggunakan Nominatim OpenStreetMap API (gratis)
    const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1&accept-language=id`);
    const data = await response.json();
    
    if (data && data.display_name) {
      const address = data.address;
      let locationName = '';
      
      // Prioritas alamat: nama jalan, kelurahan, kecamatan, kota
      const addressParts = [
        address.road || address.pedestrian || address.footway,
        address.suburb || address.village || address.neighbourhood,
        address.subdistrict || address.city_district,
        address.city || address.town || address.county
      ].filter(Boolean);
      
      // Ambil 3 bagian alamat yang paling relevan
      locationName = addressParts.slice(0, 3).join(', ');
      
      // Jika masih kosong, gunakan display_name yang dipotong
      if (!locationName) {
        locationName = data.display_name.split(',').slice(0, 3).join(', ');
      }
      
      // Update elemen dengan nama lokasi yang readable
      document.getElementById(elementId).innerHTML = 
        '<i class="bi bi-geo-alt-fill text-success"></i> ' + locationName;
    } else {
      document.getElementById(elementId).innerHTML = 
        '<i class="bi bi-geo-alt text-muted"></i> <span class="text-muted">Lokasi tidak diketahui</span>';
    }
  } catch (error) {
    console.error('Error getting location:', error);
    document.getElementById(elementId).innerHTML = 
      '<i class="bi bi-geo-alt text-danger"></i> <span class="text-muted">Error loading lokasi</span>';
  }
}

// Auto-load lokasi untuk semua row yang belum punya nama lokasi
document.addEventListener('DOMContentLoaded', function() {
  let delay = 0;
  
  <?php foreach ($log_absensi_data as $index => $log_absensi): ?>
    <?php if(empty($log_absensi->nama_lokasi) && !empty($log_absensi->latitude) && !empty($log_absensi->longitude)): ?>
      setTimeout(() => {
        getLocationName(
          <?php echo $log_absensi->latitude; ?>, 
          <?php echo $log_absensi->longitude; ?>, 
          'lokasi_<?php echo $log_absensi->id_log_absensi; ?>'
        );
      }, delay);
      delay += 1500; // Delay 1.5 detik antar request untuk menghindari rate limit
    <?php endif; ?>
  <?php endforeach; ?>
});
</script>

</body>
</html>