<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Form Pegawai - SI Preti</title>
  <link rel="stylesheet" href="<?php echo base_url('assets/bootstrap/css/bootstrap.min.css') ?>"/>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.0/font/bootstrap-icons.css">
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
    
    /* Photo Upload Styling */
    .photo-upload-container {
      display: flex;
      align-items: flex-start;
      gap: 15px;
      margin-bottom: 15px;
    }
    
    .photo-preview {
      width: 120px;
      height: 120px;
      border: 2px dashed #ddd;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      background-color: #f9f9f9;
      position: relative;
      overflow: hidden;
    }
    
    .photo-preview img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 6px;
    }
    
    .photo-placeholder {
      text-align: center;
      color: #999;
      font-size: 12px;
    }
    
    .photo-upload-controls {
      flex: 1;
    }
    
    .file-input-wrapper {
      position: relative;
      display: inline-block;
      margin-bottom: 10px;
    }
    
    .file-input-wrapper input[type=file] {
      position: absolute;
      left: -9999px;
    }
    
    .file-input-label {
      display: inline-block;
      padding: 8px 16px;
      background-color: #4CAF50;
      color: white;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      transition: background-color 0.3s;
    }
    
    .file-input-label:hover {
      background-color: #45a049;
    }
    
    .file-info {
      font-size: 12px;
      color: #666;
      margin-top: 5px;
    }
    
    .photo-actions {
      margin-top: 10px;
    }
    
    .btn-remove-photo {
      background-color: #dc3545;
      color: white;
      border: none;
      padding: 6px 12px;
      border-radius: 4px;
      font-size: 12px;
      cursor: pointer;
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

    .btn-toggle-password {
  transition: color 0.3s;
}

.btn-toggle-password:hover {
  color: #0056b3 !important;
}

.password-strength {
  margin-top: 5px;
  font-size: 12px;
}

.strength-weak { color: #dc3545; }
.strength-medium { color: #ffc107; }
.strength-strong { color: #28a745; }

.password-match {
  margin-top: 5px;
  font-size: 12px;
}

.match-valid { color: #28a745; }
.match-invalid { color: #dc3545; }
    
    /* Responsive adjustments */
    @media (max-width: 768px) {
      .form-container {
        margin: 15px;
        max-width: 100%;
      }
      
      .photo-upload-container {
        flex-direction: column;
        align-items: center;
      }
      
      .photo-preview {
        width: 150px;
        height: 150px;
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
    </div>
  </nav>

  <div class="form-container">
    <div class="form-header">
      Pegawai <?php echo $button ?>
    </div>
    
    <div class="form-body">
      <form action="<?php echo $action; ?>" method="post" enctype="multipart/form-data">
        
        <!-- Photo Upload Section -->
        <div class="form-group">
          <label class="form-label">Foto Profil</label>
          <div class="photo-upload-container">
            <div class="photo-preview" id="photoPreview">
              <?php if (!empty($image)): ?>
                <img src="http://192.168.1.14:8000/media/<?php echo $image; ?>" alt="Current Photo" id="currentPhoto" onerror="showPlaceholder()">
              <?php else: ?>
                <div class="photo-placeholder">
                  <i class="bi bi-person-fill" style="font-size: 40px; color: #ccc;"></i><br>
                  <span>Tidak ada foto</span>
                </div>
              <?php endif; ?>
            </div>
            
            <div class="photo-upload-controls">
              <div class="file-input-wrapper">
                <input type="file" id="photoUpload" name="photo" accept="image/*" onchange="previewPhoto(this)">
                <label for="photoUpload" class="file-input-label">
                  <i class="bi bi-camera"></i> Pilih Foto
                </label>
              </div>
              
              <div class="file-info">
                Format: JPG, PNG, GIF (Max: 2MB)
              </div>
              
              <div class="photo-actions" id="photoActions" <?php echo empty($image) ? 'style="display:none;"' : ''; ?>>
                <button type="button" class="btn-remove-photo" onclick="removePhoto()">
                  <i class="bi bi-trash"></i> Hapus Foto
                </button>
              </div>
            </div>
          </div>
          <input type="hidden" name="existing_image" value="<?php echo $image; ?>">
        </div>
        
        <div class="form-group">
        <label class="form-label">Jabatan</label>
        <select class="form-control" name="id_jabatan" required>
          <option value="">-- Pilih Jabatan --</option>
          <?php foreach ($jabatan as $j): ?>
            <option value="<?= $j->id_jabatan ?>" <?= ($id_jabatan == $j->id_jabatan) ? 'selected' : '' ?>>
              <?= $j->nama_jabatan ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>

        <div class="form-group">
  <label class="form-label">Unit Kerja <?php echo form_error('id_unit_kerja') ?></label>
  <select name="id_unit_kerja" class="form-control" required>
    <option value="">-- Pilih Unit Kerja --</option>
    <?php if(isset($unit_kerja) && is_array($unit_kerja)): ?>
      <?php foreach ($unit_kerja as $unit): ?>
        <option value="<?= $unit->id_unit_kerja ?>" <?= (isset($id_unit_kerja) && $id_unit_kerja == $unit->id_unit_kerja) ? 'selected' : '' ?>>
          <?= $unit->nama_unit_kerja ?>
        </option>
      <?php endforeach; ?>
    <?php endif; ?>
  </select>
</div>

        
        <div class="form-group">
          <label for="nip" class="form-label">NIP <?php echo form_error('nip') ?></label>
          <input type="text" class="form-control" name="nip" id="nip" placeholder="NIP" value="<?php echo $nip; ?>" />
        </div>
        
        <div class="form-group">
          <label for="nama" class="form-label">Nama <?php echo form_error('nama') ?></label>
          <input type="text" class="form-control" name="nama" id="nama" placeholder="Nama" value="<?php echo $nama; ?>" />
        </div>
        
        <div class="form-group">
          <label for="email" class="form-label">Email <?php echo form_error('email') ?></label>
          <input type="email" class="form-control" name="email" id="email" placeholder="Email" value="<?php echo $email; ?>" />
        </div>
        
        <div class="form-group">
          <label for="no_hp" class="form-label">No Telepon <?php echo form_error('no_hp') ?></label>
          <input type="text" class="form-control" name="no_hp" id="no_hp" placeholder="No Telepon" value="<?php echo $no_hp; ?>" />
        </div>

        <div class="form-group">
          <label for="password" class="form-label">Password <?php echo form_error('password') ?></label>
          <div style="position: relative;">
            <input type="password" 
                  class="form-control" 
                  name="password" 
                  id="password" 
                  placeholder="<?php echo $button == 'Update' ? 'Kosongkan jika tidak ingin mengubah password' : 'Masukkan password'; ?>" 
                  value="" 
                  style="padding-right: 40px;" />
            <button type="button" 
                    class="btn-toggle-password" 
                    onclick="togglePasswordInput()" 
                    style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; color: #007bff; cursor: pointer;">
              <i class="bi bi-eye" id="passwordToggleIcon"></i>
            </button>
          </div>
          <small class="form-text text-muted">
            <?php if ($button == 'Update'): ?>
              Kosongkan jika tidak ingin mengubah password yang sudah ada
            <?php else: ?>
              Minimal 6 karakter. Gunakan kombinasi huruf dan angka untuk keamanan yang lebih baik
            <?php endif; ?>
          </small>
        </div>

        <?php if ($button == 'Update'): ?>
        <div class="form-group">
          <label for="confirm_password" class="form-label">Konfirmasi Password Baru</label>
          <input type="password" 
                class="form-control" 
                name="confirm_password" 
                id="confirm_password" 
                placeholder="Konfirmasi password baru (jika diubah)" />
          <small class="form-text text-muted">Masukkan ulang password baru untuk konfirmasi</small>
        </div>
        <?php else: ?>
        <div class="form-group">
          <label for="confirm_password" class="form-label">Konfirmasi Password <span style="color: red;">*</span></label>
          <input type="password" 
                class="form-control" 
                name="confirm_password" 
                id="confirm_password" 
                placeholder="Konfirmasi password" 
                required />
        </div>
        <?php endif; ?>
        
        <?php if (isset($id_pegawai) && $id_pegawai != ''): ?>
          <input type="hidden" name="id_pegawai" value="<?php echo $id_pegawai; ?>" />
        <?php endif; ?>
        
        <div class="form-actions">
          <a href="<?php echo site_url('pegawai') ?>" class="btn btn-default">Cancel</a>
          <button type="submit" class="btn btn-primary"><?php echo $button ?></button>
        </div>
      </form>
    </div>
  </div>

  <!-- Bootstrap JS -->
  <script src="<?php echo base_url('assets/js/jquery.min.js') ?>"></script>
  <script src="<?php echo base_url('assets/bootstrap/js/bootstrap.min.js') ?>"></script>
  
  <script>

  function togglePasswordInput() {
  var passwordField = document.getElementById('password');
  var toggleIcon = document.getElementById('passwordToggleIcon');
  
  if (passwordField.type === 'password') {
    passwordField.type = 'text';
    toggleIcon.className = 'bi bi-eye-slash';
  } else {
    passwordField.type = 'password';
    toggleIcon.className = 'bi bi-eye';
  }
}

// Password strength checker
document.getElementById('password').addEventListener('input', function() {
  var password = this.value;
  var strengthDiv = document.getElementById('passwordStrength');
  
  if (!strengthDiv) {
    strengthDiv = document.createElement('div');
    strengthDiv.id = 'passwordStrength';
    strengthDiv.className = 'password-strength';
    this.parentNode.parentNode.appendChild(strengthDiv);
  }
  
  if (password.length === 0) {
    strengthDiv.innerHTML = '';
    return;
  }
  
  var strength = 0;
  var feedback = [];
  
  // Length check
  if (password.length >= 8) strength++;
  else feedback.push('minimal 8 karakter');
  
  // Number check
  if (/\d/.test(password)) strength++;
  else feedback.push('gunakan angka');
  
  // Lowercase check
  if (/[a-z]/.test(password)) strength++;
  else feedback.push('gunakan huruf kecil');
  
  // Uppercase check
  if (/[A-Z]/.test(password)) strength++;
  else feedback.push('gunakan huruf besar');
  
  // Special character check
  if (/[^A-Za-z0-9]/.test(password)) strength++;
  
  var strengthText = '';
  var strengthClass = '';
  
  if (strength < 2) {
    strengthText = 'Lemah';
    strengthClass = 'strength-weak';
  } else if (strength < 4) {
    strengthText = 'Sedang';
    strengthClass = 'strength-medium';
  } else {
    strengthText = 'Kuat';
    strengthClass = 'strength-strong';
  }
  
  strengthDiv.innerHTML = `
    <span class="${strengthClass}">Password: ${strengthText}</span>
    ${feedback.length > 0 ? `<br><small>Saran: ${feedback.join(', ')}</small>` : ''}
  `;
});

// Password confirmation checker
document.getElementById('confirm_password').addEventListener('input', function() {
  var password = document.getElementById('password').value;
  var confirmPassword = this.value;
  var matchDiv = document.getElementById('passwordMatch');
  
  if (!matchDiv) {
    matchDiv = document.createElement('div');
    matchDiv.id = 'passwordMatch';
    matchDiv.className = 'password-match';
    this.parentNode.appendChild(matchDiv);
  }
  
  if (confirmPassword.length === 0) {
    matchDiv.innerHTML = '';
    return;
  }
  
  if (password === confirmPassword) {
    matchDiv.innerHTML = '<span class="match-valid"><i class="bi bi-check-circle"></i> Password cocok</span>';
  } else {
    matchDiv.innerHTML = '<span class="match-invalid"><i class="bi bi-x-circle"></i> Password tidak cocok</span>';
  }
});

// Form validation
document.querySelector('form').addEventListener('submit', function(e) {
  var password = document.getElementById('password').value;
  var confirmPassword = document.getElementById('confirm_password').value;
  var isUpdate = '<?php echo $button; ?>' === 'Update';
  
  // Jika mode create, password wajib diisi
  if (!isUpdate && password.length === 0) {
    e.preventDefault();
    alert('Password wajib diisi untuk pegawai baru');
    return;
  }
  
  // Jika password diisi, harus cocok dengan konfirmasi
  if (password.length > 0 && password !== confirmPassword) {
    e.preventDefault();
    alert('Password dan konfirmasi password tidak cocok');
    return;
  }
  
  // Password minimal 6 karakter jika diisi
  if (password.length > 0 && password.length < 6) {
    e.preventDefault();
    alert('Password minimal 6 karakter');
    return;
  }
});


  function toggleMenu() {
    var menu = document.getElementById('navbarMenu');
    menu.classList.toggle('active');
  }
  
  function previewPhoto(input) {
    if (input.files && input.files[0]) {
      var reader = new FileReader();
      
      reader.onload = function(e) {
        var preview = document.getElementById('photoPreview');
        preview.innerHTML = '<img src="' + e.target.result + '" alt="Photo Preview" style="width: 100%; height: 100%; object-fit: cover; border-radius: 6px;">';
        
        document.getElementById('photoActions').style.display = 'block';
      }
      
      reader.readAsDataURL(input.files[0]);
    }
  }
  
  function removePhoto() {
    var preview = document.getElementById('photoPreview');
    preview.innerHTML = '<div class="photo-placeholder"><i class="bi bi-person-fill" style="font-size: 40px; color: #ccc;"></i><br><span>Tidak ada foto</span></div>';
    
    document.getElementById('photoUpload').value = '';
    document.getElementById('photoActions').style.display = 'none';
    
    // Set flag untuk hapus foto existing
    var existingInput = document.querySelector('input[name="existing_image"]');
    if (existingInput) {
      existingInput.value = '';
    }
  }
  
  function showPlaceholder() {
    var preview = document.getElementById('photoPreview');
    preview.innerHTML = '<div class="photo-placeholder"><i class="bi bi-person-fill" style="font-size: 40px; color: #ccc;"></i><br><span>Foto tidak ditemukan</span></div>';
  }
  </script>
</body>
</html>