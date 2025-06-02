<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Sipreti - Pemerintah Kota Malang</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: Arial, sans-serif;
      overflow-x: hidden;
    }
    
    /* Header navbar styling */
    .navbar {
      background-color: #330066 !important;
      padding: 0.3rem;
    }
    
    .navbar-brand {
      display: flex;
      align-items: center;
      font-weight: bold;
      color: white;
      font-size: 1.25rem;
      margin-left: 10px;
    }
    
    .navbar-brand img {
      height: 30px;
      margin-right: 10px;
    }
    
    .navbar-nav .nav-link {
      color: white !important;
      font-size: 0.9rem;
      padding: 0.5rem 0.7rem;
    }
    
    /* Full screen background image */
    .hero-section {
      position: relative;
      width: 100%;
      height: calc(100vh - 56px); /* Full height minus navbar */
      background-image: url('<?= base_url('assets/datatables/images/pemkot.jpg') ?>'); /* Replace with your image path */
      background-size: cover;
      background-position: center;
      color: white;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
    }
    
    .hero-section::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-color: rgba(0, 0, 0, 0.35);
    }
    
    .hero-content {
      position: relative;
      z-index: 2;
      text-align: center;
      width: 100%;
    }
    
    .hero-title {
      font-size: 2.8rem;
      font-weight: bold;
      margin-bottom: 0.5rem;
      text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.7);
    }
    
    .hero-subtitle {
      font-size: 1.1rem;
      text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
    }
    
    .scroll-down {
      position: absolute;
      bottom: 20px;
      font-size: 0.75rem;
      color: white;
      text-transform: uppercase;
      letter-spacing: 1px;
      z-index: 2;
    }
  </style>
</head>
<body>

  <!-- Header dan Navbar -->
  <nav class="navbar navbar-expand-lg navbar-dark">
    <div class="container-fluid">
      <a class="navbar-brand" href="#">
        <img src="<?= base_url('assets/datatables/images/logo.jpg') ?>" alt="SI Preti Logo" class="d-inline-block align-text-top"> Sipreti
      </a>
      <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
        <span class="navbar-toggler-icon"></span>
      </button>
      
      <div class="collapse navbar-collapse" id="navbarNav">
        <ul class="navbar-nav ms-auto">
          <li class="nav-item"><a class="nav-link" href="<?= base_url('pegawai'); ?>">Pegawai</a></li>
          <li class="nav-item"><a class="nav-link" href="<?= base_url('jabatan'); ?>">Jabatan</a></li>
          <li class="nav-item"><a class="nav-link" href="<?= base_url('radius_absen'); ?>">Radius Absen</a></li>
          <li class="nav-item"><a class="nav-link" href="<?= base_url('log_absensi'); ?>">Log Absensi</a></li>
		  <li class="nav-item"><a class="nav-link" href="<?= base_url('unit_kerja'); ?>">Unit Kerja</a></li>
		  <li class="nav-item"><a class="nav-link" href="<?= base_url('user_android'); ?>">User Android</a></li>
      <li class="nav-item"><a class="nav-link" href="<?= base_url('biometrik'); ?>">Tambah Gambar</a></li>
        </ul>
      </div>
    </div>
    </div>
  </nav>

  <!-- Hero Section with Background Image -->
  <section class="hero-section">
    <div class="hero-content">
      <h1 class="hero-title">Pemerintah Kota Malang</h1>
      <p class="hero-subtitle">Pendidikan, Perdagangan dan Jasa, Ekonomi, Kreatif, Pariwisata</p>
    </div>
  </section>

  <!-- Bootstrap JS -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>