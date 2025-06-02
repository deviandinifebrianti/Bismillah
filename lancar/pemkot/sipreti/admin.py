from django.contrib import admin

# Register your models here.
from .models import Biometrik

admin.site.register(Biometrik)



# from django.contrib import admin
# from django import forms
# from .models import Biometrik, Pegawai, KompresiHuffman, LogVerifikasi, KompresiArithmetic, LogVerifikasiArithmetic
# import json
# import random
# import time
# from sipreti.face_recognition.main import add_face
# from django.core.files.storage import default_storage
# from django.conf import settings
# import os
# from django.shortcuts import render, redirect
# from django.core.files.base import ContentFile
# from django.utils.html import format_html, mark_safe
# from django.db import transaction
# from django.utils.safestring import mark_safe
# from django.shortcuts import redirect, get_object_or_404
# from django.http import HttpResponse
# import logging
# from django.contrib import messages
# import sys
# from django.urls import path
# import numpy as np
# from PIL import Image
# from django.utils import timezone
# import datetime
# from .utils import process_image, convert_to_grayscale, huffman_compress
# from .views import build_huffman_tree, decode_huffman
# from io import BytesIO
# from django.core.files.base import ContentFile
# from django.db.models.signals import post_save
# from django.dispatch import receiver
# from django.conf import settings

# original_now = timezone.now
# def patched_now():
#     try:
#         return original_now()
#     except AttributeError:
#         return datetime.datetime.now(tz=datetime.timezone.utc)
# timezone.now = patched_now

# admin_site = admin.AdminSite(name='myadmin')

# # Fungsi untuk menyimpan gambar dengan struktur folder yang sesuai
# def image_upload_path(instance, filename):
#     # Simpan dalam folder /biometrik/[id_pegawai]/[filename]
#     return f'biometrik/{instance.id_pegawai.id_pegawai}/{filename}'

# # Admin untuk BiometrikPegawaiGroup
# class BiometrikPegawaiAdmin(admin.ModelAdmin):
#     """Admin khusus untuk menampilkan biometrik dikelompokkan berdasarkan pegawai"""
    
#     list_display = ['username', 'jumlah_biometrik', 'preview_biometrik']
#     search_fields = ['id_pegawai__nama']
    
#     # Fungsi untuk list_display
#     def username(self, obj):
#         return obj.id_pegawai.nama
#     username.short_description = 'Nama Pegawai'
    
#     def jumlah_biometrik(self, obj):
#         return Biometrik.objects.filter(id_pegawai=obj.id_pegawai).count()
#     jumlah_biometrik.short_description = 'Jumlah Foto'
    
#     def preview_biometrik(self, obj):
#         biometriks = Biometrik.objects.filter(id_pegawai=obj.id_pegawai)[:5]
#         html = '<div style="display: flex; flex-wrap: wrap; gap: 5px;">'
#         for bm in biometriks:
#             if bm.image:
#                 html += f"""
#                 <a href="/admin/sipreti/biometrik/{bm.id}/change/">
#                     <img src="{bm.image.url}" 
#                          style="width: 60px; height: 60px; object-fit: cover; border-radius: 4px;"
#                          title="{bm.name}" />
#                 </a>
#                 """
#         html += '</div>'
#         return mark_safe(html)
#     preview_biometrik.short_description = 'Preview'
    
#     def change_view(self, request, object_id, form_url='', extra_context=None):
#         # Dapatkan objek biometrik
#         obj = self.get_object(request, object_id)
        
#         if obj is None:
#             return self.changelist_view(request)
        
#         # Dapatkan pegawai
#         pegawai = obj.id_pegawai
        
#         # Ambil semua biometrik untuk pegawai ini
#         biometriks = Biometrik.objects.filter(id_pegawai=pegawai)
        
#         # Siapkan context
#         context = {
#             'title': f'Detail Biometrik Pegawai: {pegawai.nama}',
#             'pegawai': pegawai,
#             'biometriks': biometriks,
#         }
        
#         if extra_context:
#             context.update(extra_context)
        
#         # Render template kustom
#         return render(request, 'admin/biometrik_pegawai_detail.html', context)

#     # Gunakan tampilan mirip changelist tapi dengan logika yang berbeda
#     change_list_template = 'admin/change_list.html'

#     # Tambahkan permission
#     def has_add_permission(self, request):
#         return True
        
#     def has_change_permission(self, request, obj=None):
#         return True
    
#     def has_delete_permission(self, request, obj=None):
#         return True
        
#     def has_view_permission(self, request, obj=None):
#         return True
    
#     def get_urls(self):
#         urls = [
#             path('', self.admin_site.admin_view(self.pegawai_list_view), name='biometrikpegawaigroup_changelist'),
#             path('<path:pegawai_id>/process/', self.admin_site.admin_view(self.process_all_view), name='biometrikpegawaigroup_process'),
#         ]
#         return urls + super().get_urls()
    
#     def pegawai_list_view(self, request):
#         """Tampilan daftar pegawai dengan biometrik"""
#         # Ambil pegawai yang memiliki biometrik
#         pegawai_dengan_biometrik = Pegawai.objects.filter(
#             id_pegawai__in=Biometrik.objects.values_list('id_pegawai', flat=True).distinct()
#         )
        
#         # Dapatkan jumlah biometrik untuk setiap pegawai
#         pegawai_dengan_jumlah = []
#         for pegawai in pegawai_dengan_biometrik:
#             biometriks = Biometrik.objects.filter(id_pegawai=pegawai)
            
#             # Buat HTML untuk gambar
#             thumbnail_html = '<div style="display: flex; flex-wrap: wrap; gap: 5px;">'
#             for bm in biometriks[:5]:  # Tampilkan maksimal 5 gambar
#                 if bm.image:
#                     thumbnail_html += f"""
#                     <a href="/admin/sipreti/biometrik/{bm.id}/change/">
#                         <img src="{bm.image.url}" 
#                              style="width: 60px; height: 60px; object-fit: cover; border-radius: 4px;"
#                              title="{bm.name}" />
#                     </a>
#                     """
            
#             # Tambahkan teks jika ada lebih banyak gambar
#             if biometriks.count() > 5:
#                 thumbnail_html += f'<div style="display: flex; align-items: center; margin-left: 5px;">+{biometriks.count() - 5} lainnya</div>'
            
#             thumbnail_html += '</div>'
            
#             # Buat HTML untuk tombol proses
#             process_button = f"""
#             <a href="/admin/sipreti/biometrikpegawaigroup/{pegawai.id_pegawai}/process/" 
#                class="button" 
#                style="display: inline-block; background-color: #417690; color: white; 
#                       padding: 5px 10px; border-radius: 4px; text-decoration: none;">
#                 Proses Semua Wajah
#             </a>
#             """
            
#             # Tambahkan tombol untuk melihat daftar biometrik
#             view_button = f"""
#             <a href="/admin/sipreti/biometrik/?id_pegawai__id_pegawai={pegawai.id_pegawai}" 
#                class="button" 
#                style="display: inline-block; background-color: #79aec8; color: white; 
#                       padding: 5px 10px; border-radius: 4px; text-decoration: none; margin-left: 5px;">
#                 Lihat Detail
#             </a>
#             """
            
#             pegawai_dengan_jumlah.append({
#                 'pegawai': pegawai,
#                 'jumlah': biometriks.count(),
#                 'thumbnails': mark_safe(thumbnail_html),
#                 'action_buttons': mark_safe(process_button + view_button)
#             })
        
#         # Siapkan data untuk template
#         context = {
#             'title': 'Biometrik (Dikelompokkan berdasarkan Pegawai)',
#             'cl': {
#                 'result_count': len(pegawai_dengan_jumlah),
#                 'full_result_count': len(pegawai_dengan_jumlah),
#                 'result_list': pegawai_dengan_jumlah,
#             },
#             'opts': self.model._meta,
#             'headers': ['ID', 'Nama Pegawai', 'Jumlah Foto', 'Preview', 'Tindakan'],
#             **self.admin_site.each_context(request)
#         }
        
#         # Tangani filter dan pencarian jika ada
#         query = request.GET.get('q')
#         if query:
#             pegawai_dengan_jumlah = [p for p in pegawai_dengan_jumlah 
#                                      if query.lower() in p['pegawai'].nama.lower() or
#                                         query in str(p['pegawai'].id_pegawai)]
#             context['cl']['result_count'] = len(pegawai_dengan_jumlah)
#             context['cl']['result_list'] = pegawai_dengan_jumlah
        
#         # Render halaman dengan template admin bawaan
#         return render(request, 'admin/biometrik_pegawai_list.html', context)
    
#     def process_all_view(self, request, pegawai_id):
#         """Proses semua foto untuk satu pegawai"""
#         try:
#             # Dapatkan pegawai
#             pegawai = get_object_or_404(Pegawai, id_pegawai=pegawai_id)
            
#             # Ambil semua biometrik untuk pegawai
#             biometriks = Biometrik.objects.filter(id_pegawai=pegawai)
            
#             if not biometriks.exists():
#                 self.message_user(
#                     request, 
#                     f"Tidak ada data biometrik untuk pegawai {pegawai.nama}",
#                     level=messages.WARNING
#                 )
#                 return redirect('/admin/sipreti/biometrikpegawaigroup/')
            
#             # Dapatkan URL semua gambar
#             url_image_array = [request.build_absolute_uri(bm.image.url) for bm in biometriks if bm.image]
            
#             # Proses semua wajah
#             success = add_face(url_image_array, str(pegawai_id))
            
#             # Tampilkan pesan hasil
#             if success:
#                 self.message_user(
#                     request, 
#                     f"Berhasil memproses {len(url_image_array)} foto wajah untuk pegawai {pegawai.nama}",
#                     level=messages.SUCCESS
#                 )
#             else:
#                 self.message_user(
#                     request, 
#                     f"Gagal memproses foto wajah untuk pegawai {pegawai.nama}. Pastikan wajah terlihat jelas.",
#                     level=messages.ERROR
#                 )
                
#             return redirect('/admin/sipreti/biometrikpegawaigroup/')
            
#         except Exception as e:
#             self.message_user(
#                 request, 
#                 f"Terjadi kesalahan: {str(e)}",
#                 level=messages.ERROR
#             )
#             return redirect('/admin/sipreti/biometrikpegawaigroup/')

# class BiometrikPegawaiGroup(Biometrik):
#     """Kelas 'dummy' untuk keperluan admin"""
#     class Meta:
#         proxy = True
#         app_label = 'sipreti'
#         verbose_name = 'Biometrik (Dikelompokkan)'
#         verbose_name_plural = 'Biometrik (Dikelompokkan)'
# admin.site.register(BiometrikPegawaiGroup, BiometrikPegawaiAdmin)


# class BiometrikInline(admin.TabularInline):
#     model = Biometrik
#     extra = 0
#     fields = ['name', 'image', 'face_id']
#     readonly_fields = ['face_id']

# # Fungsi untuk menyimpan gambar dengan struktur folder yang sesuai
# def image_upload_path(instance, filename):
#     # Simpan dalam folder /biometrik/[id_pegawai]/[filename]
#     return f'biometrik/{instance.id_pegawai.id_pegawai}/{filename}'

# class BiometrikAdminForm(forms.ModelForm):
#     # Field untuk memilih pegawai dari tabel pegawai
#     id_pegawai = forms.ModelChoiceField(
#         queryset=Pegawai.objects.all(),
#         label="Id pegawai",
#         required=True
#     )
    
#     class Meta:
#         model = Biometrik
#         fields = ['id_pegawai', 'name', 'image', 'face_id']
#         widgets = {
#             'face_id': forms.TextInput(attrs={'readonly': 'readonly'}),
#         }
    
#     def __init__(self, *args, **kwargs):
#         super().__init__(*args, **kwargs)
#         # Jika ini form edit dan objek sudah memiliki id_pegawai
#         if 'instance' in kwargs and kwargs['instance'] and kwargs['instance'].id_pegawai:
#             # Set nilai awal field id_pegawai
#             self.fields['id_pegawai'].initial = kwargs['instance'].id_pegawai


# @admin.register(Biometrik)
# class BiometrikAdmin(admin.ModelAdmin):
#     form = BiometrikAdminForm
#     list_display = ['id_biometrik', 'pegawai_dengan_jumlah_gambar', 'name', 'image_preview', 'face_id', 'proses_action']
#     list_filter = ['id_pegawai']
#     search_fields = ['id_pegawai__nama', 'name', 'face_id']
#     readonly_fields = ['face_id', 'detail_image', 'proses_wajah_action', 'gambar_pegawai_lainnya']
    
#     # Tambahkan ini untuk menampilkan lebih banyak item di halaman daftar
#     list_per_page = 20
    
#     fieldsets = (
#         ('Data Biometrik', {
#             'fields': ('id_pegawai', 'name', 'image', 'face_id')
#         }),
#         ('Pratinjau Gambar', {
#             'fields': ('detail_image',)
#         }),
#         ('Gambar Pegawai Lainnya', {
#             'fields': ('gambar_pegawai_lainnya',)
#         }),
#         ('Tindakan', {
#             'fields': ('proses_wajah_action',)
#         }),
#     )
    
#     def id_biometrik(self, obj):
#         return obj.id
#     id_biometrik.short_description = 'ID'

#     def pegawai_dengan_jumlah_gambar(self, obj):
#         if obj.id_pegawai:
#             # Hitung jumlah gambar untuk pegawai ini
#             jumlah_gambar = Biometrik.objects.filter(id_pegawai=obj.id_pegawai).count()
#             return mark_safe(f"{obj.id_pegawai.id_pegawai} - {obj.id_pegawai.nama} <span style='color: #777; font-size: 0.8em;'>({jumlah_gambar} gambar)</span>")
#         return "-"
#     pegawai_dengan_jumlah_gambar.short_description = 'Pegawai'
    
#     def image_preview(self, obj):
#         # Gambar untuk halaman daftar
#         if obj.image:
#             return format_html('<img src="{}" style="max-height: 80px; max-width: 80px; border-radius: 5px; object-fit: cover;" />', obj.image.url)
#         return "Tidak ada gambar"
#     image_preview.short_description = 'Gambar'
    
#     def detail_image(self, obj):
#         # Gambar lebih besar untuk halaman detail
#         if not obj:
#             return "-"
#         return mark_safe(f'<img src="/sipreti/uncompress/{obj.id}/" width="300" height="300" style="border-radius: 8px; object-fit: contain; border: 1px solid #ddd;" alt="Wajah (Besar)" />')
#     detail_image.short_description = "Gambar Hasil Uncompress"

#     def gambar_pegawai_lainnya(self, obj):
#         # Tampilkan gambar lain dari pegawai yang sama
#         if not obj.id_pegawai:
#             return "Tidak ada pegawai terkait"
            
#         gambar_lain = Biometrik.objects.filter(id_pegawai=obj.id_pegawai).exclude(id=obj.id)
        
#         if not gambar_lain.exists():
#             return "Tidak ada gambar lain untuk pegawai ini"
            
#         html = '<div style="display: flex; flex-wrap: wrap; gap: 10px;">'
        
#         for gambar in gambar_lain:
#             if gambar.image:
#                 html += f'''
#                 <div style="text-align: center; margin-bottom: 15px;">
#                     <a href="/admin/sipreti/biometrik/{gambar.id}/change/">
#                         <img src="{gambar.image.url}" style="max-height: 120px; max-width: 120px; border-radius: 5px; object-fit: cover; border: 1px solid #ddd;" />
#                         <div style="font-size: 0.8em; margin-top: 5px;">{gambar.name or f"ID: {gambar.id}"}</div>
#                     </a>
#                 </div>
#                 '''
        
#         html += '</div>'
#         return mark_safe(html)
#     gambar_pegawai_lainnya.short_description = 'Gambar Lain dari Pegawai Ini'
    
#     def proses_action(self, obj):
#         # Tombol untuk menjalankan proses wajah di halaman daftar
#         if obj and obj.id:
#             return mark_safe(f'<a href="/admin/sipreti/biometrik/{obj.id}/proses_wajah/" class="button">Proses Wajah</a>')
#         return "-"
#     proses_action.short_description = "Aksi"
    
#     def proses_wajah_action(self, obj):
#         # Tombol untuk menjalankan proses wajah di halaman detail dengan opsi proses semua
#         if obj and obj.id:
#             html = f'''
#             <div style="display: flex; gap: 10px;">
#                 <a href="/admin/sipreti/biometrik/{obj.id}/proses_wajah/" class="button">Proses Wajah Ini</a>
#                 <a href="/admin/sipreti/biometrik/{obj.id}/proses_semua_wajah/" class="button" style="background-color: #417690;">Proses Semua Wajah Pegawai Ini</a>
#             </div>
#             '''
#             return mark_safe(html)
#         return "Belum tersimpan"
#     proses_wajah_action.short_description = "Proses Wajah"
    
#     def save_model(self, request, obj, form, change):
#         try:
#             with transaction.atomic():
#                 # Simpan model terlebih dahulu
#                 super().save_model(request, obj, form, change)
                
#                 # Refresh untuk mendapatkan data terbaru
#                 obj.refresh_from_db()
                
#                 if obj.image:
#                     id_pegawai = str(obj.id_pegawai.id_pegawai)
                    
#                     # Path gambar asli
#                     original_image_path = obj.image.path
                    
#                     # Proses gambar: grayscale dan kompresi Huffman
#                     try:
#                         # Ubah gambar ke grayscale
#                         gray_image = convert_to_grayscale(original_image_path)
                        
#                         if isinstance(gray_image, np.ndarray):
#                             grayscale_img = Image.fromarray(gray_image, mode='L')
#                         else:
#                             # Jika sudah berupa PIL Image
#                             grayscale_img = gray_image
                        
#                         # Simpan gambar grayscale ke buffer
#                         buffer = BytesIO()
#                         grayscale_img.save(buffer, format='PNG')
#                         buffer.seek(0)
                        
#                         # Simpan ke field hasil_uncompress
#                         uncompressed_file_name = os.path.basename(original_image_path).replace(".jpg", "_uncompressed.png")
#                         obj.hasil_uncompress.save(uncompressed_file_name, ContentFile(buffer.getvalue()), save=True)
#                         print(f"✅ Hasil grayscale (uncompress) disimpan ke: {obj.hasil_uncompress.path}")
                        
#                         # Lakukan kompresi Huffman
#                         compressed_data, huffman_tree = huffman_compress(gray_image)
                        
#                         # Simpan hasil kompresi ke dalam file temporary
#                         temp_compressed_path = f"{os.path.splitext(original_image_path)[0]}_compressed.bin"
#                         with open(temp_compressed_path, 'wb') as f:
#                             f.write(compressed_data)
                       
#                         # Perbarui objek dengan gambar yang sudah diproses
#                         file_name = os.path.basename(original_image_path)
#                         with open(temp_compressed_path, 'rb') as f:
#                             compressed_content = f.read()
#                             obj.image.save(
#                                 f"compressed_{file_name}", 
#                                 ContentFile(compressed_content), 
#                                 save=True
#                             )
                        
#                         # SEKARANG LAKUKAN DEKOMPRESI DAN SIMPAN HASIL DEKOMPRESI
#                         try:
                                                       
#                             # Parse frequency model untuk membangun pohon Huffman kembali
#                             # Asumsikan frequensi bisa diakses dari hasil huffman_tree
#                             frequencies = huffman_tree  # Sesuaikan jika struktur berbeda
                            
#                             # Bangun pohon Huffman
#                             root = build_huffman_tree(frequencies)
                            
#                             # Dekode data kompresi
#                             # Asumsikan tinggi dan lebar bisa diakses, jika tidak bisa simpan di suatu tempat
#                             height, width = gray_image.shape
#                             original_length = width * height
                            
#                             # Tambahkan informasi padding (asumsikan padding adalah 0)
#                             # Sesuaikan jika kompresi Huffman Anda mengembalikan informasi padding
#                             padding = 0
#                             compressed_bytes_with_padding = compressed_data + bytes([padding])
                            
#                             # Dekode Huffman
#                             decoded_pixels = decode_huffman(
#                                 compressed_bytes_with_padding, 
#                                 root, 
#                                 original_length
#                             )
                            
#                             # Ubah list pixel menjadi array numpy
#                             pixels_array = np.array(decoded_pixels, dtype=np.uint8)
                            
#                             # Reshape array sesuai dimensi gambar
#                             image_array = pixels_array.reshape((height, width))
                            
#                             # Buat gambar dari array
#                             uncompressed_image = Image.fromarray(image_array, mode='L')
                            
#                             # Simpan gambar hasil dekompresi ke buffer
#                             buffer = BytesIO()
#                             uncompressed_image.save(buffer, format='PNG')
#                             buffer.seek(0)
                            
#                             # Simpan ke field hasil_uncompress
#                             uncompressed_file_name = os.path.basename(original_image_path).replace(".jpg", "_uncompressed.png")
#                             obj.hasil_uncompress.save(uncompressed_file_name, ContentFile(buffer.getvalue()), save=True)
#                             print(f"✅ Hasil uncompress disimpan ke: {obj.hasil_uncompress.path}")
                            
#                         except Exception as e:
#                             print(f"❌ Error saat membuat hasil uncompress: {str(e)}")
#                             import traceback
#                             print(traceback.format_exc())
                        
#                         # Hapus file temporary
#                         if os.path.exists(temp_compressed_path):
#                             os.remove(temp_compressed_path)
#                     except Exception as e:
#                         print(f"Error saat memproses gambar: {str(e)}")
#                         # Lanjutkan dengan gambar asli jika terjadi kesalahan
                    
#                     # PERBAIKAN: Gunakan path lokal untuk gambar, bukan URL lengkap
#                     # Ambil semua gambar untuk pegawai ini
#                     all_images = Biometrik.objects.filter(id_pegawai=obj.id_pegawai)
                    
#                     # Gunakan path lokal file, bukan URL lengkap
#                     image_paths = [img.image.path for img in all_images if img.image]
                    
#                     # Tambahkan path gambar yang baru diupload jika belum ada
#                     if obj.image.path not in image_paths:
#                         image_paths.append(obj.image.path)
                    
#                     # Panggil add_face dengan path lokal file
#                     success = add_face(image_paths, id_pegawai)
                    
#                     if success:
#                         self.message_user(request, "Gambar tersimpan sebagai grayscale, dikompresi dengan Huffman, dan vektor wajah berhasil ditambahkan.", level='success')
#                     else:
#                         self.message_user(request, "Gambar tersimpan tetapi vektor wajah gagal ditambahkan. Pastikan wajah terlihat jelas.", level='warning')
        
#         except Exception as e:
#             # Tangani error dan batalkan transaksi
#             self.message_user(request, f"Terjadi kesalahan saat menyimpan: {str(e)}", level='error')
#             import traceback
#             print(traceback.format_exc())

#     def get_urls(self):
#         urls = super().get_urls()
#         custom_urls = [
#             path('<path:object_id>/proses_wajah/', self.admin_site.admin_view(self.proses_wajah_view), name='biometrik_proses_wajah'),
#             path('<path:object_id>/proses_semua_wajah/', self.admin_site.admin_view(self.proses_semua_wajah_view), name='biometrik_proses_semua_wajah'),
#         ]
#         return custom_urls + urls
    
#     def proses_wajah_view(self, request, object_id):
#         try:
#             # Dapatkan objek biometrik
#             biometrik = get_object_or_404(Biometrik, id=object_id)
            
#             # Dapatkan id_pegawai sebagai string
#             id_pegawai = str(biometrik.id_pegawai.id_pegawai)
            
#             # Ambil semua gambar untuk pegawai ini
#             all_images = Biometrik.objects.filter(id_pegawai=biometrik.id_pegawai)
#             url_image_array = [request.build_absolute_uri(img.image.url) for img in all_images if img.image]
            
#             # Panggil add_face untuk proses
#             success = add_face(url_image_array, id_pegawai)
            
#             if success:
#                 self.message_user(request, "Vektor wajah berhasil diproses.", level=messages.SUCCESS)
#             else:
#                 self.message_user(request, "Gagal memproses vektor wajah. Pastikan wajah terlihat jelas.", level=messages.WARNING)
                
#             # Redirect kembali ke halaman daftar, bukan halaman detail
#             return redirect('/admin/sipreti/biometrik/')
#         except Exception as e:
#             import traceback
#             logger.error(f"Error saat memproses wajah: {str(e)}")
#             logger.error(traceback.format_exc())
#             self.message_user(request, f"Gagal memproses wajah: {str(e)}", level=messages.ERROR)
#             return redirect('/admin/sipreti/biometrik/')
    
#     def proses_semua_wajah_view(self, request, object_id):
#         try:
#             # Dapatkan objek biometrik
#             biometrik = get_object_or_404(Biometrik, id=object_id)
            
#             # Dapatkan id_pegawai sebagai string
#             id_pegawai = str(biometrik.id_pegawai.id_pegawai)
            
#             # Ambil semua gambar untuk pegawai ini
#             all_images = Biometrik.objects.filter(id_pegawai=biometrik.id_pegawai)
#             url_image_array = [request.build_absolute_uri(img.image.url) for img in all_images if img.image]
            
#             # Panggil add_face untuk proses
#             success = add_face(url_image_array, id_pegawai)
            
#             jumlah_gambar = len(url_image_array)
            
#             if success:
#                 self.message_user(
#                     request, 
#                     f"Vektor wajah berhasil diproses untuk pegawai {biometrik.id_pegawai.nama} ({jumlah_gambar} gambar).", 
#                     level=messages.SUCCESS
#                 )
#             else:
#                 self.message_user(
#                     request, 
#                     f"Gagal memproses vektor wajah untuk pegawai {biometrik.id_pegawai.nama}. Pastikan wajah terlihat jelas.", 
#                     level=messages.WARNING
#                 )
                
#             # Kembalikan ke halaman daftar
#             return redirect('/admin/sipreti/biometrik/')
#         except Exception as e:
#             import traceback
#             logger.error(f"Error saat memproses semua wajah: {str(e)}")
#             logger.error(traceback.format_exc())
#             self.message_user(request, f"Gagal memproses semua wajah: {str(e)}", level=messages.ERROR)
#             return redirect('/admin/sipreti/biometrik/')
        
#     def proses_wajah_terpilih(self, request, queryset):
#         jumlah_sukses = 0
#         jumlah_error = 0
        
#         # Kelompokkan berdasarkan id_pegawai untuk memproses wajah berdasarkan pegawai
#         pegawai_list = {}
#         for biometrik in queryset:
#             if biometrik.id_pegawai_id not in pegawai_list:
#                 pegawai_list[biometrik.id_pegawai_id] = []
#             pegawai_list[biometrik.id_pegawai_id].append(biometrik)
        
#         # Proses wajah untuk setiap pegawai
#         for id_pegawai, biometriks in pegawai_list.items():
#             try:
#                 # Dapatkan id_pegawai sebagai string
#                 id_pegawai_str = str(biometriks[0].id_pegawai.id_pegawai)
#                 username = biometriks[0].id_pegawai.nama

#                 # Dapatkan URL gambar
#                 url_image_array = [request.build_absolute_uri(bm.image.url) for bm in biometriks if bm.image]
                
#                 if url_image_array:
#                     success = add_face(url_image_array, id_pegawai_str)
#                     if success:
#                         jumlah_sukses += 1
#                         self.message_user(
#                             request, 
#                             f"Berhasil memproses vektor wajah untuk pegawai {username} ({len(url_image_array)} gambar).", 
#                             level=messages.SUCCESS
#                         )
#                     else:
#                         jumlah_error += 1
#                         self.message_user(
#                             request, 
#                             f"Gagal memproses vektor wajah untuk pegawai {username}. Pastikan wajah terlihat jelas.", 
#                             level=messages.WARNING
#                         )
#             except Exception as e:
#                 jumlah_error += 1
#                 logger.error(f"Error saat memproses wajah untuk pegawai {id_pegawai}: {str(e)}")
#         if jumlah_sukses > 0 and jumlah_error > 0:
#             self.message_user(
#                 request, 
#                 f"Ringkasan: Berhasil memproses {jumlah_sukses} pegawai, gagal memproses {jumlah_error} pegawai.", 
#                 level=messages.INFO
#             )
#     proses_wajah_terpilih.short_description = "Proses ulang vektor wajah untuk data terpilih"
    
#     # Tambahkan ke actions
#     actions = ['proses_wajah_terpilih']
    
#     # Fungsi untuk mengelompokkan tampilan list berdasarkan pegawai
#     def get_queryset(self, request):
#         # Tambahkan ordering default berdasarkan id_pegawai 
#         # untuk mengelompokkan data berdasarkan pegawai
#         qs = super().get_queryset(request)
#         return qs.select_related('id_pegawai').defer('created_at', 'updated_at')
    
#     def get_admin_url(self, obj):
#         # Kustom URL admin untuk pegawai
#         return f"/admin/sipreti/pegawai/{obj.id_pegawai}/change/"
    
#     def changelist_view(self, request, extra_context=None):
#         try:
#             return super().changelist_view(request, extra_context)
#         except AttributeError as e:
#             if str(e) == "'Pegawai' object has no attribute 'id'":
#                 # Tangani error dengan menambahkan filter ke URL alih-alih pergi ke detail view
#                 self.message_user(
#                     request,
#                     "Catatan: Tampilan dikelompokkan. Klik pada pegawai untuk melihat/mengedit semua foto mereka.",
#                     level=messages.INFO
#                 )
#                 return redirect('/admin/sipreti/biometrik/')
#             else:
#                 raise e
    
# @admin.register(Pegawai)
# class PegawaiAdmin(admin.ModelAdmin):
#     list_display = ['id_pegawai', 'nama', 'nip', 'email', 'id_jabatan', 'id_unit_kerja']
#     search_fields = ['id_pegawai', 'nama', 'nip', 'email']
#     list_filter = ['id_jabatan', 'id_unit_kerja']
    
#     # Nonaktifkan kemampuan menambah/mengubah/menghapus
#     def has_add_permission(self, request):
#         return False
    
#     def has_change_permission(self, request, obj=None):
#         return False
    
#     def has_delete_permission(self, request, obj=None):
#         return False
    

# logger = logging.getLogger(__name__)
# class LogVerifikasiInline(admin.TabularInline):
#     model = LogVerifikasi
#     extra = 0
#     readonly_fields = ['status_verifikasi', 'nilai_kecocokan', 'waktu_dekompresi_ms', 'waktu_verifikasi_ms', 'created_at']
#     can_delete = False

# # @admin.register(KompresiHuffman)
# # class KompresiHuffmanAdmin(admin.ModelAdmin):
# #     list_display = ['id', 'id_pegawai', 'face_preview',]
# #     search_fields = ['id', 'id_pegawai']
# #     inlines = [LogVerifikasiInline]
# #     actions = ['action_uncompress_selected', 'action_verify_selected']

# #     readonly_fields = ['detail_image', 'statistics', 'verification_result', 'created_at_display']
    
# #     list_display_links = ['id', 'id_pegawai']
# #     list_per_page = 20
    
# #     def created_at_display(self, obj):
# #         return obj.created_at
# #     created_at_display.short_description = "Dibuat pada"
    
# #     fieldsets = (
# #         ('Data Kompresi', {
# #             'fields': ('id_pegawai', 'width', 'height', 'original_length', 'original_size', 'compressed_size', 'compression_ratio', 'created_at_display')
# #         }),
# #         ('Hasil Uncompress', {
# #             'fields': ('detail_image', 'statistics')
# #         }),
# #         ('Verifikasi', {
# #             'fields': ('verification_result',)
# #         }),
# #     )

# #     # def get_latest_verification(self, obj):
# #     #     latest_log = LogVerifikasi.objects.filter(kompresi=obj).order_by('-created_at').first()
# #     #     if latest_log:
# #     #         status = "✅ Terverifikasi" if latest_log.status_verifikasi else "❌ Gagal"
# #     #         if latest_log.nilai_kecocokan:
# #     #             return f"{status} ({latest_log.nilai_kecocokan:.2f})"
# #     #         return status
# #     #     return "Belum diverifikasi"
# #     # get_latest_verification.short_description = "Status Verifikasi"
    
# #     def face_preview(self, obj):
# #         if not obj:
# #             print(f"[PREVIEW] Objek tidak ada", file=sys.stderr)
# #             return "-"
            
# #         print(f"[PREVIEW] ID: {obj.id}", file=sys.stderr)
        
# #         if not obj.hasil_uncompress:
# #             print(f"[PREVIEW] hasil_uncompress kosong untuk ID: {obj.id}", file=sys.stderr)
# #             return "-"
        
# #         try:
# #             # Debug info di console
# #             print(f"[PREVIEW] hasil_uncompress URL: {obj.hasil_uncompress.url}", file=sys.stderr)
# #             print(f"[PREVIEW] hasil_uncompress PATH: {obj.hasil_uncompress.path}", file=sys.stderr)
# #             print(f"[PREVIEW] hasil_uncompress NAME: {obj.hasil_uncompress.name}", file=sys.stderr)
            
# #             # Check if file exists
# #             if os.path.exists(obj.hasil_uncompress.path):
# #                 file_size = os.path.getsize(obj.hasil_uncompress.path)
# #                 print(f"[PREVIEW] File ada, ukuran: {file_size} bytes", file=sys.stderr)
# #             else:
# #                 print(f"[PREVIEW] PERINGATAN: File tidak ada di disk: {obj.hasil_uncompress.path}", file=sys.stderr)
                
# #             # Debugging untuk MEDIA_URL dan settings
# #             from django.conf import settings
# #             print(f"[PREVIEW] MEDIA_URL: {settings.MEDIA_URL}", file=sys.stderr)
# #             print(f"[PREVIEW] MEDIA_ROOT: {settings.MEDIA_ROOT}", file=sys.stderr)
                
# #             # Gunakan URL dari field hasil_uncompress secara langsung
# #             img_tag = f'<img src="{obj.hasil_uncompress.url}" width="100" height="100" style="border-radius: 5px; object-fit: cover;" alt="Wajah" />'
# #             print(f"[PREVIEW] IMG tag: {img_tag}", file=sys.stderr)
# #             return mark_safe(img_tag)
# #         except Exception as e:
# #             import traceback
# #             print(f"[PREVIEW] Error: {str(e)}", file=sys.stderr)
# #             print(traceback.format_exc(), file=sys.stderr)
# #             return f"Error: {str(e)}"

#     # def detail_image(self, obj):
#     #     if not obj or not obj.hasil_uncompress:
#     #         return "-"
        
#     #     # Gunakan URL dari field hasil_uncompress secara langsung
#     #     return mark_safe(f'<img src="{obj.hasil_uncompress.url}" width="300" height="300" style="border-radius: 8px; object-fit: contain; border: 1px solid #ddd;" alt="Wajah (Besar)" />')
#     # detail_image.short_description = "Gambar Hasil Uncompress"

#     # def statistics(self, obj):
#     #     # Tampilkan statistik kompresi
#     #     html = '<div style="padding: 15px; background-color: #f9f9f9; border-radius: 5px; margin-top: 10px;">'
#     #     html += f'<div><strong>Ukuran Gambar:</strong> {obj.width} x {obj.height} piksel</div>'
#     #     html += f'<div><strong>Jumlah Piksel:</strong> {obj.original_length}</div>'
        
#     #     if obj.original_size and obj.compressed_size:
#     #         html += f'<div><strong>Ukuran Asli:</strong> {obj.original_size:,} bytes</div>'
#     #         html += f'<div><strong>Ukuran Terkompresi:</strong> {obj.compressed_size:,} bytes</div>'
#     #         html += f'<div><strong>Rasio Kompresi:</strong> {obj.compression_ratio:.2f}x</div>'
#     #         savings = (1 - (obj.compressed_size / obj.original_size)) * 100
#     #         html += f'<div><strong>Penghematan:</strong> {savings:.2f}%</div>'
        
#     #     html += '</div>'
#     #     return mark_safe(html)
#     # statistics.short_description = "Statistik Kompresi"
    
#     def verification_result(self, obj):
#         # Tampilkan hasil verifikasi
#         logs = LogVerifikasi.objects.filter(kompresi=obj).order_by('-created_at')
        
#         if not logs.exists():
#             return 'Belum ada verifikasi. Klik tombol "Verifikasi" di atas untuk melakukan verifikasi.'
        
#         html = '<div style="margin-top: 10px;">'
        
#         # Hasil verifikasi terakhir
#         latest = logs.first()
#         status_color = "green" if latest.status_verifikasi else "red"
#         status_icon = "✅" if latest.status_verifikasi else "❌"
#         status_text = "TERVERIFIKASI" if latest.status_verifikasi else "TIDAK TERVERIFIKASI"
        
#         html += f'<div style="padding: 15px; border-radius: 5px; margin-bottom: 20px; background-color: {"#d4edda" if latest.status_verifikasi else "#f8d7da"};">'
#         html += f'<div style="font-size: 18px; font-weight: bold; color: {status_color}; margin-bottom: 10px;">{status_icon} {status_text}</div>'
        
#         if latest.nilai_kecocokan:
#             html += f'<div><strong>Nilai Kecocokan:</strong> {latest.nilai_kecocokan:.2f}</div>'
        
#         html += f'<div><strong>Waktu Dekompresi:</strong> {latest.waktu_dekompresi_ms} ms</div>'
#         html += f'<div><strong>Waktu Verifikasi:</strong> {latest.waktu_verifikasi_ms} ms</div>'
#         html += f'<div><strong>Total Waktu:</strong> {latest.waktu_dekompresi_ms + latest.waktu_verifikasi_ms} ms</div>'
#         html += f'<div><strong>Verifikasi pada:</strong> {latest.created_at}</div>'
#         html += '</div>'
        
#         # Riwayat verifikasi
#         if logs.count() > 1:
#             html += '<h3 style="margin-top: 20px;">Riwayat Verifikasi</h3>'
#             html += '<table style="width: 100%; border-collapse: collapse;">'
#             html += '<tr style="background-color: #f2f2f2;"><th style="padding: 8px; border: 1px solid #ddd;">Waktu</th><th style="padding: 8px; border: 1px solid #ddd;">Status</th><th style="padding: 8px; border: 1px solid #ddd;">Nilai Kecocokan</th><th style="padding: 8px; border: 1px solid #ddd;">Waktu Dekompresi</th><th style="padding: 8px; border: 1px solid #ddd;">Waktu Verifikasi</th></tr>'
            
#             for log in logs:
#                 status = "✅ COCOK" if log.status_verifikasi else "❌ GAGAL"
#                 nilai = f"{log.nilai_kecocokan:.2f}" if log.nilai_kecocokan else "-"
#                 html += f'<tr style="border: 1px solid #ddd;"><td style="padding: 8px; border: 1px solid #ddd;">{log.created_at}</td><td style="padding: 8px; border: 1px solid #ddd;">{status}</td><td style="padding: 8px; border: 1px solid #ddd;">{nilai}</td><td style="padding: 8px; border: 1px solid #ddd;">{log.waktu_dekompresi_ms} ms</td><td style="padding: 8px; border: 1px solid #ddd;">{log.waktu_verifikasi_ms} ms</td></tr>'
            
#             html += '</table>'
        
#         html += '</div>'
#         return mark_safe(html)
#     verification_result.short_description = "Hasil Verifikasi"
    
#     # Action untuk uncompress dan verifikasi beberapa data sekaligus
#     def action_uncompress_selected(self, request, queryset):
#         success_count = 0
#         error_count = 0
        
#         for kompresi in queryset:
#             try:
#                 # Lakukan proses uncompress
#                 self.uncompress_object(request, kompresi.id)
#                 success_count += 1
#             except Exception as e:
#                 error_count += 1
#                 logger.error(f"Error saat uncompress ID {kompresi.id}: {str(e)}")
        
#         if success_count > 0:
#             self.message_user(request, f"Berhasil melakukan uncompress pada {success_count} data.", level=messages.SUCCESS)
        
#         if error_count > 0:
#             self.message_user(request, f"Gagal melakukan uncompress pada {error_count} data. Lihat log untuk detail.", level=messages.ERROR)
#     action_uncompress_selected.short_description = "Uncompress data terpilih"
    
#     def action_verify_selected(self, request, queryset):
#         success_count = 0
#         error_count = 0
        
#         for kompresi in queryset:
#             try:
#                 # Lakukan proses verifikasi
#                 from .views import verifikasi_dari_kompresi
#                 response = verifikasi_dari_kompresi(request, kompresi.id)
#                 success_count += 1
#             except Exception as e:
#                 error_count += 1
#                 logger.error(f"Error saat verifikasi ID {kompresi.id}: {str(e)}")
        
#         if success_count > 0:
#             self.message_user(request, f"Berhasil melakukan verifikasi pada {success_count} data.", level=messages.SUCCESS)
        
#         if error_count > 0:
#             self.message_user(request, f"Gagal melakukan verifikasi pada {error_count} data. Lihat log untuk detail.", level=messages.ERROR)
#     action_verify_selected.short_description = "Verifikasi data terpilih"

#     def get_urls(self):
#         urls = super().get_urls()
#         custom_urls = [
#             path('<path:object_id>/uncompress/', self.admin_site.admin_view(self.uncompress_view), name='kompresihuffman_uncompress'),
#             path('<path:object_id>/verify/', self.admin_site.admin_view(self.verify_view), name='kompresihuffman_verify'),
#         ]
#         return custom_urls + urls
    
#     def uncompress_view(self, request, object_id):
#         try:
#             # Lakukan uncompress
#             self.uncompress_object(request, object_id)
            
#             # Redirect ke halaman detail
#             self.message_user(request, "Berhasil melakukan uncompress data.", level=messages.SUCCESS)
#             return redirect(f'/admin/sipreti/kompresihuffman/{object_id}/change/')
#         except Exception as e:
#             import traceback
#             logger.error(f"Error saat uncompress: {str(e)}")
#             logger.error(traceback.format_exc())
#             self.message_user(request, f"Gagal melakukan uncompress: {str(e)}", level=messages.ERROR)
#             return redirect(f'/admin/sipreti/kompresihuffman/{object_id}/change/')
    
#     def uncompress_object(self, request, object_id):
#         kompresi = get_object_or_404(KompresiHuffman, id=object_id)
        
#         print(f"[UNCOMPRESS] Memulai uncompress untuk kompresi ID: {object_id}", file=sys.stderr)
        
#         try:
#             import os
#             BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
#             media_dir = os.path.join(BASE_DIR, "media")
#             debug_dir = os.path.join(media_dir, "debug_images")
#             uncompressed_dir = os.path.join(media_dir, "uncompressed_images")
            
#             # Buat direktori jika belum ada
#             os.makedirs(debug_dir, exist_ok=True)
#             os.makedirs(uncompressed_dir, exist_ok=True)
            
#             print(f"[UNCOMPRESS] Direktori debug: {debug_dir}", file=sys.stderr)
#             print(f"[UNCOMPRESS] Direktori uncompressed: {uncompressed_dir}", file=sys.stderr)
            
#             uncompressed_dir = os.path.join(settings.MEDIA_ROOT, "uncompressed_images")
#             os.makedirs(uncompressed_dir, exist_ok=True)
#             print(f"[UNCOMPRESS] Direktori {uncompressed_dir} dibuat/tersedia", file=sys.stderr)

#             # Parse frekuensi model
#             frequencies = json.loads(kompresi.frequency_model)
            
#             # Bangun pohon Huffman
#             from .views import build_huffman_tree
#             root = build_huffman_tree(frequencies)
            
#             # Validasi pohon Huffman
#             leaf_count, is_valid = self.validate_huffman_tree(root)
#             print(f"[UNCOMPRESS] Validasi pohon Huffman: leaf count={leaf_count}, valid={is_valid}", file=sys.stderr)
            
#             # Dekode data kompresi
#             compressed_data = kompresi.compressed_file
            
#             if len(compressed_data) > 0:
#                 padding = compressed_data[-1]
#                 print(f"[UNCOMPRESS] Byte terakhir (padding): {padding}", file=sys.stderr)
            
#             # Cek apakah ini RGB
#             is_rgb = getattr(kompresi, 'is_rgb', False)
            
#             # Fungsi bytes_to_bits yang diperbaiki
#             def bytes_to_bits(byte_data, padding_bits):
#                 bits = []
#                 for i in range(len(byte_data) - 1):
#                     byte = byte_data[i]
#                     for j in range(7, -1, -1):
#                         bits.append(1 if (byte & (1 << j)) else 0)
                
#                 # Penanganan padding yang benar
#                 if padding_bits > 0 and padding_bits < 8:
#                     bits = bits[:-padding_bits]
                
#                 return bits
            
#             # Decode Huffman dengan fungsi yang sudah diperbaiki
#             def decode_huffman_improved(compressed_data, root, original_length):
#                 padding = compressed_data[-1]
#                 bits = bytes_to_bits(compressed_data, padding)
                
#                 decoded_pixels = []
#                 node = root
                
#                 for bit in bits:
#                     if bit == 0:
#                         node = node.left
#                     else:
#                         node = node.right
                    
#                     if node and node.value is not None:
#                         decoded_pixels.append(node.value)
#                         node = root
                        
#                         if len(decoded_pixels) >= original_length:
#                             break
                
#                 # Penyesuaian jumlah piksel
#                 if len(decoded_pixels) < original_length:
#                     padding_needed = original_length - len(decoded_pixels)
#                     print(f"[UNCOMPRESS] Menambahkan {padding_needed} piksel hitam (0)", file=sys.stderr)
#                     decoded_pixels.extend([0] * padding_needed)
#                 elif len(decoded_pixels) > original_length:
#                     excess = len(decoded_pixels) - original_length
#                     print(f"[UNCOMPRESS] Memotong {excess} piksel berlebih", file=sys.stderr)
#                     decoded_pixels = decoded_pixels[:original_length]
                
#                 return decoded_pixels
            
#             # Gunakan fungsi dekode yang diperbaiki
#             decoded_pixels = decode_huffman_improved(compressed_data, root, kompresi.original_length)
#             print(f"[UNCOMPRESS] Jumlah piksel hasil dekode: {len(decoded_pixels)}", file=sys.stderr)
            
#             # Ubah list pixel menjadi array numpy
#             pixels_array = np.array(decoded_pixels, dtype=np.uint8)
            
#             # Verifikasi panjang array
#             expected_length = kompresi.width * kompresi.height * (3 if is_rgb else 1)
#             actual_length = len(pixels_array)
            
#             print(f"[UNCOMPRESS] Panjang array hasil: {actual_length}, Panjang yang diharapkan: {expected_length}", file=sys.stderr)
            
#             # Definisikan fungsi untuk mencoba berbagai variasi reshape
#             def try_various_reshapes(pixels, width, height, is_rgb):
#                 results = []
                
#                 # Daftar variasi reshape yang akan dicoba
#                 variations = [
#                     ("original", (height, width)),
#                     ("swapped", (width, height)),
#                     # Tambahkan variasi lain jika diperlukan
#                 ]
                
#                 for name, dims in variations:
#                     try:
#                         if is_rgb:
#                             reshaped = pixels.reshape((*dims, 3))
#                         else:
#                             reshaped = pixels.reshape(dims)
#                         results.append((name, reshaped))
#                         print(f"[UNCOMPRESS] Reshape '{name}' berhasil: {reshaped.shape}", file=sys.stderr)
#                     except Exception as e:
#                         print(f"[UNCOMPRESS] Reshape '{name}' gagal: {str(e)}", file=sys.stderr)
                
#                 # Jika semua variasi gagal, coba fallback ke pendekatan matematis
#                 if not results:
#                     try:
#                         import math
#                         side_length = int(math.sqrt(len(pixels) / (3 if is_rgb else 1)))
#                         if is_rgb:
#                             dims = (side_length, len(pixels) // (side_length * 3), 3)
#                         else:
#                             dims = (side_length, len(pixels) // side_length)
#                         reshaped = pixels[:np.prod(dims)].reshape(dims)
#                         results.append(("fallback", reshaped))
#                         print(f"[UNCOMPRESS] Reshape fallback berhasil: {reshaped.shape}", file=sys.stderr)
#                     except Exception as e:
#                         print(f"[UNCOMPRESS] Reshape fallback gagal: {str(e)}", file=sys.stderr)
                
#                 return results
            
#             # Coba berbagai variasi reshape
#             reshape_results = try_various_reshapes(pixels_array, kompresi.width, kompresi.height, is_rgb)
            
#             if not reshape_results:
#                 raise Exception("Tidak dapat mereshape array ke dimensi yang valid")
            
#             # Gunakan hasil reshape pertama yang berhasil
#             name, image_array = reshape_results[0]
#             mode = 'RGB' if is_rgb else 'L'
            
#             print(f"[UNCOMPRESS] Menggunakan reshape '{name}' dengan bentuk {image_array.shape}", file=sys.stderr)
            
#             # Buat gambar dari array
#             image = Image.fromarray(image_array, mode=mode)
                      
#             # Koreksi orientasi gambar
#             from PIL import ImageOps
            
#             # Orientasi asli
#             original_image = image
#             original_image.save(f"{debug_dir}original_{kompresi.id}.png")
            
#             rotated_right_image = original_image.rotate(-90)  # Atau rotate(270)
#             rotated_right_image.save(f"{debug_dir}rotated_right_{kompresi.id}.png")

#             # Rotasi 270° (mengembalikan dari quarterTurns: 1)
#             rotated_image = original_image.rotate(270)
#             rotated_image.save(f"{debug_dir}rotated_{kompresi.id}.png")
            
#             # Flip horizontal (mengembalikan dari Matrix4.rotationY(3.14))
#             flipped_image = ImageOps.mirror(original_image)
#             flipped_image.save(f"{debug_dir}flipped_{kompresi.id}.png")
            
#             # Kombinasi rotasi dan flip
#             combo_image = ImageOps.mirror(original_image.rotate(270))
#             combo_image.save(f"{debug_dir}combo_{kompresi.id}.png")
            
#             # Gunakan gambar yang sudah dikoreksi orientasinya
#             image = combo_image
            
#             # Simpan gambar hasil akhir
#             import io
#             buffer = io.BytesIO()
#             image.save(buffer, format='PNG')
#             buffer.seek(0)

#             print(f"[UNCOMPRESS] Hasil dekompresi: WxH = {kompresi.width}x{kompresi.height}", file=sys.stderr)
#             print(f"[UNCOMPRESS] Mode gambar: {mode}", file=sys.stderr)         
#             # Hapus gambar lama jika ada
#             if kompresi.hasil_uncompress:
#                 file_path = kompresi.hasil_uncompress.path
#                 if os.path.exists(file_path):
#                     file_size = os.path.getsize(file_path)
#                     print(f"[UNCOMPRESS] File berhasil disimpan: {file_path} (ukuran: {file_size} bytes)", file=sys.stderr)
#                 else:
#                     print(f"[UNCOMPRESS] ERROR: File tidak ada di path: {file_path}", file=sys.stderr)
#             else:
#                 print(f"[UNCOMPRESS] ERROR: field hasil_uncompress kosong", file=sys.stderr)
            
#             # Membuat ContentFile dari buffer dan menyimpannya ke model
#             file_name = f'uncompressed_{kompresi.id}.png'
#             image_file = ContentFile(buffer.getvalue(), name=file_name)
            
#             if kompresi.hasil_uncompress:
#                 try:
#                     kompresi.hasil_uncompress.delete(save=False)
#                     print(f"[UNCOMPRESS] File lama dihapus", file=sys.stderr)
#                 except Exception as e:
#                     print(f"[UNCOMPRESS] Error menghapus file lama: {str(e)}", file=sys.stderr)
                    
#             # Simpan file baru ke model
#             kompresi.hasil_uncompress.save(file_name, image_file, save=True)
            
#             # Verifikasi hasil penyimpanan
#             kompresi.refresh_from_db()
#             if kompresi.hasil_uncompress:
#                 print(f"[UNCOMPRESS] Berhasil menyimpan hasil ke field model: {kompresi.hasil_uncompress.name}", file=sys.stderr)
#                 if os.path.exists(kompresi.hasil_uncompress.path):
#                     print(f"[UNCOMPRESS] File ada di disk: {kompresi.hasil_uncompress.path}", file=sys.stderr)
#                 else:
#                     print(f"[UNCOMPRESS] PERINGATAN: File tidak ada di disk", file=sys.stderr)
#             else:
#                 print(f"[UNCOMPRESS] PERINGATAN: Field hasil_uncompress kosong setelah save", file=sys.stderr)
            
#             # Pastikan file ada di disk
#             if os.path.exists(kompresi.hasil_uncompress.path):
#                 file_size = os.path.getsize(kompresi.hasil_uncompress.path)
#                 print(f"[UNCOMPRESS] Ukuran file: {file_size} bytes", file=sys.stderr)
#             else:
#                 print(f"[UNCOMPRESS] PERINGATAN: File tidak ditemukan di disk: {kompresi.hasil_uncompress.path}", file=sys.stderr)
            
#             # Log sukses
#             print(f"[UNCOMPRESS] BERHASIL untuk kompresi ID: {object_id}", file=sys.stderr)
            
#             # Tampilkan pesan hanya jika request tidak None (yaitu jika dipanggil dari admin, bukan otomatis)
#             if request:
#                 self.message_user(request, "Berhasil melakukan uncompress data.", level=messages.SUCCESS)
                
#             return image
            
#         except Exception as e:
#             print(f"[UNCOMPRESS] GAGAL untuk kompresi ID: {object_id}: {str(e)}", file=sys.stderr)
#             import traceback
#             print(traceback.format_exc(), file=sys.stderr)
            
#             # Tampilkan pesan error hanya jika request tidak None
#             if request:
#                 self.message_user(request, f"Gagal melakukan uncompress: {str(e)}", level=messages.ERROR)
                
#             raise e

#     def verify_view(self, request, object_id):
#         try:
#                 # Panggil fungsi verifikasi_dari_kompresi dari views.py
#             from .views import verifikasi_dari_kompresi
#             verifikasi_dari_kompresi(request, object_id)
                
#             # Redirect ke halaman detail hanya jika request tidak None
#             if request:
#                 self.message_user(request, "Berhasil melakukan verifikasi wajah.", level=messages.SUCCESS)
#                 return redirect(f'/admin/sipreti/kompresihuffman/{object_id}/change/')
            
#             return True  # Return nilai untuk operasi otomatis
#         except Exception as e:
#             import traceback
#             logger.error(f"Error saat verifikasi: {str(e)}")
#             logger.error(traceback.format_exc())
            
#             if request:
#                 self.message_user(request, f"Gagal melakukan verifikasi: {str(e)}", level=messages.ERROR)
#                 return redirect(f'/admin/sipreti/kompresihuffman/{object_id}/change/')
            
#             raise e

#     def validate_huffman_tree(self, root):
#         """Validasi struktur dan integritas pohon Huffman"""
#         if root is None:
#             return 0, False
        
#         # Fungsi rekursif untuk traversal dan validasi
#         def _count_leaf_nodes(node):
#             if node is None:
#                 return 0
            
#             # Jika leaf node (memiliki nilai)
#             if node.value is not None:
#                 return 1
            
#             # Jika internal node, harus memiliki kedua child
#             if node.left is None or node.right is None:
#                 raise ValueError("Invalid Huffman tree: internal node missing child")
            
#             # Rekursif ke child nodes
#             return _count_leaf_nodes(node.left) + _count_leaf_nodes(node.right)
        
#         try:
#             leaf_count = _count_leaf_nodes(root)
#             return leaf_count, True
#         except ValueError as e:
#             return 0, False
        
# @receiver(post_save, sender=KompresiHuffman)
# def auto_uncompress_and_verify(sender, instance, created, **kwargs):
#     """
#     Fungsi ini dipanggil secara otomatis setelah KompresiHuffman disimpan.
#     Fungsi ini sudah ada di admin.py.
#     """
#     # Cek apakah perlu di-uncompress (baru dibuat atau belum ada hasil_uncompress)
#     if instance.compressed_file and (created or not instance.hasil_uncompress):
#         try:
#             print(f"[AUTO] Memulai uncompress otomatis untuk ID: {instance.id}", file=sys.stderr)
            
#             # Buat instance admin untuk memanggil fungsi uncompress_object
#             admin_instance = KompresiHuffmanAdmin(KompresiHuffman, None)
            
#             # Panggil fungsi uncompress_object yang sudah ada
#             try:
#                 # Set parameter request=None karena dipanggil dari signal
#                 image = admin_instance.uncompress_object(None, instance.id)
#                 print(f"[AUTO] Berhasil melakukan uncompress untuk ID: {instance.id}", file=sys.stderr)
                
#                 # Verifikasi hasil
#                 instance.refresh_from_db()
#                 if instance.hasil_uncompress and instance.hasil_uncompress.name:
#                     print(f"[AUTO] Berhasil menyimpan hasil uncompress: {instance.hasil_uncompress.name}", file=sys.stderr)
#                 else:
#                     print(f"[AUTO] PERINGATAN: Field hasil_uncompress masih kosong setelah uncompress", file=sys.stderr)
                
#                 # Lakukan verifikasi jika uncompress berhasil
#                 try:
#                     from .views import verifikasi_dari_kompresi
#                     verifikasi_dari_kompresi(None, instance.id)
#                     print(f"[AUTO] Otomatis melakukan verifikasi untuk ID: {instance.id}", file=sys.stderr)
#                 except Exception as e:
#                     print(f"[AUTO] Error verifikasi: {str(e)}", file=sys.stderr)
                
#             except Exception as e:
#                 # Jika uncompress gagal, coba pendekatan alternatif
#                 print(f"[AUTO] Error saat uncompress standar: {str(e)}", file=sys.stderr)
#                 print(f"[AUTO] Mencoba pendekatan alternatif untuk ID: {instance.id}", file=sys.stderr)
                
#                 # --- Kode dekompresi alternatif ---
#                 import os
#                 import json
#                 from PIL import Image, ImageOps
#                 import numpy as np
#                 from django.core.files.base import ContentFile
                
#                 try:
#                     # Siapkan direktori untuk penyimpanan
#                     BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
#                     media_dir = os.path.join(BASE_DIR, "media")
#                     uncompressed_dir = os.path.join(media_dir, "uncompressed_images")
#                     os.makedirs(uncompressed_dir, exist_ok=True)
                    
#                     # Parse frekuensi model
#                     frequencies = json.loads(instance.frequency_model)
                    
#                     # Bangun pohon Huffman
#                     from .views import build_huffman_tree, decode_huffman
#                     root = build_huffman_tree(frequencies)
                    
#                     # Dekode data
#                     compressed_data = instance.compressed_file
#                     decoded_pixels = decode_huffman(compressed_data, root, instance.original_length)
                    
#                     # Buat gambar dari pixel
#                     pixels_array = np.array(decoded_pixels, dtype=np.uint8)
                    
#                     # Coba berbagai varian reshape
#                     reshape_success = False
#                     image_array = None
                    
#                     # Varian 1: height x width
#                     try:
#                         image_array = pixels_array.reshape((instance.height, instance.width))
#                         reshape_success = True
#                         print(f"[AUTO] Reshape berhasil: {instance.height} x {instance.width}", file=sys.stderr)
#                     except Exception as e1:
#                         print(f"[AUTO] Reshape height x width gagal: {str(e1)}", file=sys.stderr)
                    
#                     # Varian 2: width x height
#                     if not reshape_success:
#                         try:
#                             image_array = pixels_array.reshape((instance.width, instance.height))
#                             reshape_success = True
#                             print(f"[AUTO] Reshape berhasil: {instance.width} x {instance.height}", file=sys.stderr)
#                         except Exception as e2:
#                             print(f"[AUTO] Reshape width x height gagal: {str(e2)}", file=sys.stderr)
                    
#                     # Jika semua reshape gagal, coba pendekatan matematis
#                     if not reshape_success:
#                         import math
#                         side = int(math.sqrt(len(pixels_array)))
#                         try:
#                             image_array = pixels_array[:side*side].reshape((side, side))
#                             reshape_success = True
#                             print(f"[AUTO] Reshape matematis berhasil: {side} x {side}", file=sys.stderr)
#                         except Exception as e3:
#                             print(f"[AUTO] Reshape matematis gagal: {str(e3)}", file=sys.stderr)
#                             raise Exception(f"Semua varian reshape gagal")
                    
#                     # Buat gambar dari array
#                     image = Image.fromarray(image_array, mode='L')
                    
#                     # Koreksi orientasi
#                     combo_image = ImageOps.mirror(image.rotate(270))
                    
#                     # Simpan ke file
#                     file_name = f'uncompressed_{instance.id}.png'
#                     file_path = os.path.join(uncompressed_dir, file_name)
#                     combo_image.save(file_path)
                    
#                     # Verifikasi file tersimpan
#                     if os.path.exists(file_path):
#                         print(f"[AUTO] File berhasil disimpan: {file_path}", file=sys.stderr)
#                     else:
#                         print(f"[AUTO] PERINGATAN: File tidak ada setelah save", file=sys.stderr)
                    
#                     # Update field hasil_uncompress di model
#                     with open(file_path, 'rb') as f:
#                         file_content = f.read()
#                         image_file = ContentFile(file_content, name=file_name)
#                         instance.hasil_uncompress.save(file_name, image_file, save=True)
                    
#                     # Verifikasi update DB
#                     instance.refresh_from_db()
#                     if instance.hasil_uncompress and instance.hasil_uncompress.name:
#                         print(f"[AUTO] Berhasil update field: {instance.hasil_uncompress.name}", file=sys.stderr)
#                     else:
#                         print(f"[AUTO] PERINGATAN: Field masih kosong setelah update", file=sys.stderr)
                    
#                     # Lakukan verifikasi
#                     try:
#                         from .views import verifikasi_dari_kompresi
#                         verifikasi_dari_kompresi(None, instance.id)
#                         print(f"[AUTO] Otomatis melakukan verifikasi untuk ID: {instance.id}", file=sys.stderr)
#                     except Exception as ve:
#                         print(f"[AUTO] Error verifikasi: {str(ve)}", file=sys.stderr)
                    
#                 except Exception as alt_e:
#                     print(f"[AUTO] Pendekatan alternatif juga gagal: {str(alt_e)}", file=sys.stderr)
#                     import traceback
#                     print(traceback.format_exc(), file=sys.stderr)
                
#         except Exception as e:
#             print(f"[AUTO] Error proses otomatis untuk ID {instance.id}: {str(e)}", file=sys.stderr)
#             import traceback
#             print(traceback.format_exc(), file=sys.stderr)