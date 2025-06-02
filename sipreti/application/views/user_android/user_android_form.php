<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Form User Android - SI Preti</title>
  <link rel="stylesheet" href="<?php echo base_url('assets/bootstrap/css/bootstrap.min.css') ?>"/>
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
      font-size: 15px;
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
      max-width: 600px;
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
    
    .error-text {
      color: #dc3545;
      font-size: 12px;
      margin-top: 3px;
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
    
    .btn-default {
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
      <img src="<?= base_url('assets/datatables/images/logo.jpg') ?>" alt="SI Preti Logo"> SI Preti
    </a>
    
    <button class="navbar-toggler" onclick="toggleMenu()">☰</button>
    
    <div class="navbar-menu" id="navbarMenu">
      <a href="<?php echo site_url('welcome'); ?>" class="nav-link">Dashboard</a>
      <a href="<?php echo site_url('log_absensi'); ?>" class="nav-link">Log Absensi</a>
      <a href="<?php echo site_url('pegawai'); ?>" class="nav-link">Pegawai</a>
      <a href="<?php echo site_url('user_android'); ?>" class="nav-link">User Android</a>
      <a href="<?php echo site_url('vektor_pegawai'); ?>" class="nav-link">Vektor Pegawai</a>
    </div>
  </nav>

  <div class="form-container">
    <div class="form-header">
      User Android <?php echo $button ?>
    </div>
    
    <div class="form-body">
      <form action="<?php echo $action; ?>" method="post">
        <div class="form-row">
          <div class="form-col">
            <div class="form-group">
              <label for="id_pegawai" class="form-label">ID Pegawai <?php echo form_error('id_pegawai') ?></label>
              <input type="text" class="form-control" name="id_pegawai" id="id_pegawai" placeholder="ID Pegawai" value="<?php echo $id_pegawai; ?>" />
            </div>
          </div>
          
          <div class="form-col">
            <div class="form-group">
              <label for="username" class="form-label">Username <?php echo form_error('username') ?></label>
              <input type="text" class="form-control" name="username" id="username" placeholder="Username" value="<?php echo $username; ?>" />
            </div>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-col">
            <div class="form-group">
              <label for="email" class="form-label">Email <?php echo form_error('email') ?></label>
              <input type="email" class="form-control" name="email" id="email" placeholder="Email" value="<?php echo $email; ?>" />
            </div>
          </div>
          
          <div class="form-col">
            <div class="form-group">
              <label for="no_hp" class="form-label">No. HP <?php echo form_error('no_hp') ?></label>
              <input type="text" class="form-control" name="no_hp" id="no_hp" placeholder="No. HP" value="<?php echo $no_hp; ?>" />
            </div>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-col">
            <div class="form-group">
              <label for="valid_hp" class="form-label">Valid HP <?php echo form_error('valid_hp') ?></label>
              <input type="text" class="form-control" name="valid_hp" id="valid_hp" placeholder="Valid HP" value="<?php echo $valid_hp; ?>" />
            </div>
          </div>
          
          <div class="form-col">
            <div class="form-group">
              <label for="imei" class="form-label">IMEI <?php echo form_error('imei') ?></label>
              <input type="text" class="form-control" name="imei" id="imei" placeholder="IMEI" value="<?php echo $imei; ?>" />
            </div>
          </div>
        </div>
        
        <input type="hidden" name="id_user_android" value="<?php echo $id_user_android; ?>" /> 
        
        <div class="form-actions">
          <a href="<?php echo site_url('user_android') ?>" class="btn btn-default">Cancel</a>
          <button type="submit" class="btn btn-primary"><?php echo $button ?></button>
        </div>
      </form>
    </div>
  </div>

  <!-- Bootstrap JS -->
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