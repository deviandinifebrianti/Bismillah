<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Daftar Jabatan - SI Preti</title>
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
    
    /* Content styling */
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
    
    .content-area {
      padding: 0 15px 15px 15px;
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
    
    /* Action buttons styling - ditambahkan dari halaman pegawai */
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
    
    .pagination-info {
      margin-top: 15px;
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

  <!-- Content Header -->
  <div class="content-header">
    <h2>Daftar Jabatan</h2>
  </div>

  <!-- Main Content -->
  <div class="content-area">
    <div class="row" style="margin-bottom: 10px">
      <div class="col-md-4">
        <?php echo anchor(site_url('jabatan/create'),'Create', 'class="btn btn-primary"'); ?>
      </div>
      <div class="col-md-4 text-center">
        <div style="margin-top: 8px" id="message">
          <?php echo $this->session->userdata('message') <> '' ? $this->session->userdata('message') : ''; ?>
        </div>
      </div>
      <div class="col-md-1 text-right">
      </div>
      <div class="col-md-3 text-right">
        <form action="<?php echo site_url('jabatan/index'); ?>" class="form-inline" method="get">
          <div class="input-group">
            <input type="text" class="form-control" name="q" value="<?php echo $q; ?>">
            <span class="input-group-btn">
              <?php 
                if ($q <> '')
                {
                  ?>
                  <a href="<?php echo site_url('jabatan'); ?>" class="btn btn-default">Reset</a>
                  <?php
                }
              ?>
              <button class="btn btn-primary" type="submit">Cari</button>
            </span>
          </div>
        </form>
      </div>
    </div>
    
    <div class="table-responsive">
      <table class="table table-bordered" style="margin-bottom: 10px">
        <thead>
          <tr>
            <th>No</th>
            <th>ID Jabatan</th>
            <th>Nama Jabatan</th>
            <th>Aksi</th>
          </tr>
        </thead>
        <tbody>
          <?php
          foreach ($jabatan_data as $jabatan)
          {
            ?>
            <tr>
              <td width="80px"><?php echo ++$start ?></td>
              <td><?php echo $jabatan->id_jabatan ?></td>
              <td><?php echo $jabatan->nama_jabatan ?></td>
              <td style="text-align:center" width="150px">
                <!-- Menggunakan icon action buttons seperti di halaman pegawai -->
                <a href="<?php echo site_url('jabatan/read/'.$jabatan->id_jabatan); ?>" class="action-btn view-btn" title="Lihat"><i class="bi bi-eye-fill"></i></a>
                <a href="<?php echo site_url('jabatan/update/'.$jabatan->id_jabatan); ?>" class="action-btn edit-btn" title="Edit"><i class="bi bi-pencil-fill"></i></a>
                <a href="<?php echo site_url('jabatan/delete/'.$jabatan->id_jabatan); ?>" class="action-btn delete-btn" title="Hapus" onclick="return confirm('Yakin ingin menghapus data ini?')"><i class="bi bi-trash-fill"></i></a>
              </td>
            </tr>
            <?php
          }
          ?>
        </tbody>
      </table>
    </div>
    
    <div class="row pagination-info">
      <div class="col-md-6">
        <a href="#" class="btn btn-primary">Total Record : <?php echo $total_rows ?></a>
      </div>
      <div class="col-md-6 text-right">
        <?php echo $pagination ?>
      </div>
    </div>
  </div>

  <!-- Bootstrap JS and other scripts -->
  <script src="<?php echo base_url('assets/js/jquery.min.js') ?>"></script>
  <script src="<?php echo base_url('assets/bootstrap/js/bootstrap.min.js') ?>"></script>
  
  <!-- Script untuk toggle menu pada mobile -->
  <script>
  function toggleMenu() {
    var menu = document.getElementById('navbarMenu');
    menu.classList.toggle('active');
  }
  </script>
</body>
</html>