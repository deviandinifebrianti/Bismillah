<tr><td>Id Pegawai</td><td><?php echo $id_pegawai; ?></td></tr>
<tr><td>Face Embeddings</td><td><small style="word-wrap: break-word; display: block;"><?php echo $face_embeddings; ?></small></td></tr>
<tr><td>Created At</td><td><?php echo $created_at; ?></td></tr>
<tr><td>Updated At</td><td><?php echo $updated_at; ?></td></tr>
<tr><td>Deleted At</td><td><?php echo $deleted_at ? $deleted_at : '-'; ?></td></tr>
<tr>
    <td>Foto</td>
    <td>
        <?php if (!empty($image)) : ?>
            <?php 
                $is_full_url = filter_var($image, FILTER_VALIDATE_URL);
                $image_src = $is_full_url ? $image : base_url('uploads/' . $image); 
            ?>
            <img src="<?= $image_src ?>" width="200">
            <?php if (!empty($face_id)): ?>
                <p>Face ID: <?= $face_id ?></p>
            <?php endif; ?>
        <?php else : ?>
            <em>Tidak ada gambar</em>
        <?php endif; ?>
    </td>
</tr>
