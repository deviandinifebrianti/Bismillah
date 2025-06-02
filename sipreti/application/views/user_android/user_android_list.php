<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Daftar User Android - Sipreti</title>
  <link rel="stylesheet" href="<?php echo base_url('assets/bootstrap/css/bootstrap.min.css') ?>"/>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.0/font/bootstrap-icons.css">
  <style>
    /* CSS tetap sama seperti kode asli Anda */
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      background-color: #f8f9fa;
    }
    
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
      font-size: 12px; /* Ukuran font header lebih kecil karena banyak kolom */
    }
    
    .table td {
      padding: 8px 10px;
      border: 1px solid #ddd;
      text-align: center;
      font-size: 12px; /* Ukuran font data lebih kecil */
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
    }
    
    .view-btn { background-color: #6cb33f; }
    .edit-btn { background-color: #17a2b8; }
    .delete-btn { background-color: #dc3545; }
    
    .badge {
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: normal;
    }
    
    .badge-success {
      background-color: #28a745;
      color: white;
    }
    
    .badge-secondary {
      background-color: #6c757d;
      color: white;
    }
    
    .table-responsive {
      overflow-x: auto;
    }
    
    /* Style untuk teks yang lebih pendek di kolom device info */
    .device-info {
      font-size: 11px;
      max-width: 100px;
      word-wrap: break-word;
    }
    
    .footer {
      background-color: #ccc;
      padding: 8px 15px;
      text-align: center;
      color: #333;
      font-size: 12px;
      margin-top: 30px;
    }
    
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

<!-- Header -->
<div class="content-header">
  <h2>Daftar User Android</h2>
</div>

<!-- Konten -->
<div class="container-fluid">
  <div class="search-container">
    <form action="<?php echo site_url('user_android/index'); ?>" class="search-box" method="get">
      <input type="text" class="form-control" name="q" value="<?php echo $q; ?>" placeholder="Cari user...">
      <button class="btn btn-primary" type="submit">Cari</button>
      <?php if ($q != '') { ?>
        <a href="<?php echo site_url('user_android'); ?>" class="btn btn-secondary ms-2">Reset</a>
      <?php } ?>
    </form>
    <a href="<?php echo site_url('user_android/create'); ?>" class="btn add-button">+ Tambah User</a>
  </div>

  <!-- Pesan Notifikasi -->
  <?php if ($this->session->userdata('message') != ''): ?>
  <div class="alert alert-success alert-dismissible fade show mb-3">
    <?php echo $this->session->userdata('message'); ?>
    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
  </div>
  <?php endif; ?>

  <!-- Tabel - Desain tetap sama, tapi data lengkap -->
  <div class="table-responsive">
    <table class="table table-bordered">
      <thead>
        <tr>
          <th>No</th>
          <th>Id Pegawai</th>
          <th>Username</th>
          <th>Email</th>
          <th>Device ID</th>
          <th>Device Brand</th>
          <th>Device Model</th>
          <th>OS Version</th>
          <th>SDK Version</th>
          <th>Last Login</th>
          <th>Aksi</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($user_android_data as $user_android): ?>
        <tr>
          <td width="50px"><?php echo ++$start ?></td>
          <td><?php echo $user_android->id_pegawai ?></td>
          <td><?php echo $user_android->username ?></td>
          <td class="device-info">
            <?php 
            // Prioritas: email dari user_android, jika kosong ambil dari pegawai
            $email_display = '';
            if (!empty($user_android->email)) {
              $email_display = $user_android->email;
            } elseif (!empty($user_android->pegawai_email)) {
              $email_display = $user_android->pegawai_email . ' <small class="text-muted">(dari pegawai)</small>';
            } else {
              $email_display = '<span class="text-muted">-</span>';
            }
            echo $email_display;
            ?>
          </td>
          <td class="device-info">
            <?php echo $user_android->device_id ?: '<span class="text-muted">-</span>'; ?>
          </td>
          <td class="device-info">
            <?php echo $user_android->device_brand ?: '<span class="text-muted">-</span>'; ?>
          </td>
          <td class="device-info">
            <?php echo $user_android->device_model ?: '<span class="text-muted">-</span>'; ?>
          </td>
          <td class="device-info">
            <?php echo $user_android->device_os_version ?: '<span class="text-muted">-</span>'; ?>
          </td>
          <td class="device-info">
            <?php echo $user_android->device_sdk_version ?: '<span class="text-muted">-</span>'; ?>
          </td>
          <td class="device-info">
            <?php 
            if ($user_android->last_login) {
              echo date('d/m/Y<br>H:i', strtotime($user_android->last_login));
            } else {
              echo '<span class="text-muted">-</span>';
            }
            ?>
          </td>
          <td>
            <a href="<?php echo site_url('user_android/read/'.$user_android->id_user_android.'?start='.$start.'&q='.urlencode($q)); ?>" class="action-btn view-btn" title="Lihat"><i class="bi bi-eye-fill"></i></a>
            <a href="<?php echo site_url('user_android/delete/'.$user_android->id_user_android); ?>" class="action-btn delete-btn" title="Hapus" onclick="return confirm('Yakin ingin menghapus data ini?')"><i class="bi bi-trash-fill"></i></a>
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

<script src="<?php echo base_url('assets/js/jquery.min.js'); ?>"></script>
<script src="<?php echo base_url('assets/bootstrap/js/bootstrap.min.js'); ?>"></script>

<script>
function toggleMenu() {
  var menu = document.getElementById('navbarMenu');
  menu.classList.toggle('active');
}
</script>

</body>
</html>