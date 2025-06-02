<!-- views/verifikasi/index.php -->
<div class="container mt-4">
    <h1 class="mb-4">Verifikasi Dekompresi Wajah</h1>
    
    <div class="row">
        <div class="col-md-12">
            <div class="card">
                <div class="card-header bg-primary text-white">
                    <h3>Data Kompresi</h3>
                </div>
                <div class="card-body">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>ID Pegawai</th>
                                <th>Dimensi</th>
                                <th>Ukuran Kompresi</th>
                                <th>Waktu Dibuat</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($kompresi_data as $kompresi): ?>
                            <tr>
                                <td><?= $kompresi['id'] ?></td>
                                <td><?= $kompresi['id_pegawai'] ?></td>
                                <td><?= $kompresi['width'] ?>x<?= $kompresi['height'] ?></td>
                                <td><?= $kompresi['compressed_size'] ?> bytes</td>
                                <td><?= date('d-m-Y H:i:s', strtotime($kompresi['created_at'])) ?></td>
                                <td>
                                    <a href="<?= site_url('verifikasi/detail/'.$kompresi['id']) ?>" class="btn btn-primary btn-sm">Detail</a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                            <?php if (empty($kompresi_data)): ?>
                            <tr>
                                <td colspan="6" class="text-center">Tidak ada data kompresi</td>
                            </tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>