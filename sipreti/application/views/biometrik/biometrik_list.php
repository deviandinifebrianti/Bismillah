<?php
// File: application/views/biometrik/list.php
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Biometrik Pegawai - SI Preti</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
        }

        /* Header */
        .header {
            background: linear-gradient(135deg, #6b46c1 0%, #9333ea 100%);
            color: white;
            padding: 1rem 2rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .logo-icon {
            width: 40px;
            height: 40px;
            background: #22c55e;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            color: white;
        }

        .logo-text {
            font-size: 1.5rem;
            font-weight: bold;
        }

        .nav {
            display: flex;
            gap: 2rem;
        }

        .nav a {
            color: white;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            transition: background-color 0.3s;
        }

        .nav a:hover, .nav a.active {
            background-color: rgba(255, 255, 255, 0.1);
        }

        /* Page Title */
        .page-title {
            background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
            color: white;
            padding: 2rem;
            font-size: 2rem;
            font-weight: bold;
        }

        /* Flash Messages */
        .alert {
            padding: 1rem;
            margin: 1rem 2rem;
            border-radius: 8px;
            font-weight: bold;
            position: relative;
        }

        .alert-success {
            background-color: #d1fae5;
            color: #065f46;
            border: 1px solid #a7f3d0;
        }

        .alert-danger {
            background-color: #fee2e2;
            color: #991b1b;
            border: 1px solid #fca5a5;
        }

        .alert-close {
            position: absolute;
            right: 1rem;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            font-size: 1.2rem;
            cursor: pointer;
            color: inherit;
        }

        /* Content */
        .content {
            padding: 2rem;
            max-width: 1200px;
            margin: 0 auto;
        }

        /* Controls */
        .controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            gap: 1rem;
        }

        .search-container {
            display: flex;
            gap: 0;
        }

        .search-input {
            padding: 0.75rem 1rem;
            border: 2px solid #e5e7eb;
            border-radius: 8px 0 0 8px;
            font-size: 1rem;
            width: 300px;
            outline: none;
        }

        .search-input:focus {
            border-color: #9333ea;
        }

        .search-button {
            padding: 0.75rem 1.5rem;
            background: linear-gradient(135deg, #9333ea 0%, #7c3aed 100%);
            color: white;
            border: none;
            border-radius: 0 8px 8px 0;
            cursor: pointer;
            font-size: 1rem;
            font-weight: bold;
            transition: all 0.3s;
        }

        .search-button:hover {
            background: linear-gradient(135deg, #7c3aed 0%, #6b46c1 100%);
        }

        .action-buttons {
            display: flex;
            gap: 1rem;
        }

        .btn {
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 1rem;
            font-weight: bold;
            text-decoration: none;
            display: inline-block;
            text-align: center;
            transition: all 0.3s;
        }

        .btn-primary {
            background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
            color: white;
        }

        .btn-success {
            background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
            color: white;
        }

        .btn-green {
            background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
            color: white;
            padding: 0.5rem 1rem;
            font-size: 0.9rem;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        /* Table */
        .table-container {
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            background: linear-gradient(135deg, #6b46c1 0%, #9333ea 100%);
            color: white;
            padding: 1rem;
            text-align: left;
            font-weight: bold;
        }

        td {
            padding: 1rem;
            border-bottom: 1px solid #e5e7eb;
            vertical-align: middle;
        }

        tr:hover {
            background-color: #f9fafb;
        }

        tr:last-child td {
            border-bottom: none;
        }

        .biometric-image {
            width: 60px;
            height: 60px;
            border-radius: 8px;
            object-fit: cover;
            border: 2px solid #e5e7eb;
            cursor: pointer;
            transition: transform 0.3s;
        }

        .biometric-image:hover {
            transform: scale(1.1);
        }

        .no-image {
            width: 60px;
            height: 60px;
            background: #f3f4f6;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #6b7280;
            font-size: 0.8rem;
            text-align: center;
            border: 2px solid #e5e7eb;
        }

        /* Photo count badge */
        .photo-count {
            background: #dc2626;
            color: white;
            border-radius: 50%;
            width: 18px;
            height: 18px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 0.7rem;
            font-weight: bold;
            margin-left: 0.5rem;
            vertical-align: top;
        }

        /* Empty state */
        .empty-state {
            text-align: center;
            padding: 3rem;
            color: #6b7280;
        }

        .empty-state h3 {
            font-size: 1.5rem;
            margin-bottom: 1rem;
            color: #374151;
        }

        .empty-state p {
            font-size: 1.1rem;
            margin-bottom: 2rem;
        }

        /* Footer */
        .footer {
            background: #374151;
            color: white;
            text-align: center;
            padding: 1rem;
            margin-top: 2rem;
        }

        /* Loading state */
        .loading {
            text-align: center;
            padding: 2rem;
            color: #6b7280;
        }

        .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #9333ea;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Responsive */
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                gap: 1rem;
                padding: 1rem;
            }

            .nav {
                flex-wrap: wrap;
                justify-content: center;
                gap: 1rem;
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

            .controls {
                flex-direction: column;
                align-items: stretch;
            }

            .search-input {
                width: 100%;
                border-radius: 8px;
                margin-bottom: 1rem;
            }

            .search-button {
                width: 100%;
                border-radius: 8px;
                margin-bottom: 1rem;
            }

            .action-buttons {
                justify-content: center;
                flex-wrap: wrap;
            }

            .content {
                padding: 1rem;
            }

            table {
                font-size: 0.9rem;
            }

            th, td {
                padding: 0.75rem 0.5rem;
            }

            .biometric-image, .no-image {
                width: 40px;
                height: 40px;
            }

            .page-title {
                font-size: 1.5rem;
                padding: 1.5rem 1rem;
            }
        }

        @media (max-width: 480px) {
            .nav a {
                padding: 0.5rem;
                font-size: 0.9rem;
            }

            .btn {
                padding: 0.5rem 1rem;
                font-size: 0.9rem;
            }

            th, td {
                padding: 0.5rem 0.25rem;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="logo">
            <div class="logo-icon">SI</div>
            <div>
                <div class="logo-text">SI Preti</div>
                <div style="font-size: 0.8rem; opacity: 0.8;">Sistem Informasi Presensi Terkini</div>
            </div>
        </div>
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
    </header>

    <!-- Page Title -->
    <div class="page-title">
        Biometrik Pegawai
    </div>

    <!-- Flash Messages -->
    <?php if ($this->session->flashdata('success')): ?>
        <div class="alert alert-success" id="successAlert">
            <?= $this->session->flashdata('success') ?>
            <button type="button" class="alert-close" onclick="closeAlert('successAlert')">&times;</button>
        </div>
    <?php endif; ?>

    <?php if ($this->session->flashdata('error')): ?>
        <div class="alert alert-danger" id="errorAlert">
            <?= $this->session->flashdata('error') ?>
            <button type="button" class="alert-close" onclick="closeAlert('errorAlert')">&times;</button>
        </div>
    <?php endif; ?>

    <!-- Content -->
    <div class="content">
        <!-- Controls -->
        <div class="controls">
            <form method="GET" action="<?= base_url('biometrik') ?>" class="search-container">
                <input type="text" name="search" class="search-input" 
                       placeholder="Masukkan nama pegawai..." 
                       value="<?= isset($search) ? htmlspecialchars($search) : '' ?>">
                <button type="submit" class="search-button">
                    <span>🔍</span> Cari
                </button>
            </form>
            <div class="action-buttons">
                <a href="<?= base_url('biometrik/biometrik_form') ?>" class="btn btn-success">
                    + Tambah Biometrik
                </a>
                <a href="<?= base_url('biometrik/export_csv') ?>" class="btn btn-primary">
                    📊 Export CSV
                </a>
                <a href="<?= base_url('biometrik/import_csv') ?>" class="btn btn-success">
                    📁 Import CSV
                </a>
            </div>
        </div>

        <!-- Table -->
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th style="width: 5%;">No.</th>
                        <th style="width: 20%;">Nama</th>
                        <th style="width: 15%;">ID Pegawai</th>
                        <th style="width: 20%;">Nama Unit Kerja</th>
                        <th style="width: 15%;">Face ID</th>
                        <th style="width: 10%;">Dibuat</th>
                        <th style="width: 15%;">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php 
                    // Group data berdasarkan nama dan ID pegawai
                   $grouped_data = [];
if (!empty($biometrik)) {
    foreach ($biometrik as $row) {
        // Prioritaskan NIP, jika tidak ada gunakan id_pegawai
        $id_pegawai = !empty($row->nip) ? $row->nip : $row->id_pegawai;
        
        // Gunakan ID pegawai sebagai key utama untuk grouping
        if (!isset($grouped_data[$id_pegawai])) {
            $grouped_data[$id_pegawai] = [
                'data' => $row,
                'count' => 1,
                'ids' => [$row->id],
                'photos' => [$row] // Simpan semua foto untuk bisa ditampilkan nanti
            ];
        } else {
            // Jika sudah ada, tambah counter dan ID
            $grouped_data[$id_pegawai]['count']++;
            $grouped_data[$id_pegawai]['ids'][] = $row->id;
            $grouped_data[$id_pegawai]['photos'][] = $row;
            
            // Update data utama jika yang baru lebih lengkap
            if (empty($grouped_data[$id_pegawai]['data']->nama_pegawai) && !empty($row->nama_pegawai)) {
                $grouped_data[$id_pegawai]['data'] = $row;
            }
        }
    }
}
                    
                    if (!empty($grouped_data)):
                        $no = 1; 
                        foreach ($grouped_data as $group): 
                        $row = $group['data'];
                        $photo_count = $group['count'];
                    ?>
                    <tr>
                        <td><?= $no++ ?>.</td>
                        <td>
                            <strong><?= isset($row->nama_pegawai) ? htmlspecialchars($row->nama_pegawai) : htmlspecialchars($row->name) ?></strong>
                        </td>
                        <td><?= isset($row->nip) ? htmlspecialchars($row->nip) : htmlspecialchars($row->id_pegawai) ?></td>
                        <td>
    <?php if (isset($row->nama_unit_kerja) && !empty($row->nama_unit_kerja)): ?>
        <?= htmlspecialchars($row->nama_unit_kerja) ?>
    <?php else: ?>
        <span style="color: #6b7280; font-style: italic;">Unit kerja belum diset</span>
    <?php endif; ?>
</td>
                        <td>
                            <small><?= date('d-m-Y', strtotime($row->created_at)) ?></small><br>
                            <small style="color: #6b7280;"><?= date('H:i:s', strtotime($row->created_at)) ?></small>
                        </td>
                        <td>
                            <a href="<?= base_url('biometrik/kelola/' . $row->id) ?>" class="btn btn-green">
                                🔧 Kelola<?= $photo_count > 1 ? ' (' . $photo_count . ')' : '' ?>
                            </a>
                        </td>
                    </tr>
                    <?php 
                        endforeach; 
                    else: 
                    ?>
                    <tr>
                        <td colspan="8">
                            <div class="empty-state">
                                <?php if (isset($search) && $search): ?>
                                    <h3>🔍 Pencarian Tidak Ditemukan</h3>
                                    <p>Tidak ada data biometrik yang cocok dengan "<strong><?= htmlspecialchars($search) ?></strong>"</p>
                                    <a href="<?= base_url('biometrik') ?>" class="btn btn-primary">Lihat Semua Data</a>
                                <?php else: ?>
                                    <h3>📷 Belum Ada Data Biometrik</h3>
                                    <p>Mulai dengan menambahkan data biometrik pegawai pertama</p>
                                    <a href="<?= base_url('biometrik/biometrik_form') ?>" class="btn btn-success">+ Tambah Data Pertama</a>
                                <?php endif; ?>
                            </div>
                        </td>
                    </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>

        <!-- Statistics -->
        <?php if (!empty($grouped_data)): ?>
        <div style="margin-top: 2rem; text-align: center; color: #6b7280;">
            <p>Total: <strong><?= count($grouped_data) ?></strong> pegawai dengan <strong><?= count($biometrik) ?></strong> foto biometrik</p>
        </div>
        <?php endif; ?>
    </div>

    <!-- Image Modal -->
    <div id="imageModal" style="display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.8); cursor: pointer;" onclick="closeImageModal()">
        <div style="position: relative; margin: auto; top: 50%; transform: translateY(-50%); text-align: center;">
            <img id="modalImage" style="max-width: 90%; max-height: 90%; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.5);">
            <div id="modalCaption" style="color: white; font-size: 1.2rem; margin-top: 1rem; font-weight: bold;"></div>
            <button onclick="closeImageModal()" style="position: absolute; top: -40px; right: 0; background: white; border: none; border-radius: 50%; width: 30px; height: 30px; cursor: pointer; font-size: 1.2rem;">×</button>
        </div>
    </div>

    <!-- Footer -->
    <footer class="footer">
        ©2025 BKPSDM Kota Malang - Sistem Informasi Presensi Terkini
    </footer>

    <script>
        // Close alert function
        function closeAlert(alertId) {
            const alert = document.getElementById(alertId);
            if (alert) {
                alert.style.transition = 'opacity 0.5s';
                alert.style.opacity = '0';
                setTimeout(() => alert.remove(), 500);
            }
        }

        // Auto hide flash messages after 5 seconds
        setTimeout(function() {
            const alerts = document.querySelectorAll('.alert');
            alerts.forEach(alert => {
                if (alert.id === 'successAlert' || alert.id === 'errorAlert') {
                    closeAlert(alert.id);
                }
            });
        }, 5000);

        // Image modal functions
        function showImageModal(imageSrc, caption) {
            document.getElementById('modalImage').src = imageSrc;
            document.getElementById('modalCaption').textContent = caption;
            document.getElementById('imageModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
        }

        function closeImageModal() {
            document.getElementById('imageModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }

        // Search functionality
        document.querySelector('.search-input').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                this.closest('form').submit();
            }
        });

        // Button hover effects
        document.querySelectorAll('.btn').forEach(btn => {
            btn.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-2px)';
                this.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.15)';
            });
            
            btn.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0)';
                this.style.boxShadow = 'none';
            });
        });

        // Loading state for search
        document.querySelector('form').addEventListener('submit', function() {
            const button = this.querySelector('.search-button');
            const originalText = button.innerHTML;
            button.innerHTML = '<div class="spinner" style="width: 16px; height: 16px; border-width: 2px;"></div>';
            button.disabled = true;
            
            // Re-enable after 3 seconds (fallback)
            setTimeout(() => {
                button.innerHTML = originalText;
                button.disabled = false;
            }, 3000);
        });

        // Escape key to close modal
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeImageModal();
            }
        });

        console.log('Biometrik List loaded successfully');
    </script>
</body>
</html>