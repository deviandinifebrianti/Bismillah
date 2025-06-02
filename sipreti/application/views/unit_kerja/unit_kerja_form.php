<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Tambah Unit Kerja - SI Preti</title>
  <link rel="stylesheet" href="<?php echo base_url('assets/bootstrap/css/bootstrap.min.css') ?>"/>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      background-color: #e0e0e0;
    }
    
    /* Header navbar styling tanpa ul li */
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
      margin-left: auto; /* Penting: ini membuat menu berada di kanan */
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
    
    /* Form styling */
    .form-container {
      width: 100%;
      max-width: 850px;
      background-color: white;
      border-radius: 5px;
      box-shadow: 0 2px 5px rgba(0,0,0,0.1);
      overflow: hidden;
      margin: 30px auto;
    }
    
    .form-header {
      background-color: #4CAF50;
      color: white;
      padding: 12px 15px;
      font-size: 18px;
      font-weight: 600;
    }
    
    .form-body {
      padding: 20px;
    }
    
    .form-description {
      margin-bottom: 20px;
      font-size: 14px;
      color: #666;
      font-style: italic;
    }
    
    .form-group {
      margin-bottom: 15px;
    }
    
    .form-label {
      display: block;
      margin-bottom: 5px;
      font-weight: 500;
      font-size: 14px;
    }
    
    .form-control {
      width: 100%;
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
    }
    
    .form-control:focus {
      outline: none;
      border-color: #4CAF50;
      box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.2);
    }
    
    .form-control[readonly] {
      background-color: #f9f9f9;
    }
    
    .map-container {
      margin-top: 20px;
      margin-bottom: 20px;
    }
    
    #map {
      height: 400px;
      width: 100%;
      border-radius: 4px;
      border: 1px solid #ddd;
    }
    
    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: 10px;
      margin-top: 20px;
    }
    
    .btn {
      padding: 8px 20px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-weight: 500;
      font-size: 14px;
    }
    
    .btn-default, .btn-secondary {
      background-color: #f5f5f5;
      color: #333;
    }
    
    .btn-primary {
      background-color: #9C27B0;
      color: white;
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
      .form-container {
        margin: 15px;
        max-width: 100%;
      }
      
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
    }
  </style>
</head>
<body>
  <!-- Header dengan Navbar tanpa ul li -->
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
    </div>
  </nav>

  <div class="form-container">
    <div class="form-header">
      Tambah Unit Kerja
    </div>
    
    <div class="form-body">
      <div class="form-description">
        Klik peta atau isi nama unit kerja untuk mengambil lokasi otomatis.
      </div>
      
      <form action="<?= $action ?>" method="post">
        <div class="form-row">
          <div class="form-col">
            <div class="form-group">
              <label for="nama_unit" class="form-label">Nama Unit Kerja</label>
              <input type="text" id="nama_unit" name="nama_unit_kerja" class="form-control" value="<?= $nama_unit_kerja ?>" onblur="cariLokasi()" required>
            </div>
            
            <div class="form-group">
              <label for="alamat" class="form-label">Alamat</label>
              <input type="text" id="alamat" name="alamat" class="form-control" value="<?= $alamat ?>" readonly>
            </div>
          </div>
          
          <div class="form-col">
            <div class="form-group">
              <label for="id_radius" class="form-label">Radius Absen</label>
              <select name="id_radius" id="id_radius" class="form-control" required>
                <option value="">-- Pilih Radius --</option>
                <?php foreach ($radius_data as $r): ?>
                  <option value="<?= $r->id_radius ?>" <?= ($id_radius == $r->id_radius) ? 'selected' : '' ?>>
                    <?= $r->id_radius ?>
                  </option>
                <?php endforeach; ?>
              </select>
            </div>
            
            <div class="form-row">
              <div class="form-col">
                <div class="form-group">
                  <label for="latitude" class="form-label">Latitude</label>
                  <input type="text" id="latitude" name="latitude" class="form-control" value="<?= $latitude ?>" readonly>
                </div>
              </div>
              
              <div class="form-col">
                <div class="form-group">
                  <label for="longitude" class="form-label">Longitude</label>
                  <input type="text" id="longitude" name="longitude" class="form-control" value="<?= $longitude ?>" readonly>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div class="map-container">
          <div id="map"></div>
        </div>
        
        <div class="form-actions">
          <a href="<?= site_url('unit_kerja') ?>" class="btn btn-secondary">Kembali</a>
          <button type="submit" class="btn btn-primary">Simpan</button>
        </div>
      </form>
    </div>
  </div>

  <!-- LIBRARY -->
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="<?php echo base_url('assets/bootstrap/js/bootstrap.min.js') ?>"></script>

  <!-- Script untuk toggle menu pada mobile -->
  <script>
  function toggleMenu() {
    var menu = document.getElementById('navbarMenu');
    menu.classList.toggle('active');
  }
  </script>

  <!-- SCRIPT PETA -->
  <script>
  let map = L.map('map').setView([-7.9797, 112.6304], 13);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors'
  }).addTo(map);

  let marker = null;
  let circle = null;

  // Fungsi global menggambar radius
  function gambarRadius(lat, lng) {
    const idRadius = $('#id_radius').val();
    if (!idRadius || isNaN(lat) || isNaN(lng)) return;

    $.ajax({
      url: "<?php echo site_url('radius_absen/get_detail_json/') ?>" + idRadius,
      type: "GET",
      dataType: "json",
      success: function (data) {
        if (circle) {
          map.removeLayer(circle);
        }

        circle = L.circle([lat, lng], {
          radius: parseFloat(data.ukuran),
          color: 'blue',
          fillColor: '#cce5ff',
          fillOpacity: 0.3
        }).addTo(map);
      },
      error: function () {
        console.error('Gagal mengambil data radius');
      }
    });
  }

  map.on('click', function(e) {
    const lat = e.latlng.lat;
    const lng = e.latlng.lng;

    if (marker) {
      marker.setLatLng(e.latlng);
    } else {
      marker = L.marker(e.latlng).addTo(map);
    }

    document.getElementById('latitude').value = lat;
    document.getElementById('longitude').value = lng;

    fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`)
      .then(res => res.json())
      .then(data => {
        document.getElementById('alamat').value = data.display_name || '';
      })
      .catch(err => console.error(err));

    gambarRadius(lat, lng);
  });

  $('#id_radius').on('change', function () {
    const lat = parseFloat($('#latitude').val());
    const lng = parseFloat($('#longitude').val());
    gambarRadius(lat, lng);
  });

  // Fungsi cari lokasi berdasarkan nama
  function cariLokasi() {
    var namaUnit = document.getElementById('nama_unit').value;
    if (namaUnit === '') return false;

    fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(namaUnit)}`)
      .then(response => response.json())
      .then(data => {
        if (data.length > 0) {
          const lokasi = data[0];
          document.getElementById('alamat').value = lokasi.display_name;
          document.getElementById('latitude').value = lokasi.lat;
          document.getElementById('longitude').value = lokasi.lon;

          const latlng = L.latLng(lokasi.lat, lokasi.lon);
          if (marker) {
            marker.setLatLng(latlng);
          } else {
            marker = L.marker(latlng).addTo(map);
          }
          map.setView(latlng, 16);

          gambarRadius(parseFloat(lokasi.lat), parseFloat(lokasi.lon));
        } else {
          alert('Lokasi tidak ditemukan!');
        }
      })
      .catch(err => {
        console.error(err);
        alert('Gagal mengambil lokasi');
      });

    return false;
  }

  $('#nama_unit').keypress(function (e) {
    if (e.which == 13) {
      e.preventDefault();
      cariLokasi();
    }
  });
  </script>
</body>
</html>