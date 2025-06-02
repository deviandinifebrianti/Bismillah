<h2>Daftar Vektor Pegawai</h2>

<a href="<?= site_url('vektor_pegawai/create') ?>" class="btn btn-success">+ Tambah Pegawai</a> <!-- Tombol Tambah Pegawai -->
<br><br>
<?= $this->session->flashdata('message') ?>

<table border="1" cellpadding="8">
    <thead>
        <tr>
            <th>ID Pegawai</th>
            <th>Nama</th>
            <th>Foto</th>
            <th>Dibuat Pada</th>
            <th>Aksi</th>
        </tr>
    </thead>
    <tbody>
        <?php foreach ($vektor_pegawai as $vp): ?>
        <tr>
            <td><?= htmlspecialchars($vp['id_pegawai']) ?></td>
            <td><?= htmlspecialchars($vp['nama']) ?></td>
            <td>
                <?php if (!empty($vp['foto_list'])): ?>
                    <?php foreach ($vp['foto_list'] as $foto): ?>
                        <a href="#" onclick="openModal('<?= base_url('uploads/' . $foto) ?>')">
                            <img src="<?= base_url('uploads/' . $foto) ?>" width="80" style="margin: 2px; cursor: pointer;">
                        </a>
                    <?php endforeach; ?>
                <?php else: ?>
                    Tidak ada gambar
                <?php endif; ?>
            </td>
            <td><?= date('d M Y H:i', strtotime($vp['created_at'])) ?></td>
            <td>
                <a href="<?= site_url('vektor_pegawai/read/' . $vp['id_vektor_pegawai']) ?>" class="btn btn-info">Detail</a> |
                <a href="<?= site_url('vektor_pegawai/update/' . $vp['id_vektor_pegawai']) ?>" class="btn btn-warning">Edit</a> | 
                <a href="<?= site_url('vektor_pegawai/delete/' . $vp['id_vektor_pegawai']) ?>" onclick="return confirm('Yakin?')">Hapus</a>
            </td>
        </tr>
        <?php endforeach; ?>
    </tbody>
</table>

<!-- Modal -->
<div id="myModal" style="display:none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background-color: rgba(0, 0, 0, 0.7); z-index: 9999;">
    <span style="position: absolute; top: 20px; right: 20px; color: #fff; font-size: 30px; cursor: pointer;" onclick="closeModal()">×</span>
    <img id="modalImage" src="" style="display: block; margin: 100px auto; max-width: 90%; max-height: 90%;"/>
    <button id="deleteBtn" class="btn btn-danger" style="display: block; margin: 20px auto 0 auto;">Hapus Foto Ini</button>
</div>

<script>
    let currentImageUrl = ''; // Tambahkan ini di atas

    function openModal(imageUrl) {
        currentImageUrl = imageUrl; // simpan url-nya ke global variable
        document.getElementById('modalImage').src = imageUrl;
        document.getElementById('myModal').style.display = 'block';
    }

    function closeModal() {
        document.getElementById('myModal').style.display = 'none';
    }

    document.getElementById('deleteBtn').addEventListener('click', function () {
        if (confirm('Yakin ingin menghapus foto ini?')) {
            const segments = currentImageUrl.split('/');
            const filename = segments[segments.length - 1];
            window.location.href = "<?= site_url('vektor_pegawai/hapus_foto/') ?>" + filename;
        }
    });
</script>


<style>
    /* Gaya umum untuk tombol */
    .btn {
        display: inline-block;
        padding: 8px 15px;
        text-decoration: none;
        border-radius: 5px;
        color: #fff;
        font-size: 14px;
        text-align: center;
        margin-right: 5px;
        cursor: pointer;
    }

    /* Gaya tombol untuk masing-masing aksi */
    .btn-info {
        background-color: #17a2b8; /* Biru */
        border: 1px solid #17a2b8;
    }

    .btn-warning {
        background-color: #ffc107; /* Kuning */
        border: 1px solid #ffc107;
    }

    .btn-danger {
        background-color: #dc3545; /* Merah */
        border: 1px solid #dc3545;
    }

    .btn-primary {
        background-color: #007bff; /* Biru Tua */
        border: 1px solid #007bff;
    }

    .btn-success {
        background-color: #28a745; /* Hijau untuk tombol Tambah Pegawai */
        border: 1px solid #28a745;
    }

    /* Hover effect untuk tombol */
    .btn:hover {
        opacity: 0.8;
    }

    /* Modal styling */
    #myModal {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background-color: rgba(0, 0, 0, 0.7);
        z-index: 9999;
    }

    #modalImage {
        display: block;
        margin: 100px auto;
        max-width: 90%;
        max-height: 90%;
    }
</style>
