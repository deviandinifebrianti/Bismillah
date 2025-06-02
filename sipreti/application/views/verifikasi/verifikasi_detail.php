<!-- views/verifikasi/detail.php -->
<div class="container mt-4">
    <div class="row">
        <div class="col-md-12">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<?= site_url('verifikasi') ?>">Data Kompresi</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Detail #<?= $kompresi['id'] ?></li>
                </ol>
            </nav>
        </div>
    </div>

    <div class="card mb-4">
        <div class="card-header bg-primary text-white">
            <h2>Detail Kompresi #<?= $kompresi['id'] ?></h2>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h3>Informasi Kompresi</h3>
                    <table class="table">
                        <tr>
                            <th>ID Pegawai</th>
                            <td><?= $kompresi['id_pegawai'] ?></td>
                        </tr>
                        <tr>
                            <th>Dimensi</th>
                            <td><?= $kompresi['width'] ?>x<?= $kompresi['height'] ?></td>
                        </tr>
                        <tr>
                            <th>Tipe Kompresi</th>
                            <td><?= $kompresi['compression_type'] ?></td>
                        </tr>
                        <tr>
                            <th>Ukuran Asli</th>
                            <td><?= $kompresi['original_size'] ?> bytes</td>
                        </tr>
                        <tr>
                            <th>Ukuran Kompresi</th>
                            <td><?= $kompresi['compressed_size'] ?> bytes</td>
                        </tr>
                        <tr>
                            <th>Rasio Kompresi</th>
                            <td><?= number_format($kompresi['compression_ratio'], 2) ?>x</td>
                        </tr>
                        <tr>
                            <th>Waktu Kompresi</th>
                            <td><?= $kompresi['compression_time_ms'] ?> ms</td>
                        </tr>
                        <tr>
                            <th>Waktu Dibuat</th>
                            <td><?= date('d-m-Y H:i:s', strtotime($kompresi['created_at'])) ?></td>
                        </tr>
                    </table>
                </div>
                
                <div class="col-md-6">
                    <h3>Hasil Dekompresi</h3>
                    <div class="text-center">
                        <img src="<?= site_url('verifikasi/tampilkan_hasil/'.$kompresi['id']) ?>" alt="Hasil Dekompresi" class="img-fluid border" style="max-height: 300px;">
                    </div>
                    
                    <div class="mt-4">
                        <button id="btnVerifikasi" class="btn btn-primary btn-lg" data-id="<?= $kompresi['id'] ?>">
                            Verifikasi Wajah
                        </button>
                    </div>
                </div>
            </div>
            
            <div class="row mt-4">
                <div class="col-md-12">
                    <div id="hasilVerifikasi" class="alert alert-info d-none">
                        <h4 class="alert-heading">Hasil Verifikasi</h4>
                        <div id="verifikasiContent"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    $('#btnVerifikasi').on('click', function() {
        var kompresiId = $(this).data('id');
        var btn = $(this);
        
        // Ubah tampilan tombol
        btn.prop('disabled', true);
        btn.html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Memproses...');
        
        // Tampilkan div hasil verifikasi
        $('#hasilVerifikasi').removeClass('d-none');
        $('#hasilVerifikasi').attr('class', 'alert alert-info');
        $('#verifikasiContent').html('<p>Sedang memproses dekompresi dan verifikasi wajah. Mohon tunggu...</p>');
        
        // Kirim request AJAX
        $.ajax({
            url: '<?= site_url('verifikasi/proses_verifikasi/') ?>' + kompresiId,
            type: 'POST',
            dataType: 'json',
            success: function(data) {
                // Reset tombol
                btn.prop('disabled', false);
                btn.html('Verifikasi Wajah');
                
                // Tampilkan hasil
                if (data.status === 1) {
                    $('#hasilVerifikasi').attr('class', 'alert alert-success');
                    var html = '<p><strong>Status:</strong> ' + data.message + '</p>' +
                               '<p><strong>ID Pegawai:</strong> ' + data.id_pegawai + '</p>' +
                               '<p><strong>Waktu Dekompresi:</strong> ' + data.dekompresi_time_ms + ' ms</p>' +
                               '<p><strong>Waktu Verifikasi:</strong> ' + data.verifikasi_time_ms + ' ms</p>' +
                               '<p><strong>Total Waktu:</strong> ' + data.total_time_ms + ' ms</p>';
                    
                    $('#verifikasiContent').html(html);
                } else {
                    $('#hasilVerifikasi').attr('class', 'alert alert-danger');
                    var html = '<p><strong>Status:</strong> ' + data.message + '</p>' +
                               '<p><strong>ID Pegawai:</strong> ' + data.id_pegawai + '</p>' +
                               '<p><strong>Waktu Dekompresi:</strong> ' + data.dekompresi_time_ms + ' ms</p>' +
                               '<p><strong>Waktu Verifikasi:</strong> ' + data.verifikasi_time_ms + ' ms</p>' +
                               '<p><strong>Total Waktu:</strong> ' + data.total_time_ms + ' ms</p>';
                    
                    $('#verifikasiContent').html(html);
                }
            },
            error: function(xhr, status, error) {
                // Reset tombol
                btn.prop('disabled', false);
                btn.html('Verifikasi Wajah');
                
                // Tampilkan error
                $('#hasilVerifikasi').attr('class', 'alert alert-danger');
                $('#verifikasiContent').html('<p><strong>Error:</strong> ' + error + '</p>');
            }
        });
    });
});
</script>