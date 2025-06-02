<?php
if (!function_exists('get_biometrik_image_url')) {
    function get_biometrik_image_url($image, $face_id = null) {
        $CI =& get_instance();
        
        if (empty($image)) return '';
        
        // Cek beberapa kemungkinan lokasi file
        $possible_paths = [
            'media/biometrik/' . $face_id . '/' . $image,
            'uploads/biometrik/' . $image,
            'assets/images/biometrik/' . $image
        ];
        
        foreach ($possible_paths as $path) {
            if (file_exists(FCPATH . $path)) {
                return base_url($path);
            }
        }
        
        // Default fallback
        return base_url('media/biometrik/' . $face_id . '/' . $image);
    }
}