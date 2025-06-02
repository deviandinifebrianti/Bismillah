<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kelola Biometrik - SI Preti</title>
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

        .nav a:hover {
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

        /* Content */
        .content {
            padding: 2rem;
            max-width: 1200px;
            margin: 0 auto;
        }

        /* Pegawai Info */
        .pegawai-info {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .pegawai-info h3 {
            color: #6b46c1;
            margin-bottom: 1rem;
        }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
        }

        .info-item {
            padding: 1rem;
            background: #f9fafb;
            border-radius: 8px;
            border-left: 4px solid #22c55e;
        }

        .info-label {
            font-weight: bold;
            color: #374151;
            margin-bottom: 0.25rem;
        }

        .info-value {
            color: #6b7280;
        }

        /* Photos Grid */
        .photos-section {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .photos-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
        }

        .photos-header h3 {
            color: #6b46c1;
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

        .btn-success {
            background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
            color: white;
        }

        .btn-danger {
            background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
            color: white;
        }

        .btn-primary {
            background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
            color: white;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        .photos-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 1.5rem;
        }

        .photo-card {
            background: #f9fafb;
            border-radius: 12px;
            padding: 1.5rem;
            text-align: center;
            border: 2px solid #e5e7eb;
            transition: all 0.3s;
        }

        .photo-card:hover {
            border-color: #22c55e;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .biometric-image {
            width: 150px;
            height: 150px;
            border-radius: 12px;
            object-fit: cover;
            border: 3px solid #e5e7eb;
            margin-bottom: 1rem;
        }

        .no-image {
            width: 150px;
            height: 150px;
            background: #e5e7eb;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #6b7280;
            font-size: 0.9rem;
            text-align: center;
            margin: 0 auto 1rem;
        }

        .photo-info {
            margin-bottom: 1rem;
        }

        .photo-info h4 {
            color: #374151;
            font-size: 1.1rem;
            margin-bottom: 0.5rem;
        }

        .photo-info p {
            color: #6b7280;
            font-size: 0.9rem;
            margin-bottom: 0.25rem;
        }

        .photo-actions {
            display: flex;
            gap: 0.5rem;
            justify-content: center;
        }

        .btn-sm {
            padding: 0.5rem 1rem;
            font-size: 0.9rem;
        }

        /* Back Button */
        .back-btn {
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

        /* Responsive */
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                gap: 1rem;
            }

            .nav {
                flex-wrap: wrap;
                justify-content: center;
            }

            .content {
                padding: 1rem;
            }

            .photos-header {
                flex-direction: column;
                gap: 1rem;
            }

            .photos-grid {
                grid-template-columns: 1fr;
            }

            .photo-actions {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>

    <!-- Page Title -->
    <div class="page-title">
        Kelola Biometrik - <?= $biometrik->nama ?>
    </div>

    <!-- Content -->
    <div class="content">
        <!-- Back Button -->
        <div class="back-btn">
            <a href="<?= base_url('biometrik') ?>" class="btn btn-primary">← Kembali ke Daftar</a>
        </div>

        <!-- Pegawai Info -->
        <div class="pegawai-info">
            <h3>Informasi Pegawai</h3>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Nama</div>
                    <div class="info-value"><?= $biometrik->nama ?></div>
                </div>
                <div class="info-item">
    <div class="info-label">ID Pegawai</div>
    <div class="info-value"><?= $biometrik->id_pegawai ?></div>
</div>
<div class="info-item">
    <div class="info-label">Jabatan</div>
    <div class="info-value"><?= !empty($biometrik->nama_jabatan) ? $biometrik->nama_jabatan : 'Tidak ada data' ?></div>
</div>
<div class="info-item">
    <div class="info-label">Unit Kerja</div>
    <div class="info-value"><?= !empty($biometrik->nama_unit_kerja) ? $biometrik->nama_unit_kerja : 'Tidak ada data' ?></div>
</div>
                <div class="info-item">
                    <div class="info-label">Total Foto Biometrik</div>
                    <div class="info-value"><?= count($all_biometrik) ?> foto</div>
                </div>
            </div>
        </div>

        <!-- Photos Section -->
<div class="photos-section">
    <div class="photos-header">
        <h3>Foto Biometrik (<?= count($all_biometrik) ?>)</h3>
        <!-- Update tombol Tambah Foto Baru di halaman kelola_biometrik -->
        <a href="<?= base_url('biometrik/tambah_biometrik?id_pegawai=' . $biometrik->id_pegawai) ?>" class="btn btn-success">+ Tambah Foto Baru</a>
    </div>

    <?php if (!empty($all_biometrik)): ?>
        <div class="photos-grid">
            <?php foreach ($all_biometrik as $foto): ?>
                <div class="photo-card">
                    <?php if (!empty($foto->image)): ?>
                        <?php
                        // Cek apakah $foto->image sudah berisi full URL atau hanya nama file
                        if (!empty($foto->image)) {
                            // Jika sudah berisi full URL (http://...)
                            if (strpos($foto->image, 'http://') === 0 || strpos($foto->image, 'https://') === 0) {
                                $image_url = $foto->image;
                            } 
                            // Jika hanya nama file, buat URL Django
                            else if (!empty($foto->id_pegawai)) {
                                $django_media_url = 'http://localhost:8000/media';
                                $image_url = $django_media_url . '/biometrik/' . $foto->id_pegawai . '/' . $foto->image;
                            } 
                            // Fallback dengan face_id
                            else if (!empty($foto->face_id)) {
                                $django_media_url = 'http://localhost:8000/media';
                                $image_url = $django_media_url . '/biometrik/' . $foto->face_id . '/' . $foto->image;
                            } 
                            // Fallback ke CodeIgniter uploads
                            else {
                                $image_url = base_url('uploads/biometrik/' . $foto->image);
                            }
                        } else {
                            $image_url = base_url('assets/images/no-image.png');
                        }
                        ?>
                        <img src="<?= $image_url ?>" 
                             alt="Foto Biometrik" 
                             class="biometric-image"
                             onerror="this.onerror=null; this.src='<?= base_url('assets/images/no-image.png') ?>';">
                    <?php else: ?>
                        <div class="no-image">Tidak ada gambar</div>
                    <?php endif; ?>
                    
                    <div class="photo-info">
                        <h4><?= $foto->name ?></h4>
                        <p><strong>ID Pegawai:</strong> <?= $foto->id_pegawai ?></p>
                        <p><strong>Face ID:</strong> <?= $foto->face_id ?></p>
                        <p><strong>Dibuat:</strong> <?= date('d-m-Y H:i', strtotime($foto->created_at)) ?></p>
                        <?php if (!empty($foto->updated_at)): ?>
                            <p><strong>Diupdate:</strong> <?= date('d-m-Y H:i', strtotime($foto->updated_at)) ?></p>
                        <?php endif; ?>
                    </div>
                    
                    <div class="photo-actions">
                        <a href="<?= $image_url ?>" target="_blank" class="btn btn-primary btn-sm">Preview</a>
                        <form method="POST" action="<?= base_url('biometrik/delete') ?>" style="display: inline;">
    <input type="hidden" name="id" value="<?= $foto->id ?>">
    <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Yakin hapus?')">Hapus</button>
</form>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php else: ?>
        <div style="text-align: center; padding: 3rem; color: #6b7280;">
            <p style="font-size: 1.2rem; margin-bottom: 1rem;">Belum ada foto biometrik</p>
            <a href="<?= base_url('biometrik/biometrik_form?id_pegawai=' . $biometrik->id_pegawai) ?>" class="btn btn-success">Tambah Foto Pertama</a>
        </div>
    <?php endif; ?>
</div>
    </div>

    <script>
        alert('ID yang akan dihapus: ' + id);
        function confirmDelete(id) {
    if (confirm('Apakah Anda yakin ingin menghapus foto biometrik ini?')) {
        // ✅ URL yang benar untuk CodeIgniter 3
        window.location.href = '<?= base_url() ?>biometrik/delete/' + id;
    }
}
    </script>
</body>
</html>