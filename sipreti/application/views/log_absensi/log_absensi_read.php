<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Detail Log Absensi - SI Preti</title>
  <link rel="stylesheet" href="<?php echo base_url('assets/bootstrap/css/bootstrap.min.css') ?>"/>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.0/font/bootstrap-icons.css">
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      background-color: #e0e0e0;
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
    
    .navbar-toggler {
      display: none;
      background: none;
      border: none;
      color: white;
      font-size: 24px;
      cursor: pointer;
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
    
    .detail-container {
      width: 100%;
      max-width: 800px;
      background-color: white;
      border-radius: 8px;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
      overflow: hidden;
      margin: 30px auto;
    }
    
    .detail-header {
      background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
      color: white;
      padding: 20px;
      text-align: center;
    }
    
    .detail-header h3 {
      margin: 0;
      font-size: 24px;
      font-weight: 600;
    }
    
    .detail-header .subtitle {
      margin-top: 5px;
      opacity: 0.9;
      font-size: 14px;
    }
    
    .detail-body {
      padding: 30px;
    }
    
    .info-section {
      margin-bottom: 25px;
    }
    
    .section-title {
      font-size: 16px;
      font-weight: 600;
      color: #333;
      margin-bottom: 15px;
      padding-bottom: 8px;
      border-bottom: 2px solid #e9ecef;
      display: flex;
      align-items: center;
    }
    
    .section-title i {
      margin-right: 8px;
      color: #4CAF50;
    }
    
    .info-group {
      margin-bottom: 20px;
    }
    
    .info-label {
      display: block;
      margin-bottom: 8px;
      font-weight: 600;
      font-size: 14px;
      color: #555;
    }
    
    .info-value {
      padding: 12px 15px;
      background-color: #f8f9fa;
      border: 1px solid #e9ecef;
      border-radius: 6px;
      font-size: 14px;
      min-height: 20px;
      position: relative;
    }
    
    .info-value.highlight {
      background-color: #e8f5e8;
      border-color: #4CAF50;
    }
    
    .foto-container {
      text-align: center;
      margin: 20px 0;
    }
    
    .foto-preview {
      max-width: 300px;
      max-height: 300px;
      border: 3px solid #ddd;
      border-radius: 10px;
      cursor: pointer;
      transition: all 0.3s ease;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    }
    
    .foto-preview:hover {
      transform: scale(1.05);
      border-color: #4CAF50;
      box-shadow: 0 6px 25px rgba(0,0,0,0.2);
    }
    
    .no-foto {
      padding: 40px;
      background-color: #f8f9fa;
      border: 2px dashed #ddd;
      border-radius: 10px;
      color: #6c757d;
      text-align: center;
    }
    
    .status-badge {
      display: inline-block;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }
    
    .status-checkin {
      background-color: #d4edda;
      color: #155724;
    }
    
    .status-checkout {
      background-color: #fff3cd;
      color: #856404;
    }
    
    .coordinates-link {
      color: #007bff;
      text-decoration: none;
      font-weight: 500;
    }
    
    .coordinates-link:hover {
      text-decoration: underline;
    }
    
    .action-buttons {
      display: flex;
      justify-content: space-between;
      gap: 15px;
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #e9ecef;
    }
    
    .btn {
      padding: 12px 25px;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 600;
      font-size: 14px;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      transition: all 0.3s ease;
    }
    
    .btn i {
      margin-right: 8px;
    }
    
    .btn-secondary {
      background-color: #6c757d;
      color: white;
    }
    
    .btn-secondary:hover {
      background-color: #5a6268;
      color: white;
      text-decoration: none;
    }
    
    .btn-primary {
      background-color: #007bff;
      color: white;
    }
    
    .btn-primary:hover {
      background-color: #0056b3;
      color: white;
      text-decoration: none;
    }
    
    .btn-warning {
      background-color: #ffc107;
      color: #212529;
    }
    
    .btn-warning:hover {
      background-color: #e0a800;
      color: #212529;
      text-decoration: none;
    }
    
    .btn-danger {
      background-color: #dc3545;
      color: white;
    }
    
    .btn-danger:hover {
      background-color: #c82333;
      color: white;
      text-decoration: none;
    }
    
    /* Photo Modal */
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
    
    /* Two column layout for info fields */
    @media (min-width: 768px) {
      .info-row {
        display: flex;
        margin-left: -10px;
        margin-right: -10px;
      }
      
      .info-col {
        flex: 1;
        padding-left: 10px;
        padding-right: 10px;
      }
    }
    
    /* Responsive adjustments */
    @media (max-width: 768px) {
      .navbar {
        flex-wrap: wrap;
      }
      
      .navbar-menu {
        display: none;
        width: 100%;
        flex-direction: column;
        align-items: flex-start;
        margin-top: 10px;
      }
      
      .navbar-menu.active {
        display: flex;
      }
      
      .nav-link {
        width: 100%;
        margin: 2px 0;
      }
      
      .navbar-toggler {
        display: block;
        margin-left: auto;
      }
      
      .detail-container {
        margin: 15px;
        max-width: 100%;
      }
      
      .detail-body {
        padding: 20px;
      }
      
      .action-buttons {
        flex-direction: column;
      }
      
      .btn {
        text-align: center;
        justify-content: center;
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
    
    <button class="navbar-toggler" onclick="toggleMenu()">☰</button>
    
    <div class="navbar-menu" id="navbarMenu">
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

  <div class="detail-container">
    <div class="detail-header">
      <h3><i class="bi bi-person-badge"></i> Detail Log Absensi</h3>
      <div class="subtitle">ID Log: <?php echo $id_log_absensi; ?></div>
    </div>
    
    <div class="detail-body">
      
      <!-- Informasi Pegawai -->
      <div class="info-section">
        <div class="section-title">
          <i class="bi bi-person-fill"></i>
          Informasi Pegawai
        </div>
        
        <div class="info-row">
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">ID Pegawai</label>
              <div class="info-value highlight"><?php echo $id_pegawai; ?></div>
            </div>
          </div>
          
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">Jenis Absensi</label>
              <div class="info-value"><?php echo $jenis_absensi ?: 'Regular'; ?></div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Informasi Absensi -->
      <div class="info-section">
        <div class="section-title">
          <i class="bi bi-clock-fill"></i>
          Informasi Absensi
        </div>
        
        <div class="info-row">
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">Status Absensi</label>
              <div class="info-value">
                <?php 
                  if($check_mode == 0) {
                    echo '<span class="status-badge status-checkin"><i class="bi bi-box-arrow-in-right"></i> Check In</span>';
                  } else if($check_mode == 1) {
                    echo '<span class="status-badge status-checkout"><i class="bi bi-box-arrow-right"></i> Check Out</span>';
                  } else {
                    echo '<span class="status-badge">Unknown</span>';
                  }
                ?>
              </div>
            </div>
          </div>
          
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">Waktu Absensi</label>
              <div class="info-value">
                <i class="bi bi-calendar3"></i>
                <?php 
                  // Format waktu yang lebih readable
                  date_default_timezone_set('Asia/Jakarta');
                  $formatted_time = date('d M Y, H:i:s', strtotime($waktu_absensi));
                  echo $formatted_time;
                ?>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Foto Absensi -->
      <div class="info-section">
        <div class="section-title">
          <i class="bi bi-camera-fill"></i>
          Foto Absensi
        </div>
        
        <div class="foto-container">
          <?php 
            // Generate foto dari Django berdasarkan waktu absensi
            $date = date('Ymd', strtotime($waktu_absensi));
            $django_media_path = "D:/ABSENSI DEVI/lancar/pemkot/media/huffman_images/";
            $foto_path = $django_media_path . $id_pegawai . "/";
            $pattern = $foto_path . $date . "*_decoded.jpg";
            $files = glob($pattern);
            
            if (!empty($files)) {
              // Ambil foto terbaru
              usort($files, function($a, $b) {
                return strcmp(basename($a), basename($b));
              });
              $foto_file = basename(end($files));
              $web_url = "http://localhost:8000/media/huffman_images/" . $id_pegawai . "/" . $foto_file;
          ?>
            <a href="#photoModal">
              <img src="<?php echo $web_url; ?>" 
                   alt="Foto Absensi" 
                   class="foto-preview"
                   title="Klik untuk memperbesar">
            </a>
            <p class="mt-2 text-muted small">
              <i class="bi bi-info-circle"></i> 
              File: <?php echo $foto_file; ?>
            </p>
            
            <!-- Photo Modal -->
            <div id="photoModal" class="photo-modal">
              <a href="#" class="photo-modal-close">&times;</a>
              <div class="photo-modal-content">
                <img src="<?php echo $web_url; ?>" alt="Foto Absensi Besar">
              </div>
            </div>
            
          <?php } else { ?>
            <div class="no-foto">
              <i class="bi bi-camera-slash" style="font-size: 40px; margin-bottom: 10px;"></i>
              <p><strong>Foto tidak tersedia</strong></p>
              <small>Tidak ada foto yang ditemukan untuk absensi ini</small>
            </div>
          <?php } ?>
        </div>
      </div>
      
      <!-- Informasi Lokasi -->
      <div class="info-section">
        <div class="section-title">
          <i class="bi bi-geo-alt-fill"></i>
          Informasi Lokasi
        </div>
        
        <div class="info-row">
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">Latitude</label>
              <div class="info-value"><?php echo $latitude; ?></div>
            </div>
          </div>
          
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">Longitude</label>
              <div class="info-value"><?php echo $longitude; ?></div>
            </div>
          </div>
        </div>
        
        <div class="info-group">
          <label class="info-label">Nama Lokasi</label>
          <div class="info-value">
            <span id="lokasiDetail">
              <?php echo $nama_lokasi ?: '<span class="text-muted"><i class="bi bi-geo-alt"></i> Loading lokasi...</span>'; ?>
            </span>
          </div>
        </div>
        
        <div class="info-group">
          <label class="info-label">Lihat di Maps</label>
          <div class="info-value">
            <a href="https://www.google.com/maps?q=<?php echo $latitude; ?>,<?php echo $longitude; ?>" 
               target="_blank" 
               class="coordinates-link">
              <i class="bi bi-map"></i> 
              Buka di Google Maps
            </a>
            
            <span style="margin: 0 10px;">|</span>
            
            <a href="https://www.openstreetmap.org/?mlat=<?php echo $latitude; ?>&mlon=<?php echo $longitude; ?>&zoom=18" 
               target="_blank" 
               class="coordinates-link">
              <i class="bi bi-globe"></i> 
              Buka di OpenStreetMap
            </a>
          </div>
        </div>
      </div>
      
      <!-- Informasi Sistem -->
      <div class="info-section">
        <div class="section-title">
          <i class="bi bi-gear-fill"></i>
          Informasi Sistem
        </div>
                  
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">URL Foto Presensi</label>
              <div class="info-value" style="word-break: break-all;">
                <?php echo $url_foto_presensi ?: '-'; ?>
              </div>
            </div>
          </div>
        </div>
        
        <div class="info-row">
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">Created At</label>
              <div class="info-value">
                <?php 
                  if($created_at) {
                    echo '<i class="bi bi-calendar-plus"></i> ' . date('d M Y, H:i:s', strtotime($created_at));
                  } else {
                    echo '-';
                  }
                ?>
              </div>
            </div>
          </div>
          
          <div class="info-col">
            <div class="info-group">
              <label class="info-label">Updated At</label>
              <div class="info-value">
                <?php 
                  if($updated_at) {
                    echo '<i class="bi bi-calendar-check"></i> ' . date('d M Y, H:i:s', strtotime($updated_at));
                  } else {
                    echo '-';
                  }
                ?>
              </div>
            </div>
          </div>
        </div>
        
        <?php if($deleted_at): ?>
        <div class="info-group">
          <label class="info-label">Deleted At</label>
          <div class="info-value" style="background-color: #f8d7da; border-color: #dc3545;">
            <i class="bi bi-trash"></i> 
            <?php echo date('d M Y, H:i:s', strtotime($deleted_at)); ?>
          </div>
        </div>
        <?php endif; ?>
      </div>
      
      <!-- Action Buttons -->
      <div class="action-buttons">
        <a href="<?php echo site_url('log_absensi') ?>" class="btn btn-secondary">
          <i class="bi bi-arrow-left"></i> Kembali ke List
        </a>
        
        <div>
          <a href="<?php echo site_url('log_absensi/update/'.$id_log_absensi) ?>" class="btn btn-warning">
            <i class="bi bi-pencil-square"></i> Edit
          </a>
          
          <a href="<?php echo site_url('log_absensi/delete/'.$id_log_absensi) ?>" 
             class="btn btn-danger"
             onclick="return confirm('Yakin ingin menghapus data absensi ini?')">
            <i class="bi bi-trash"></i> Hapus
          </a>
        </div>
      </div>
    </div>
  </div>

  <!-- Bootstrap JS -->
  <script src="<?php echo base_url('assets/js/jquery.min.js') ?>"></script>
  <script src="<?php echo base_url('assets/bootstrap/js/bootstrap.min.js') ?>"></script>
  
  <script>
  // Toggle menu mobile
  function toggleMenu() {
    var menu = document.getElementById('navbarMenu');
    menu.classList.toggle('active');
  }
  
  // Auto-load lokasi jika kosong
  document.addEventListener('DOMContentLoaded', function() {
    const namaLokasi = '<?php echo $nama_lokasi; ?>';
    const latitude = <?php echo $latitude; ?>;
    const longitude = <?php echo $longitude; ?>;
    
    if (!namaLokasi && latitude && longitude) {
      getLocationName(latitude, longitude, 'lokasiDetail');
    }
  });
  
  // Function untuk mendapatkan nama lokasi
  async function getLocationName(lat, lng, elementId) {
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1&accept-language=id`);
      const data = await response.json();
      
      if (data && data.display_name) {
        const address = data.address;
        const addressParts = [
          address.road || address.pedestrian || address.footway,
          address.suburb || address.village || address.neighbourhood,
          address.subdistrict || address.city_district,
          address.city || address.town || address.county
        ].filter(Boolean);
        
        const locationName = addressParts.slice(0, 3).join(', ');
        
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
  </script>
</body>
</html>