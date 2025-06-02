from django.db import models
from django.contrib import admin
import uuid
from django.core.files.images import ImageFile
from io import BytesIO
from sipreti.face_recognition.main import add_face
from django.conf import settings
from django.utils import timezone
from django.contrib.auth.models import User
import cv2
from django.core.files.base import ContentFile
from io import BytesIO
from django.db.models.signals import post_save
from django.dispatch import receiver

class RadiusAbsen(models.Model):
    id_radius = models.AutoField(primary_key=True)
    ukuran = models.FloatField()
    satuan = models.CharField(max_length=10)
    is_active = models.BooleanField(default=False)

    class Meta:
        managed = False
        db_table = 'radius_absen'


class Jabatan(models.Model):
    id_jabatan = models.AutoField(primary_key=True)
    nama_jabatan = models.CharField(max_length=100)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'jabatan'
        managed = False

class UnitKerja(models.Model):
    id_unit_kerja = models.AutoField(primary_key=True)
    nama_unit_kerja = models.CharField(max_length=100)
    alamat = models.CharField(max_length=100)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    radius = models.ForeignKey(
        RadiusAbsen,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='id_radius')
    
    class Meta:
        managed = True
        db_table = 'unit_kerja'

class Pegawai(models.Model):
    id_pegawai = models.AutoField(primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    nama = models.CharField(max_length=200)
    nip = models.CharField(max_length=20)
    email = models.CharField(max_length=255)
    no_hp = models.CharField(max_length=20, blank=True) 
    password = models.CharField(max_length=128) 
    image = models.CharField(max_length=255, blank=True, null=True)
    id_jabatan = models.ForeignKey(Jabatan, on_delete=models.SET_NULL, null=True, db_column='id_jabatan')
    id_unit_kerja = models.ForeignKey(UnitKerja, on_delete=models.SET_NULL, null=True, db_column='id_unit_kerja')
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    def __str__(self):
        return f"{self.id_pegawai} - {self.nama}"
    
    @property
    def image_full_url(self):
        if self.image:
            return f"{settings.BASE_URL}{self.image.url}"
        return None

    class Meta:
        db_table = 'pegawai'
        verbose_name_plural = "Pegawai"

def image_upload_path(instance, filename):
    """
    Menyimpan gambar dengan format:
    biometrik/[id_pegawai]/[timestamp]_[filename]
    """
    import time
    import os
    
    # Dapatkan timestamp saat ini
    timestamp = int(time.time())
    
    # Ambil id_pegawai
    id_pegawai = instance.id_pegawai.id_pegawai if instance.id_pegawai else "temp"
    
    # Buat path: biometrik/[id_pegawai]/[timestamp]_[filename]
    return f'biometrik/{id_pegawai}/{timestamp}_{filename}'

# Fungsi baru untuk menentukan path upload berdasarkan ID
def uncompress_upload_path(instance, filename):
    face_id = instance.face_id if instance.face_id else f"{instance.id_pegawai.id_pegawai}.temp"
    return f'uncompressed/{face_id}/{filename}'

class Biometrik(models.Model):
    id_pegawai = models.ForeignKey(Pegawai, on_delete=models.CASCADE, db_column='id_pegawai')
    name = models.CharField(max_length=200)
    image = models.ImageField(upload_to=image_upload_path, null=True, blank=True) 
    face_vector = models.TextField(null=True, blank=True)
    hasil_uncompress = models.ImageField(upload_to=uncompress_upload_path, null=True, blank=True)
    face_id = models.CharField(max_length=200,blank=True)
    kompresi_id = models.IntegerField(blank=True, null=True)
    huffman_codes_path = models.CharField(max_length=255, blank=True, null=True)
    face_features = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name
    

class TimingLogSimple(models.Model):
    id_timing = models.AutoField(primary_key=True)
    id_pegawai = models.CharField(max_length=100, db_index=True)
    
    # Mobile timing (ms)
    mobile_capture = models.IntegerField(null=True, blank=True)
    mobile_huffman = models.IntegerField(null=True, blank=True)
    mobile_sending = models.IntegerField(null=True, blank=True)
    mobile_total = models.IntegerField(null=True, blank=True)
    
    # Server timing (ms)
    server_add_face = models.IntegerField(null=True, blank=True)
    server_verify = models.IntegerField(null=True, blank=True)
    server_total = models.IntegerField(null=True, blank=True)
    
    # Result
    euclidean_distance = models.FloatField(null=True, blank=True)
    verification_success = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'timing_logs'
        ordering = ['-created_at']

    def __str__(self):
        return f"Timing #{self.id_timing} - {self.id_pegawai}"
    
    @property
    def grand_total_time(self):
        mobile = self.mobile_total or 0
        server = self.server_total or 0
        return mobile + server
    
    @property
    def success_rate_display(self):
        """Display success rate yang user-friendly"""
        return "✅ Berhasil" if self.verification_success else "❌ Gagal"


    # def save(self, *args, **kwargs):
    #     is_new = self.pk is None
    #     super().save(*args, **kwargs)

    #     updated_fields = {}

    #     # Set face_id setelah object memiliki id
    #     if is_new and not self.face_id:
    #         self.face_id = f"{self.id_pegawai.id_pegawai}.{self.id}"
    #         # Update face_id ke database
    #         Biometrik.objects.filter(id=self.id).update(face_id=self.face_id)
    #         updated_fields['face_id'] = self.face_id

    #     if updated_fields:
    #         # Gunakan update langsung
    #         try:
    #             from django.db import connection
    #             with connection.cursor() as cursor:
    #                 set_clause = ", ".join([f"{field} = %s" for field in updated_fields.keys()])
    #                 values = list(updated_fields.values())
    #                 values.append(self.id)
    #                 cursor.execute(
    #                     f"UPDATE {self._meta.db_table} SET {set_clause} WHERE id = %s",
    #                     values
    #                 )
    #         except Exception as e:
    #             import traceback
    #             print(f"Error saat update fields: {str(e)}")
    #             print(traceback.format_exc())
                
    #     # Proses face recognition jika ada gambar dan face_id
    #     if self.image and self.face_id:
    #         try:
    #             # Dapatkan path lokal gambar
    #             local_path = self.image.path
                
    #             # Pastikan direktori ada
    #             import os
    #             os.makedirs(os.path.dirname(local_path), exist_ok=True)
                
    #             from PIL import Image

    #             if not self.hasil_uncompress:
    #                 # Buka gambar dari path
    #                 img = Image.open(local_path)

    #                 # Simpan ulang dalam kualitas tinggi ke dalam memori (uncompress)
    #                 buffer = BytesIO()
    #                 img.save(buffer, format='JPEG', quality=100)
    #                 buffer.seek(0)

    #                 # Simpan ke field hasil_uncompress
    #                 filename = os.path.basename(local_path).replace(".jpg", "_uncompressed.jpg")

    #                 self.hasil_uncompress.save(filename, ContentFile(buffer.read()), save=True)
    #                 print(f"✅ Hasil uncompress disimpan ke: {self.hasil_uncompress.path}")
                    
    #             # Proses face recognition
    #             from sipreti.face_recognition.main import add_face
    #             success = add_face([local_path], self.face_id)
                
    #             if not success:
    #                 print("❌ Gagal menambahkan face vector dari gambar ini")
    #             else:
    #                 print("✅ Face vector berhasil ditambahkan dan disimpan")
    #         except Exception as e:
    #             import traceback
    #             print(f"Error saat memproses gambar: {str(e)}")
    #             print(traceback.format_exc())
    
    class Meta:
        verbose_name_plural = "Biometrik"


class LogAbsensi(models.Model):
    id_log_absensi = models.AutoField(primary_key=True)
    id_pegawai = models.ForeignKey(Pegawai, on_delete=models.CASCADE, db_column='id_pegawai')
    jenis_absensi = models.IntegerField(choices=[(0, 'Harian'), (1, 'Dinas')])
    check_mode = models.IntegerField(choices=[(0, 'Check-in'), (1, 'Check-out')])  # 0 = In, 1 = Out
    waktu_absensi = models.DateTimeField(default=timezone.now)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    nama_lokasi = models.CharField(max_length=255, blank=True, null=True)
    nama_kamera = models.CharField(max_length=255, blank=True, null=True)
    url_foto_presensi = models.CharField(max_length=255, blank=True, null=True)
    url_dokumen = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'log_absensi'
        managed = False 
    
class UserAndroid(models.Model):
    id_pegawai = models.ForeignKey(Pegawai, on_delete=models.CASCADE, db_column='id_pegawai')
    username = models.CharField(max_length=255)
    device_id = models.CharField(max_length=255)
    device_brand = models.CharField(max_length=100, null=True, blank=True)
    device_model = models.CharField(max_length=100, null=True, blank=True)
    device_os_version = models.CharField(max_length=50, null=True, blank=True)
    device_sdk_version = models.CharField(max_length=50, null=True, blank=True)
    last_login = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_android'


def huffman_upload_path(instance, filename):
    return f'huffman_images/{instance.id_pegawai}/{filename}'

import logging
logger = logging.getLogger(__name__)
class KompresiHuffman(models.Model):
    id_pegawai = models.CharField(max_length=100)
    width = models.IntegerField()
    height = models.IntegerField()
    frequency_model = models.JSONField()  # Disimpan sebagai JSON string
    code_table = models.JSONField()  # Disimpan sebagai JSON string
    compressed_file = models.BinaryField()
    compression_type = models.CharField(max_length=50, default='huffman')
    original_length = models.IntegerField(default=0)
    original_size = models.IntegerField(default=0)
    compressed_size = models.IntegerField(default=0)
    compression_ratio = models.FloatField(default=0.0)
    compression_time_ms = models.IntegerField(default=0)
    hasil_uncompress = models.ImageField(upload_to=huffman_upload_path, null=True, blank=True)
    face_vector = models.TextField(blank=True, null=True)
    huffman_tree = models.JSONField(null=True, blank=True)  # Struktur tree lengkap
    tree_depth = models.IntegerField(null=True, blank=True) # Kedalaman tree
    unique_characters = models.IntegerField(null=True, blank=True)

    created_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'kompresihuffman'
        
    def __str__(self):
        return f"Kompresi-{self.id}-{self.id_pegawai}"

# from django.db.models.signals import post_save
# from django.dispatch import receiver
# @receiver(post_save, sender=KompresiHuffman)
# def auto_uncompress(sender, instance, created, **kwargs):
#     # Hanya jalankan uncompress jika ini adalah kompresi baru
#     if created and not instance.hasil_uncompress:
#         try:
#             from .admin import KompresiHuffmanAdmin
#             admin_instance = KompresiHuffmanAdmin(KompresiHuffman, None)
#             admin_instance.uncompress_object(None, instance.id)
            
#             logger.info(f"Otomatis melakukan uncompress untuk ID: {instance.id}")
#         except Exception as e:
#             logger.error(f"Gagal melakukan uncompress otomatis untuk ID {instance.id}: {str(e)}")
#             import traceback
#             logger.error(traceback.format_exc())
            

class LogVerifikasi(models.Model):
    kompresi = models.ForeignKey(KompresiHuffman, on_delete=models.CASCADE)
    status_verifikasi = models.BooleanField(default=False)
    nilai_kecocokan = models.FloatField(null=True, blank=True)
    waktu_dekompresi_ms = models.IntegerField()
    waktu_verifikasi_ms = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'logverifikasi'
    
    def __str__(self):
        return f"Verifikasi-{self.kompresi.id}: {'Berhasil' if self.status_verifikasi else 'Gagal'}"
    

# KKOMPRESI ARITHMETIC
class KompresiArithmetic(models.Model):
    """Model untuk menyimpan data kompresi arithmetic."""
    id_pegawai = models.CharField(max_length=50)
    width = models.IntegerField()
    height = models.IntegerField()
    frequency_model = models.JSONField(null=True, blank=True) # JSON representation of frequency table
    code_table = models.JSONField(null=True, blank=True)  # Optional, for compatibility
    compressed_file = models.BinaryField()  # Compressed data
    compression_type = models.CharField(max_length=20, default='arithmetic')
    original_length = models.IntegerField()  # Length of original pixel array
    
    # Metrik kompresi
    original_size = models.IntegerField(default=0)
    compressed_size = models.IntegerField(default=0)
    compression_ratio = models.FloatField(default=0.0)
    compression_time_ms = models.IntegerField(default=0)
    
    # Metadata
    created_at = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return f"Arithmetic Compression ID: {self.id} - Pegawai: {self.id_pegawai}"
    
    class Meta:
        verbose_name = "Kompresi Arithmetic"
        verbose_name_plural = "Kompresi Arithmetic"


class LogVerifikasiArithmetic(models.Model):
    """Model untuk menyimpan log hasil verifikasi wajah dari data kompresi arithmetic."""
    kompresi = models.ForeignKey(KompresiArithmetic, on_delete=models.CASCADE)
    status_verifikasi = models.BooleanField()
    nilai_kecocokan = models.FloatField(null=True, blank=True)
    waktu_dekompresi_ms = models.IntegerField()
    waktu_verifikasi_ms = models.IntegerField()
    created_at = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        status = "Cocok" if self.status_verifikasi else "Tidak Cocok"
        return f"Verifikasi Arithmetic {status} - {self.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    
    class Meta:
        verbose_name = "Log Verifikasi Arithmetic"
        verbose_name_plural = "Log Verifikasi Arithmetic"


class KompresiRle(models.Model):
    # Informasi dasar
    id_pegawai = models.CharField(max_length=100)
    compression_type = models.CharField(max_length=20)  
    
    # Dimensi gambar
    width = models.IntegerField()
    height = models.IntegerField()
    
    # Informasi kompresi
    original_length = models.IntegerField()
    compressed_size = models.IntegerField()
    original_size = models.IntegerField()
    compression_ratio = models.FloatField()
    compression_time_ms = models.IntegerField()
    compression_type = models.CharField(max_length=20, default='rle')
    
    # Data kompresi (disimpan sebagai file)
    compressed_file = models.FileField(upload_to='compressed_files/')
    
    # Field khusus untuk algoritma tertentu (jadikan nullable)
    frequency_model = models.JSONField(null=True, blank=True)
    code_table = models.JSONField(null=True, blank=True)
    
    # Untuk gambar RGB vs grayscale
    is_rgb = models.BooleanField(default=False)
    
    def __str__(self):
        return f"Kompresi {self.compression_type} - {self.id_pegawai} - {self.timestamp}"

