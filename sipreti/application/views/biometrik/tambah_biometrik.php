<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $title ?> - SI Preti</title>
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
            max-width: 800px;
            margin: 0 auto;
        }

        /* Back Button */
        .back-btn {
            margin-bottom: 2rem;
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

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        /* Form Card */
        .form-card {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .form-card h3 {
            color: #6b46c1;
            margin-bottom: 1.5rem;
            font-size: 1.5rem;
        }

        /* Form Styles */
        .form-group {
            margin-bottom: 1.5rem;
        }

        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: bold;
            color: #374151;
        }

        .form-control {
            width: 100%;
            padding: 0.75rem;
            border: 2px solid #e5e7eb;
            border-radius: 8px;
            font-size: 1rem;
            transition: border-color 0.3s;
        }

        .form-control:focus {
            outline: none;
            border-color: #22c55e;
            box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.1);
        }

        .form-control[readonly] {
            background-color: #f9fafb;
            color: #6b7280;
        }

        /* File Upload */
        .file-upload {
            border: 2px dashed #d1d5db;
            border-radius: 8px;
            padding: 2rem;
            text-align: center;
            transition: border-color 0.3s;
            cursor: pointer;
        }

        .file-upload:hover {
            border-color: #22c55e;
        }

        .file-upload.dragover {
            border-color: #22c55e;
            background-color: rgba(34, 197, 94, 0.05);
        }

        .file-upload-icon {
            font-size: 3rem;
            margin-bottom: 1rem;
        }

        .file-upload-text {
            color: #6b7280;
            margin-bottom: 1rem;
        }

        .file-upload input[type="file"] {
            display: none;
        }

        .file-upload-btn {
            background: #f3f4f6;
            color: #374151;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            cursor: pointer;
            transition: background-color 0.3s;
            display: inline-block;
        }

        .file-upload-btn:hover {
            background: #e5e7eb;
        }

        /* Preview Image */
        .image-preview {
            margin-top: 1rem;
            text-align: center;
        }

        .preview-image {
            max-width: 200px;
            max-height: 200px;
            border-radius: 8px;
            border: 2px solid #e5e7eb;
        }

        /* Alert Messages */
        .alert {
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
        }

        .alert-danger {
            background-color: #fef2f2;
            border: 1px solid #fecaca;
            color: #dc2626;
        }

        .alert-success {
            background-color: #f0fdf4;
            border: 1px solid #bbf7d0;
            color: #16a34a;
        }

        /* Info Box */
        .info-box {
            background: #f0f9ff;
            border: 1px solid #bae6fd;
            border-radius: 8px;
            padding: 1rem;
            margin: 1rem 0;
        }

        .info-box-title {
            color: #0369a1;
            font-weight: bold;
            margin-bottom: 0.5rem;
        }

        .info-box-content {
            color: #0c4a6e;
            font-size: 0.9rem;
        }

        .info-box ul {
            margin: 0.5rem 0;
            padding-left: 1.5rem;
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
        }
    </style>
</head>
<body>
    
    <!-- Page Title -->
    <div class="page-title">
        Tambah Foto Biometrik
    </div>

    <!-- Content -->
    <div class="content">
        <!-- Back Button -->
        <div class="back-btn">
            <?php if (isset($_GET['id_pegawai'])): ?>
                <?php 
                $temp_biometrik = $this->db->where('id_pegawai', $_GET['id_pegawai'])->get('sipreti_biometrik')->row();
                if ($temp_biometrik): ?>
                    <a href="<?= base_url('biometrik/kelola/' . $temp_biometrik->id) ?>" class="btn btn-primary">← Kembali</a>
                <?php else: ?>
                    <a href="<?= base_url('biometrik') ?>" class="btn btn-primary">← Kembali ke Daftar</a>
                <?php endif; ?>
            <?php else: ?>
                <a href="<?= base_url('biometrik') ?>" class="btn btn-primary">← Kembali ke Daftar</a>
            <?php endif; ?>
        </div>

        <!-- Error/Success Messages -->
        <?php if ($this->session->flashdata('error')): ?>
            <div class="alert alert-danger">
                <?= $this->session->flashdata('error') ?>
            </div>
        <?php endif; ?>

        <?php if ($this->session->flashdata('success')): ?>
            <div class="alert alert-success">
                <?= $this->session->flashdata('success') ?>
            </div>
        <?php endif; ?>

        <!-- Form Card -->
        <div class="form-card">
            <h3>Tambah Foto Biometrik</h3>
            
            <form method="POST" enctype="multipart/form-data" action="<?= base_url('biometrik/save_photo') ?>">
                
                <!-- Pilih Pegawai -->
                <div class="form-group">
                    <label for="id_pegawai">Pilih Pegawai <span style="color: red;">*</span></label>
                    <select name="id_pegawai" id="id_pegawai" class="form-control" required>
                        <option value="">-- Pilih Pegawai --</option>
                        <?php foreach ($pegawai as $p): ?>
                            <option value="<?= $p->id_pegawai ?>" 
                                    <?= (isset($_GET['id_pegawai']) && $_GET['id_pegawai'] == $p->id_pegawai) ? 'selected' : '' ?>>
                                <?= $p->nama ?> - <?= $p->nip ?>
                                <?php if (!empty($p->nama_jabatan)): ?>
                                    (<?= $p->nama_jabatan ?>)
                                <?php endif; ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <!-- Upload Foto -->
                <div class="form-group">
                    <label>Upload Foto Wajah <span style="color: red;">*</span></label>
                    <div class="file-upload" onclick="document.getElementById('image').click()">
                        <div class="file-upload-icon">📷</div>
                        <div class="file-upload-text">
                            <strong>Klik untuk memilih foto atau drag & drop file di sini</strong><br>
                            <small>Pastikan foto menampilkan wajah dengan jelas untuk hasil deteksi yang optimal</small>
                        </div>
                        <div class="file-upload-btn">Pilih Foto</div>
                        <input type="file" id="image" name="image" accept="image/*" onchange="previewImage(this)" required>
                        <div style="font-size: 0.8rem; color: #6b7280; margin-top: 0.5rem;">
                            Format: JPG, PNG, GIF. Maksimal 2MB<br>
                            <strong>Tips:</strong> Gunakan foto dengan wajah yang jelas, pencahayaan baik, dan tanpa terlalu banyak bayangan
                        </div>
                    </div>
                    
                    <!-- Preview Image -->
                    <div class="image-preview" id="imagePreview" style="display: none;">
                        <img id="preview" class="preview-image" alt="Preview">
                        <div style="margin-top: 0.5rem;">
                            <button type="button" onclick="removeImage()" style="background: #dc2626; color: white; border: none; padding: 0.25rem 0.5rem; border-radius: 4px; cursor: pointer;">Hapus</button>
                        </div>
                    </div>
                </div>

                <!-- Info Processing -->
                <div class="info-box">
                    <div class="info-box-title">ℹ️ Informasi Pemrosesan</div>
                    <div class="info-box-content">
                        Setelah foto diupload, sistem akan otomatis:
                        <ul>
                            <li>Mendeteksi wajah dalam foto</li>
                            <li>Generate Face ID unik</li>
                            <li>Mengekstrak face vector untuk pengenalan wajah</li>
                            <li>Menyimpan data biometrik untuk sistem presensi</li>
                        </ul>
                    </div>
                </div>

                <!-- Submit Button -->
                <div class="form-group" style="text-align: center;">
                    <button type="submit" class="btn btn-success" style="padding: 1rem 2rem; font-size: 1.1rem;" id="submitBtn">
                        <span id="submit-text">
                            📤 Upload & Proses Foto
                        </span>
                        <span id="loading-text" style="display: none;">
                            ⏳ Memproses foto...
                        </span>
                    </button>
                    <div style="margin-top: 0.5rem; font-size: 0.8rem; color: #6b7280;">
                        Proses mungkin memakan waktu beberapa detik
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Footer -->
    <footer class="footer">
        ©2025 BKPSDM Kota Malang
    </footer>

    <script>
        // Preview image function
        function previewImage(input) {
            if (input.files && input.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    document.getElementById('preview').src = e.target.result;
                    document.getElementById('imagePreview').style.display = 'block';
                };
                reader.readAsDataURL(input.files[0]);
            }
        }

        // Remove image function
        function removeImage() {
            document.getElementById('image').value = '';
            document.getElementById('imagePreview').style.display = 'none';
        }

        // Drag and drop functionality
        const fileUpload = document.querySelector('.file-upload');
        
        fileUpload.addEventListener('dragover', function(e) {
            e.preventDefault();
            this.classList.add('dragover');
        });

        fileUpload.addEventListener('dragleave', function(e) {
            e.preventDefault();
            this.classList.remove('dragover');
        });

        fileUpload.addEventListener('drop', function(e) {
            e.preventDefault();
            this.classList.remove('dragover');
            
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                document.getElementById('image').files = files;
                previewImage(document.getElementById('image'));
            }
        });

        // Processing indicator
        document.querySelector('form').addEventListener('submit', function() {
            document.getElementById('submit-text').style.display = 'none';
            document.getElementById('loading-text').style.display = 'inline';
            document.getElementById('submitBtn').disabled = true;
        });
    </script>
</body>
</html>