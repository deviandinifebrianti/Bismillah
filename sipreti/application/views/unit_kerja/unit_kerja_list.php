<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Daftar Unit Kerja - Sipreti</title>
  <link rel="stylesheet" href="<?php echo base_url('assets/bootstrap/css/bootstrap.min.css') ?>"/>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.0/font/bootstrap-icons.css">
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      background-color: #f8f9fa;
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
    
    .table-responsive {
      overflow-x: auto;
    }
    
    .footer {
      background-color: #ccc;
      padding: 8px 15px;
      text-align: center;
      color: #333;
      font-size: 12px;
      margin-top: 30px;
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
    <a href="<?php echo site_url('biometrik'); ?>" class="nav-link">Tambah Gambar</a>
  </div>
</nav>

<!-- Header -->
<div class="content-header">
  <h2>Daftar Unit Kerja</h2>
</div>

<!-- Konten -->
<div class="container-fluid">
  <div class="search-container">
    <form action="<?php echo site_url('unit_kerja/index'); ?>" class="search-box" method="get">
      <input type="text" class="form-control" name="q" value="<?php echo $q; ?>" placeholder="Cari unit kerja...">
      <button class="btn btn-primary" type="submit">Cari</button>
      <?php if ($q != '') { ?>
        <a href="<?php echo site_url('unit_kerja'); ?>" class="btn btn-secondary ms-2">Reset</a>
      <?php } ?>
    </form>
    <a href="<?php echo site_url('unit_kerja/create'); ?>" class="btn add-button">+ Tambah Unit</a>
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
          <th>Id Unit Kerja</th>
          <th>Id Radius</th>
          <th>Nama Unit Kerja</th>
          <th>Alamat</th>
          <th>Latitude</th>
          <th>Longitude</th>
          <th>Aksi</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($unit_kerja_data as $unit_kerja): ?>
        <tr>
          <td width="80px"><?php echo ++$start ?></td>
          <td><?php echo $unit_kerja->id_unit_kerja ?></td>
          <td><?php echo $unit_kerja->id_radius ?></td>
          <td><?php echo $unit_kerja->nama_unit_kerja ?></td>
          <td><?php echo $unit_kerja->alamat ?></td>
          <td><?php echo $unit_kerja->latitude ?></td>
          <td><?php echo $unit_kerja->longitude ?></td>
          <td>
            <a href="<?php echo site_url('unit_kerja/read/'.$unit_kerja->id_unit_kerja); ?>" class="action-btn view-btn" title="Lihat"><i class="bi bi-eye-fill"></i></a>
            <a href="<?php echo site_url('unit_kerja/update/'.$unit_kerja->id_unit_kerja); ?>" class="action-btn edit-btn" title="Edit"><i class="bi bi-pencil-fill"></i></a>
            <a href="<?php echo site_url('unit_kerja/delete/'.$unit_kerja->id_unit_kerja); ?>" class="action-btn delete-btn" title="Hapus" onclick="return confirm('Yakin ingin menghapus data ini?')"><i class="bi bi-trash-fill"></i></a>
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

<!-- Script untuk toggle menu pada mobile -->
<script>
function toggleMenu() {
  var menu = document.getElementById('navbarMenu');
  menu.classList.toggle('active');
}
</script>

</body>
</html>