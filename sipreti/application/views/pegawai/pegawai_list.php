<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Daftar Pegawai - Sipreti</title>
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
      align-items: center;
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
    
    .action-buttons {
      display: flex;
      gap: 10px;
    }
    
    .add-button {
      background-color: #9C27B0;
      color: white;
      border: none;
    }
    
    .refresh-button {
      background-color: #17a2b8;
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
    
    /* Style untuk foto profil */
    .profile-photo {
      width: 50px;
      height: 50px;
      object-fit: cover;
      border-radius: 8px;
      border: 2px solid #ddd;
      cursor: pointer;
      transition: transform 0.2s;
    }
    
    .profile-photo:hover {
      transform: scale(1.1);
      border-color: #007bff;
    }
    
    .no-photo {
      width: 50px;
      height: 50px;
      background-color: #f8f9fa;
      border: 2px dashed #ccc;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #999;
      font-size: 12px;
    }
    
    .photo-container {
      position: relative;
    }
    
    .photo-refresh {
      position: absolute;
      top: -5px;
      right: -5px;
      background: #007bff;
      color: white;
      border: none;
      border-radius: 50%;
      width: 20px;
      height: 20px;
      font-size: 10px;
      cursor: pointer;
      display: none;
    }
    
    .photo-container:hover .photo-refresh {
      display: block;
    }
    
    .footer {
      background-color: #ccc;
      padding: 8px 15px;
      text-align: center;
      color: #333;
      font-size: 12px;
      margin-top: 30px;
    }
    
    /* Modal untuk preview foto */
    .modal-photo {
      max-width: 100%;
      max-height: 70vh;
      object-fit: contain;
    }
    
    /* Loading spinner */
    .loading-spinner {
      display: inline-block;
      width: 16px;
      height: 16px;
      border: 2px solid #f3f3f3;
      border-top: 2px solid #007bff;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-left: 5px;
    }
    
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    
    /* Success message */
    .success-message {
      background-color: #d4edda;
      color: #155724;
      padding: 10px 15px;
      border: 1px solid #c3e6cb;
      border-radius: 4px;
      margin-bottom: 15px;
    }

    .password-masked {
  display: flex;
  align-items: center;
  gap: 5px;
}

.password-dots {
  font-family: monospace;
  letter-spacing: 2px;
  color: #666;
}

.password-text {
  font-family: monospace;
  background-color: #f8f9fa;
  padding: 2px 6px;
  border-radius: 3px;
  border: 1px solid #ddd;
  font-size: 12px;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.btn-show-password {
  background: none;
  border: none;
  color: #007bff;
  cursor: pointer;
  padding: 2px;
  font-size: 12px;
}

.btn-show-password:hover {
  background-color: rgba(0, 123, 255, 0.1);
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
      
      .search-container {
        flex-direction: column;
        gap: 10px;
      }
      
      .action-buttons {
        justify-content: center;
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
  <h2>Daftar Pegawai</h2>
</div>

<!-- Konten -->
<div class="container-fluid">
  <!-- Success Message -->
  <?php if($this->session->flashdata('message')): ?>
    <div class="success-message">
      <?php echo $this->session->flashdata('message'); ?>
    </div>
  <?php endif; ?>

  <div class="search-container">
    <form action="<?php echo site_url('pegawai/index'); ?>" class="search-box" method="get">
      <input type="text" class="form-control" name="q" value="<?php echo $q; ?>" placeholder="Cari pegawai...">
      <button class="btn btn-primary" type="submit">Cari</button>
      <?php if ($q != '') { ?>
        <a href="<?php echo site_url('pegawai'); ?>" class="btn btn-secondary ms-2">Reset</a>
      <?php } ?>
    </form>
    
    <div class="action-buttons">
      <button onclick="refreshAllPhotos()" class="btn refresh-button" id="refreshBtn">
        <i class="bi bi-arrow-clockwise"></i> Refresh Foto
      </button>
      <a href="<?php echo site_url('pegawai/create'); ?>" class="btn add-button">
        <i class="bi bi-plus"></i> Tambah
      </a>
    </div>
  </div>

  <!-- Tabel -->
  <div class="table-responsive">
    <table class="table table-bordered">
      <thead>
        <tr>
          <th>No</th>
          <th>ID Pegawai</th>
          <th>Jabatan</th>
          <th>Unit Kerja</th>
          <th>NIP</th>
          <th>Nama</th>
          <th>Email</th>
          <th>No HP</th>
          <th>Password</th>
          <th>Foto</th>
          <th>Aksi</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($pegawai_data as $index => $pegawai): ?>
        <tr data-pegawai-id="<?php echo $pegawai->id_pegawai; ?>">
          <td><?php echo ++$start; ?></td>
          <td><?php echo $pegawai->id_pegawai; ?></td>
          
          <td><?php echo !empty($pegawai->nama_jabatan) ? $pegawai->nama_jabatan : 'N/A'; ?></td>
<td><?php echo !empty($pegawai->nama_unit_kerja) ? $pegawai->nama_unit_kerja : 'N/A'; ?></td>
          
          <td><?php echo $pegawai->nip; ?></td>
          <td><?php echo $pegawai->nama; ?></td>
          <td><?php echo $pegawai->email; ?></td>
          <td><?php echo $pegawai->no_hp; ?></td>
  <td>
  <?php if (isset($pegawai->password) && $pegawai->password !== '' && $pegawai->password !== null): ?>
    <span class="password-masked" id="password-<?php echo $pegawai->id_pegawai; ?>">
      <span class="password-dots">••••••••</span>
      <button class="btn-show-password" onclick="togglePassword(<?php echo $pegawai->id_pegawai; ?>)">
        <i class="bi bi-eye" id="eye-icon-<?php echo $pegawai->id_pegawai; ?>"></i>
      </button>
      <span class="password-text" style="display: none;"><?php echo $pegawai->password; ?></span>
    </span>
  <?php else: ?>
    <span class="text-muted">No Password</span>
  <?php endif; ?>
</td>
          <td>
            <div class="photo-container">
              <?php if (!empty($pegawai->image)): ?>
                <?php 
                  // Langsung ambil dari Django
                  $django_photo = "http://35.247.167.202:8000/media/" . $pegawai->image;
                ?>
                <img src="<?php echo $django_photo; ?>?t=<?php echo time(); ?>" 
                    class="profile-photo" 
                    alt="Foto <?php echo $pegawai->nama; ?>"
                    id="photo-<?php echo $pegawai->id_pegawai; ?>"
                    onclick="showPhotoModal('<?php echo $django_photo; ?>', '<?php echo $pegawai->nama; ?>')"
                    onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div class="no-photo" style="display: none;">
                  <i class="bi bi-person"></i>
                </div>
                <button class="photo-refresh" onclick="refreshSinglePhoto(<?php echo $pegawai->id_pegawai; ?>)" title="Refresh foto">
                  <i class="bi bi-arrow-clockwise"></i>
                </button>
              <?php else: ?>
                <div class="no-photo" id="photo-<?php echo $pegawai->id_pegawai; ?>">
                  <i class="bi bi-person"></i>
                </div>
                <button class="photo-refresh" onclick="refreshSinglePhoto(<?php echo $pegawai->id_pegawai; ?>)" title="Check foto baru">
                  <i class="bi bi-arrow-clockwise"></i>
                </button>
              <?php endif; ?>
            </div>
          </td>
          <td>
            <a href="<?php echo site_url('pegawai/read/'.$pegawai->id_pegawai); ?>" class="action-btn view-btn" title="Lihat"><i class="bi bi-eye-fill"></i></a>
            <a href="<?php echo site_url('pegawai/update/'.$pegawai->id_pegawai); ?>" class="action-btn edit-btn" title="Edit"><i class="bi bi-pencil-fill"></i></a>
            <a href="<?php echo site_url('pegawai/delete/'.$pegawai->id_pegawai); ?>" class="action-btn delete-btn" title="Hapus" onclick="return confirm('Yakin ingin menghapus data ini?')"><i class="bi bi-trash-fill"></i></a>
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

<!-- Modal untuk preview foto -->
<div class="modal fade" id="photoModal" tabindex="-1" aria-labelledby="photoModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="photoModalLabel">Foto Profil</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body text-center">
        <img id="modalPhoto" src="" class="modal-photo" alt="Foto Profil">
      </div>
    </div>
  </div>
</div>

<script src="<?php echo base_url('assets/js/jquery.min.js'); ?>"></script>
<script src="<?php echo base_url('assets/bootstrap/js/bootstrap.min.js'); ?>"></script>

<!-- Script untuk toggle menu pada mobile -->
<script>
function togglePassword(idPegawai) {
  var passwordDots = document.querySelector('#password-' + idPegawai + ' .password-dots');
  var passwordText = document.querySelector('#password-' + idPegawai + ' .password-text');
  var eyeIcon = document.getElementById('eye-icon-' + idPegawai);
  
  if (passwordText.style.display === 'none') {
    passwordDots.style.display = 'none';
    passwordText.style.display = 'inline';
    eyeIcon.className = 'bi bi-eye-slash';
    
    setTimeout(function() {
      passwordDots.style.display = 'inline';
      passwordText.style.display = 'none';
      eyeIcon.className = 'bi bi-eye';
    }, 3000);
  } else {
    passwordDots.style.display = 'inline';
    passwordText.style.display = 'none';
    eyeIcon.className = 'bi bi-eye';
  }
}

function toggleMenu() {
  var menu = document.getElementById('navbarMenu');
  menu.classList.toggle('active');
}

function showPhotoModal(imageUrl, nama) {
  // Add timestamp to force refresh in modal too
  var timestampedUrl = imageUrl + (imageUrl.includes('?') ? '&' : '?') + 't=' + new Date().getTime();
  document.getElementById('modalPhoto').src = timestampedUrl;
  document.getElementById('photoModalLabel').textContent = 'Foto Profil - ' + nama;
  
  var photoModal = new bootstrap.Modal(document.getElementById('photoModal'));
  photoModal.show();
}

// Refresh single photo
function refreshSinglePhoto(idPegawai) {
  // Add loading spinner
  var photoElement = document.getElementById('photo-' + idPegawai);
  var originalHTML = photoElement.outerHTML;
  
  // Show loading
  photoElement.style.opacity = '0.5';
  
  // Fetch updated photo info via AJAX
  fetch('<?php echo site_url('pegawai/get_photo_info/'); ?>' + idPegawai)
    .then(response => response.json())
    .then(data => {
      if (data.success && data.has_photo) {
        // Update photo with timestamp to force refresh
        var newTimestamp = new Date().getTime();
        var newPhotoUrl = data.photo_url + '?t=' + newTimestamp;
        
        photoElement.outerHTML = `
          <div class="photo-container">
            <img src="${newPhotoUrl}" 
                class="profile-photo" 
                alt="Foto Updated"
                id="photo-${idPegawai}"
                onclick="showPhotoModal('${data.photo_url}', 'Pegawai')"
                onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
            <div class="no-photo" style="display: none;">
              <i class="bi bi-person"></i>
            </div>
            <button class="photo-refresh" onclick="refreshSinglePhoto(${idPegawai})" title="Refresh foto">
              <i class="bi bi-arrow-clockwise"></i>
            </button>
          </div>
        `;
      } else {
        // No photo found
        photoElement.outerHTML = `
          <div class="photo-container">
            <div class="no-photo" id="photo-${idPegawai}">
              <i class="bi bi-person"></i>
            </div>
            <button class="photo-refresh" onclick="refreshSinglePhoto(${idPegawai})" title="Check foto baru">
              <i class="bi bi-arrow-clockwise"></i>
            </button>
          </div>
        `;
      }
    })
    .catch(error => {
      console.error('Error refreshing photo:', error);
      photoElement.style.opacity = '1';
    });
}

// Refresh all photos
function refreshAllPhotos() {
  var refreshBtn = document.getElementById('refreshBtn');
  var originalHTML = refreshBtn.innerHTML;
  
  refreshBtn.innerHTML = '<i class="bi bi-arrow-clockwise"></i> Refreshing...<span class="loading-spinner"></span>';
  refreshBtn.disabled = true;
  
  // Simple page reload with cache bust
  setTimeout(() => {
    window.location.href = window.location.href + (window.location.href.includes('?') ? '&' : '?') + '_t=' + new Date().getTime();
  }, 500);
}

// Auto refresh every 30 seconds if user is idle
var lastActivity = new Date().getTime();
var autoRefreshInterval;

document.addEventListener('mousemove', function() {
  lastActivity = new Date().getTime();
});

document.addEventListener('keypress', function() {
  lastActivity = new Date().getTime();
});

// Check for auto refresh every 30 seconds
setInterval(function() {
  var now = new Date().getTime();
  if (now - lastActivity > 30000) { // 30 seconds idle
    // Auto refresh photos silently
    document.querySelectorAll('.profile-photo').forEach(function(img) {
      var currentSrc = img.src;
      var newSrc = currentSrc.split('?')[0] + '?t=' + now;
      img.src = newSrc;
    });
  }
}, 30000);
</script>

</body>
</html>