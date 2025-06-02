
<!-- Formulir -->
<form action="<?= $action ?>" method="post" enctype="multipart/form-data" class="form-container">
    <div class="form-group">
    <label for="id_pegawai">Pilih Pegawai</label>
    <select name="id_pegawai" required class="form-control">
        <option value="">--Pilih Pegawai--</option>
        <?php foreach ($pegawai_list as $p): ?>
            <option value="<?= $p->id_pegawai ?>" <?= set_select('id_pegawai', $p->id_pegawai, ($p->id_pegawai == $id_pegawai)) ?>>
                <?= $p->id_pegawai ?> - <?= $p->nama ?>
            </option>
        <?php endforeach; ?>
    </select>
    </div>

    <div class="form-group">
        <label for="image">Upload Foto Wajah</label>
        <input type="file" name="image" required class="form-control-file">
    </div>

    <button type="submit" class="btn btn-primary"><?= $button ?></button>
</form>

<!-- Styling -->
<style>
    /* Posisi tengah secara horizontal dan vertikal */
    body, html {
        height: 100%;
        margin: 0;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: #f1f1f1;
    }

    /* Form container */
    .form-container {
        width: 100%;
        max-width: 500px;
        padding: 30px;
        background-color: #fff;
        border-radius: 10px;
        box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1);
    }

    /* Input & Label */
    .form-group {
        margin-bottom: 20px;
    }

    .form-group label {
        font-size: 16px;
        font-weight: bold;
        display: block;
        margin-bottom: 6px;
    }

    .form-control, .form-control-file {
        width: 100%;
        padding: 10px;
        font-size: 14px;
        border: 1px solid #ccc;
        border-radius: 5px;
        box-sizing: border-box;
    }

    .form-control-file {
        padding: 10px;
    }

    /* Tombol submit */
    .btn {
        display: block;
        padding: 12px;
        background-color: #007bff;
        color: #fff;
        border: none;
        border-radius: 6px;
        font-size: 16px;
        cursor: pointer;
        width: 100%;
        transition: background-color 0.3s ease;
    }

    .btn:hover {
        background-color: #0056b3;
    }

    /* Responsif */
    @media (max-width: 600px) {
        .form-container {
            padding: 20px;
        }
    }
</style>
