<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lihat Biometrik</title>
</head>
<body>
    <h1>Gambar Biometrik</h1>
    <?php if (!empty($image)): ?>
        <?php $url_image = base_url('media/dataset/' . trim($image)); ?>
        <p>URL Gambar: <a href="<?php echo $url_image; ?>"><?php echo $url_image; ?></a></p>
        <img src="<?php echo $url_image; ?>" alt="Biometrik" style="width: 200px; height: auto;"/>
    <?php else: ?>
        <p>Tidak ada gambar untuk ditampilkan.</p>
    <?php endif; ?>
</body>
</html>