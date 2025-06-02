# sipreti/middleware.py
from django.utils import timezone
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class TimezoneMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        # Patch timezone.make_aware function
        self._patch_timezone_functions()
        
    def _patch_timezone_functions(self):
        # Simpan referensi ke fungsi asli
        original_make_aware = timezone.make_aware
        
        # Fungsi pengganti yang menangani string
        def safe_make_aware(value, *args, **kwargs):
            if value is None:
                return None
                
            if isinstance(value, str):
                try:
                    # Coba beberapa format tanggal umum
                    formats = [
                        '%Y-%m-%d %H:%M:%S',
                        '%Y-%m-%d %H:%M:%S.%f',
                        '%Y-%m-%d',
                        '%d/%m/%Y %H:%M:%S',
                        '%d/%m/%Y'
                    ]
                    
                    for fmt in formats:
                        try:
                            dt = datetime.strptime(value, fmt)
                            return original_make_aware(dt, *args, **kwargs)
                        except ValueError:
                            continue
                            
                    # Jika semua format gagal, gunakan waktu sekarang
                    logger.warning(f"Gagal konversi string ke datetime: '{value}'. Menggunakan waktu sekarang.")
                    return timezone.now()
                except Exception as e:
                    logger.error(f"Error saat konversi datetime: {e}")
                    return timezone.now()
            
            # Jika sudah berupa datetime atau tipe lain, gunakan fungsi asli
            return original_make_aware(value, *args, **kwargs)
        
        # Ganti fungsi original dengan fungsi yang aman
        timezone.make_aware = safe_make_aware
        
    def __call__(self, request):
        response = self.get_response(request)
        return response