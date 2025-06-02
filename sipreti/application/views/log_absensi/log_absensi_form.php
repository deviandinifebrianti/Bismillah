<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Form Log Absensi - SI Preti</title>
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
    
    .form-container {
      width: 100%;
      max-width: 800px;
      background-color: white;
      border-radius: 8px;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
      overflow: hidden;
      margin: 30px auto;
    }
    
    .form-header {
      background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
      color: white;
      padding: 20px;
      text-align: center;
    }
    
    .form-header h3 {
      margin: 0;
      font-size: 22px;
      font-weight: 600;
    }
    
    .form-body {
      padding: 30px;
    }
    
    .form-section {
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
    
    .form-group {
      margin-bottom: 20px;
    }
    
    .form-label {
      display: block;
      margin-bottom: 8px;
      font-weight: 600;
      font-size: 14px;
      color: #555;
    }
    
    .form-label .required {
      color: #dc3545;
    }
    
    .form-control {
      width: 100%;
      padding: 12px 15px;
      border: 1px solid #e9ecef;
      border-radius: 6px;
      font-size: 14px;
      transition: all 0.3s ease;
      box-sizing: border-box;
    }
    
    .form-control:focus {
      outline: none;
      border-color: #4CAF50;
      box-shadow: 0 0 0 3px rgba(76, 175, 80, 0.1);
    }
    
    .form-control.error {
      border-color: #dc3545;
    }
    
    .form-select {
      background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e");
      background-position: right 12px center;
      background-repeat: no-repeat;
      background-size: 16px 12px;
      padding-right: 40px;
      appearance: none;
    }
    
    .input-group {
      position: relative;
    }
    
    .input-group-text {
      position: absolute;
      right: 10px;
      top: 50%;
      transform: translateY(-50%);
      color: #6c757d;
      cursor: pointer;
      z-index: 10;
    }
    
    .error-text {
      color: #dc3545;
      font-size: 12px;
      margin-top: 5px;
      display: block;
    }
    
    .help-text {
      color: #6c757d;
      font-size: 12px;
      margin-top: 3px;
    }
    
    .form-actions {
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
      background-color: #4CAF50;
      color: white;
    }
    
    .btn-primary:hover {
      background-color: #45a049;
      color: white;
      text-decoration: none;
    }
    
    .btn-info {
      background-color: #17a2b8;
      color: white;
      font-size: 12px;
      padding: 8px 15px;
    }
    
    .btn-info:hover {
      background-color: #138496;
    }
    
    /* Two column layout for form fields */
    @media (min-width: 768px) {
      .form-row {
        display: flex;
        margin-left: -10px;
        margin-right: -10px;
      }
      
      .form-col {
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
      
      .form-container {
        margin: 15px;
        max-width: 100%;
      }
      
      .form-body {
        padding: 20px;
      }
      
      .form-actions {
        flex-direction: column;
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

  <div class="form-container">
    <div class="form-header">
      <h3>
        <i class="bi bi-<?php echo ($button == 'Update') ? 'pencil-square' : 'plus-circle'; ?>"></i>
        <?php echo $button; ?> Log Absensi
      </h3>
    </div>
    
    <div class="form-body">
      <form action="<?php echo $action; ?>" method="post" id="logAbsensiForm">
        
        <!-- Informasi Pegawai -->
        <div class="form-section">
          <div class="section-title">
            <i class="bi bi-person-fill"></i>
            Informasi Pegawai
          </div>
          
          <div class="form-row">
            <div class="form-col">
              <div class="form-group">
                <label for="id_pegawai" class="form-label">
                  ID Pegawai <span class="required">*</span>
                </label>
                <input type="text" 
                       class="form-control" 
                       name="id_pegawai" 
                       id="id_pegawai" 
                       placeholder="Masukkan ID Pegawai" 
                       value="<?php echo $id_pegawai; ?>" 
                       required />
                <?php if(form_error('id_pegawai')): ?>
                  <span class="error-text"><?php echo form_error('id_pegawai'); ?></span>
                <?php endif; ?>
              </div>
            </div>
            
            <div class="form-col">
              <div class="form-group">
                <label for="jenis_absensi" class="form-label">Jenis Absensi</label>
                <select class="form-control form-select" name="jenis_absensi" id="jenis_absensi">
                  <option value="">Pilih Jenis Absensi</option>
                </select>
                <?php if(form_error('jenis_absensi')): ?>
                  <span class="error-text"><?php echo form_error('jenis_absensi'); ?></span>
                <?php endif; ?>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Informasi Absensi -->
        <div class="form-section">
          <div class="section-title">
            <i class="bi bi-clock-fill"></i>
            Informasi Absensi
          </div>
          
          <div class="form-row">
            <div class="form-col">
              <div class="form-group">
                <label for="check_mode" class="form-label">
                  Check Mode <span class="required">*</span>
                </label>
                <select class="form-control form-select" name="check_mode" id="check_mode" required>
                  <option value="">Pilih Check Mode</option>
                  <option value="0" <?php echo ($check_mode == '0') ? 'selected' : ''; ?>>Check In</option>
                  <option value="1" <?php echo ($check_mode == '1') ? 'selected' : ''; ?>>Check Out</option>
                </select>
                <?php if(form_error('check_mode')): ?>
                  <span class="error-text"><?php echo form_error('check_mode'); ?></span>
                <?php endif; ?>
              </div>
            </div>
            
            <div class="form-col">
              <div class="form-group">
                <label for="waktu_absensi" class="form-label">
                  Waktu Absensi <span class="required">*</span>
                </label>
                <div class="input-group">
                  <input type="datetime-local" 
                         class="form-control" 
                         name="waktu_absensi" 
                         id="waktu_absensi" 
                         value="<?php echo $waktu_absensi ? date('Y-m-d\TH:i', strtotime($waktu_absensi)) : ''; ?>" 
                         required />
                  <span class="input-group-text" onclick="setCurrentTime()">
                    <i class="bi bi-clock" title="Set waktu sekarang"></i>
                  </span>
                </div>
                <?php if(form_error('waktu_absensi')): ?>
                  <span class="error-text"><?php echo form_error('waktu_absensi'); ?></span>
                <?php endif; ?>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Informasi Lokasi -->
        <div class="form-section">
          <div class="section-title">
            <i class="bi bi-geo-alt-fill"></i>
            Informasi Lokasi
          </div>
          
          <div class="form-row">
            <div class="form-col">
              <div class="form-group">
                <label for="latitude" class="form-label">
                  Latitude <span class="required">*</span>
                </label>
                <div class="input-group">
                  <input type="text" 
                         class="form-control" 
                         name="latitude" 
                         id="latitude" 
                         placeholder="Contoh: -7.966123" 
                         value="<?php echo $latitude; ?>" 
                         required />
                  <span class="input-group-text" onclick="getCurrentLocation()">
                    <i class="bi bi-geo-alt" title="Ambil lokasi sekarang"></i>
                  </span>
                </div>
                <?php if(form_error('latitude')): ?>
                  <span class="error-text"><?php echo form_error('latitude'); ?></span>
                <?php endif; ?>
              </div>
            </div>
            
            <div class="form-col">
              <div class="form-group">
                <label for="longitude" class="form-label">
                  Longitude <span class="required">*</span>
                </label>
                <input type="text" 
                       class="form-control" 
                       name="longitude" 
                       id="longitude" 
                       placeholder="Contoh: 112.632456" 
                       value="<?php echo $longitude; ?>" 
                       required />
                <?php if(form_error('longitude')): ?>
                  <span class="error-text"><?php echo form_error('longitude'); ?></span>
                <?php endif; ?>
              </div>
            </div>
          </div>
          
          <div class="form-group">
            <label for="nama_lokasi" class="form-label">Nama Lokasi</label>
            <div class="input-group">
              <input type="text" 
                     class="form-control" 
                     name="nama_lokasi" 
                     id="nama_lokasi" 
                     placeholder="Nama lokasi akan terisi otomatis dari koordinat" 
                     value="<?php echo $nama_lokasi; ?>" />
              <span class="input-group-text" onclick="getLocationFromCoords()">
                <i class="bi bi-search" title="Cari nama lokasi dari koordinat"></i>
              </span>
            </div>
            <small class="help-text">Kosongkan untuk mengisi otomatis berdasarkan koordinat</small>
            <?php if(form_error('nama_lokasi')): ?>
              <span class="error-text"><?php echo form_error('nama_lokasi'); ?></span>
            <?php endif; ?>
          </div>
          
          <div class="form-group">
            <button type="button" class="btn btn-info" onclick="showOnMap()">
              <i class="bi bi-map"></i> Lihat di Maps
            </button>
          </div>
        </div>
        
        <!-- Informasi Teknis -->
        <div class="form-section">
          <div class="section-title">
            <i class="bi bi-gear-fill"></i>
            Informasi Teknis
          </div>
            
            <div class="form-col">
              <div class="form-group">
                <label for="url_foto_presensi" class="form-label">URL Foto Presensi</label>
                <input type="url" 
                       class="form-control" 
                       name="url_foto_presensi" 
                       id="url_foto_presensi" 
                       placeholder="https://example.com/foto.jpg" 
                       value="<?php echo $url_foto_presensi; ?>" />
                <small class="help-text">URL foto dari sistem Django (opsional)</small>
                <?php if(form_error('url_foto_presensi')): ?>
                  <span class="error-text"><?php echo form_error('url_foto_presensi'); ?></span>
                <?php endif; ?>
              </div>
            </div>
          </div>
          
          <div class="form-group">
            <label for="url_dokumen" class="form-label">URL Dokumen</label>
            <input type="url" 
                   class="form-control" 
                   name="url_dokumen" 
                   id="url_dokumen" 
                   placeholder="https://example.com/dokumen.pdf" 
                   value="<?php echo $url_dokumen; ?>" />
            <small class="help-text">URL dokumen pendukung (opsional)</small>
            <?php if(form_error('url_dokumen')): ?>
              <span class="error-text"><?php echo form_error('url_dokumen'); ?></span>
            <?php endif; ?>
          </div>
        </div>
        
        <input type="hidden" name="id_log_absensi" value="<?php echo $id_log_absensi; ?>" /> 
        
        <div class="form-actions">
          <a href="<?php echo site_url('log_absensi') ?>" class="btn btn-secondary">
            <i class="bi bi-arrow-left"></i> Kembali
          </a>
          
          <button type="submit" class="btn btn-primary">
            <i class="bi bi-check-circle"></i> <?php echo $button; ?>
          </button>
        </div>
      </form>
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
  
  // Set waktu sekarang
  function setCurrentTime() {
    const now = new Date();
    const localDateTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    document.getElementById('waktu_absensi').value = localDateTime;
  }
  
  // Ambil lokasi saat ini
  function getCurrentLocation() {
    if (navigator.geolocation) {
      document.getElementById('latitude').placeholder = 'Mengambil lokasi...';
      document.getElementById('longitude').placeholder = 'Mengambil lokasi...';
      
      navigator.geolocation.getCurrentPosition(function(position) {
        document.getElementById('latitude').value = position.coords.latitude;
        document.getElementById('longitude').value = position.coords.longitude;
        document.getElementById('latitude').placeholder = 'Contoh: -7.966123';
        document.getElementById('longitude').placeholder = 'Contoh: 112.632456';
        
        // Auto-fill nama lokasi
        getLocationFromCoords();
      }, function(error) {
        alert('Error: ' + error.message);
        document.getElementById('latitude').placeholder = 'Contoh: -7.966123';
        document.getElementById('longitude').placeholder = 'Contoh: 112.632456';
      });
    } else {
      alert('Geolocation tidak didukung oleh browser ini');
    }
  }
  
  // Ambil nama lokasi dari koordinat
  async function getLocationFromCoords() {
    const lat = document.getElementById('latitude').value;
    const lng = document.getElementById('longitude').value;
    
    if (!lat || !lng) {
      alert('Masukkan koordinat latitude dan longitude terlebih dahulu');
      return;
    }
    
    try {
      document.getElementById('nama_lokasi').placeholder = 'Mencari nama lokasi...';
      
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
        document.getElementById('nama_lokasi').value = locationName;
      } else {
        document.getElementById('nama_lokasi').value = 'Lokasi tidak diketahui';
      }
      
      document.getElementById('nama_lokasi').placeholder = 'Nama lokasi akan terisi otomatis dari koordinat';
    } catch (error) {
      console.error('Error:', error);
      alert('Error mengambil nama lokasi');
      document.getElementById('nama_lokasi').placeholder = 'Nama lokasi akan terisi otomatis dari koordinat';
    }
  }
  
  // Tampilkan di maps
  function showOnMap() {
    const lat = document.getElementById('latitude').value;
    const lng = document.getElementById('longitude').value;
    
    if (!lat || !lng) {
      alert('Masukkan koordinat latitude dan longitude terlebih dahulu');
      return;
    }
    
    const url = `https://www.google.com/maps?q=${lat},${lng}`;
    window.open(url, '_blank');
  }
  
  // Auto-set waktu saat halaman dimuat jika create mode
  document.addEventListener('DOMContentLoaded', function() {
    const waktuField = document.getElementById('waktu_absensi');
    if (!waktuField.value && '<?php echo $button; ?>' === 'Create') {
      setCurrentTime();
    }
  });
  
  // Form validation
  document.getElementById('logAbsensiForm').addEventListener('submit', function(e) {
    const requiredFields = ['id_pegawai', 'check_mode', 'waktu_absensi', 'latitude', 'longitude'];
    let isValid = true;
    
    requiredFields.forEach(function(fieldId) {
      const field = document.getElementById(fieldId);
      if (!field.value.trim()) {
        field.classList.add('error');
        isValid = false;
      } else {
        field.classList.remove('error');
      }
    });
    
    if (!isValid) {
      e.preventDefault();
      alert('Mohon lengkapi semua field yang wajib diisi');
    }
  });
  </script>
</body>
</html>