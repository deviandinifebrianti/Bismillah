from django.shortcuts import render
from django.http import JsonResponse, HttpResponseServerError
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.forms.models import model_to_dict
import os
from django.conf import settings
from .models import Biometrik, Jabatan, UnitKerja, RadiusAbsen, Pegawai, LogAbsensi, LogVerifikasi, KompresiRle, UserAndroid, KompresiHuffman
from sipreti.face_recognition import main
from django.conf import settings
import time
from .face_recognition.main import add_face
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from rest_framework.decorators import api_view, parser_classes
from django.http import JsonResponse, HttpResponse
from django.views.decorators.http import require_http_methods
from django.contrib.auth.models import User
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .serializers import BiometrikSerializer, JabatanSerializer, PegawaiSerializer, LogAbsensiSerializer, RadiusAbsenSerializer, UnitKerjaSerializer
from rest_framework import viewsets
from .models import Pegawai, LogAbsensi
from django.contrib.auth.hashers import make_password
from django.utils import timezone
from django.contrib.auth.hashers import check_password
import requests
import base64
from PIL import Image
import numpy as np
from io import BytesIO
from .face_recognition.main import add_face
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from collections import Counter
import traceback
import sys
import io
import json
import logging
from django.views.decorators.http import require_http_methods
from django.views.decorators.http import require_GET, require_POST
from django.shortcuts import render, get_object_or_404
import os
import json
import base64
import pickle
from datetime import datetime
import traceback
from django.db import connection
import gzip
import base64
import json

import numpy as np
import cv2  # Pastikan opencv-python sudah diinstal

from django.http import JsonResponse, HttpResponseBadRequest
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt

path_dataset = settings.MEDIA_ROOT+"/sipreti/dataset/"
# Create your views here.
# @csrf_exempt
# def add_image(request):
#     time.sleep(3)
#     if request.method == 'POST':
#         id_pegawai = request.POST['id_pegawai']
#         name = request.POST['name']
#         image_file = request.FILES.get('image')

#         if not image_file:
#             return HttpResponseServerError("Memerlukan File Gambar")

#         # Simpan file ke folder media/biometrik/<id_pegawai>/
#         folder_path = os.path.join('biometrik', str(id_pegawai))
#         file_name = f"{int(time.time())}_{image_file.name}"
#         saved_path = default_storage.save(os.path.join(folder_path, file_name), ContentFile(image_file.read()))
#         image_url = request.build_absolute_uri(os.path.join(settings.MEDIA_URL, saved_path))

#         file_name_only = str(id_pegawai)
#         biometrik = Biometrik.objects.filter(id_pegawai=id_pegawai)

#         if biometrik.count() == 0:
#             url_image_array = [image_url]
#             adding_face = main.add_face(url_image_array, file_name_only)
#         else:
#             url_image_array = [b.image for b in biometrik]
#             url_image_array.append(image_url)
#             adding_face = main.add_face(url_image_array, file_name_only)

#             if not adding_face:
#                 url_image_array.remove(image_url)
#                 main.add_face(url_image_array, file_name_only)

#         if adding_face:
#             face_id = insert_image_db(id_pegawai, name, image_url)
#             # Hapus gambar duplikat
#             seen = set()
#             for row in Biometrik.objects.all():
#                 if row.image in seen:
#                     row.delete()
#                 else:
#                     seen.add(row.image)
#             response = {'status': 1, 'message': "Berhasil", "face_id": face_id}
#         else:
#             response = {'status': 0, 'message': "Gagal"}

#         print(response)
#         return JsonResponse(response)
    
# from django.utils import timezone
# current_time = timezone.now()
# def insert_image_db(id_pegawai,name,url_image):
#     pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
#     biometrik = Biometrik.objects.create(
#         id_pegawai = pegawai,  # <- ini adalah objek Pegawai, bukan string
#         name = name,
#         image = url_image
#     )
#     id_biometrik = biometrik.id
#     face_id = f"{pegawai.id_pegawai}.{id_biometrik}"
#     # update image
#     Biometrik.objects.filter(id=id_biometrik).update(
#         face_id=face_id
#     )
#     return face_id

@csrf_exempt
def add_image(request):
    import json
    
    time.sleep(3)
    if request.method == 'POST':
        id_pegawai = request.POST['id_pegawai']
        name = request.POST['name']
        image_file = request.FILES.get('image')

        if not image_file:
            return HttpResponseServerError("Memerlukan File Gambar")

        # Simpan file ke folder media/biometrik/<id_pegawai>/
        folder_path = os.path.join('biometrik', str(id_pegawai))
        file_name = f"{int(time.time())}_{image_file.name}"
        saved_path = default_storage.save(os.path.join(folder_path, file_name), ContentFile(image_file.read()))
        image_url = request.build_absolute_uri(os.path.join(settings.MEDIA_URL, saved_path))

        biometrik = Biometrik.objects.filter(id_pegawai=id_pegawai)

        if biometrik.count() == 0:
            # Jika belum ada data biometrik untuk pegawai ini
            url_image_array = [image_url]
        else:
            # Jika sudah ada, gabungkan dengan gambar yang sudah ada
            url_image_array = [b.image for b in biometrik]
            url_image_array.append(image_url)

        # PERBAIKAN: Panggil add_face dengan 1 parameter saja
        face_vector = main.add_face(url_image_array)

        if face_vector:  # Jika berhasil extract face vector
            # Simpan ke database
            face_id = insert_image_db(id_pegawai, name, image_url, face_vector)
            
            # Hapus gambar duplikat
            seen = set()
            for row in Biometrik.objects.all():
                if row.image in seen:
                    row.delete()
                else:
                    seen.add(row.image)
                    
            response = {'status': 1, 'message': "Berhasil", "face_id": face_id}
        else:
            # Jika gagal extract face vector
            if biometrik.count() > 0:
                # Jika sudah ada data sebelumnya, coba proses ulang tanpa gambar baru
                url_image_array_fallback = [b.image for b in biometrik]
                fallback_vector = main.add_face(url_image_array_fallback)
                
                if fallback_vector:
                    # Update dengan face vector dari gambar lama
                    face_vector_json = json.dumps(fallback_vector)
                    Biometrik.objects.filter(id_pegawai=id_pegawai).update(
                        face_vector=face_vector_json
                    )
                    
            # Tetap simpan gambar tapi tanpa face vector
            face_id = insert_image_db(id_pegawai, name, image_url, None)
            response = {'status': 0, 'message': "Gagal extract face vector", "face_id": face_id}

        print(response)
        return JsonResponse(response)

def insert_image_db(id_pegawai, name, url_image, face_vector=None):
    from .models import Biometrik, Pegawai
    import json
    
    # Konversi face_vector ke JSON string jika ada
    face_vector_json = json.dumps(face_vector) if face_vector else ''
    
    try:
        # Ambil instance Pegawai dari id
        pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
    except Pegawai.DoesNotExist:
        return None

    # Insert image dengan face_vector
    insert_biometrik = Biometrik.objects.create(
        id_pegawai=pegawai,
        name=name,
        image=url_image,
        face_vector=face_vector_json  # Simpan face vector di sini
    )
    insert_biometrik.save()
    
    id_biometrik = insert_biometrik.id
    face_id = str(id_pegawai) + "." + str(id_biometrik)
    
    # Update dengan face_id
    Biometrik.objects.filter(id=id_biometrik).update(
        face_id=face_id
    )
    
    return face_id

# simpan vector ke tabel pegawai (ini dari mobile)
def upload_and_process_photo(request):
    import json
    import os
    
    if request.method == 'POST':
        id_pegawai = request.POST.get('id_pegawai')
        name = request.POST.get('name', '')
        image_file = request.FILES.get('image')

        if not image_file or not id_pegawai:
            return JsonResponse({
                'status': 0, 
                'message': "ID Pegawai dan file gambar diperlukan"
            })

        try:
            # 1. SIMPAN FILE
            folder_path = os.path.join('huffman_images_vector', str(id_pegawai))
            file_name = f"{int(time.time())}_{image_file.name}"
            saved_path = default_storage.save(
                os.path.join(folder_path, file_name), 
                ContentFile(image_file.read())
            )
            
            # 2. CONVERT KE ABSOLUTE PATH
            absolute_path = os.path.join(settings.MEDIA_ROOT, saved_path)
            print(f"📁 File tersimpan di: {absolute_path}")
            
            # 3. KUMPULKAN SEMUA PATH FOTO PEGAWAI INI
            image_paths_list = [absolute_path]
            
            # Cari foto lama jika ada
            try:
                pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
                if pegawai.foto:
                    old_absolute_path = os.path.join(settings.MEDIA_ROOT, str(pegawai.foto))
                    if os.path.exists(old_absolute_path) and old_absolute_path != absolute_path:
                        image_paths_list.insert(0, old_absolute_path)
            except Pegawai.DoesNotExist:
                pass
            
            print(f"📸 Total gambar untuk diproses: {len(image_paths_list)}")
            
            # 4. EXTRACT FACE VECTOR LANGSUNG
            face_vector = main.add_face_from_local_path(image_paths_list)
            
            if face_vector:
                # 5. SIMPAN KE TABEL PEGAWAI KOLOM FACE_VECTOR
                face_vector_json = json.dumps(face_vector)
                
                try:
                    # Update pegawai yang sudah ada
                    pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
                    pegawai.foto = saved_path
                    pegawai.face_vector = face_vector_json  # SIMPAN DI KOLOM FACE_VECTOR
                    if name:
                        pegawai.name = name
                    pegawai.save()
                    
                    print(f"✅ Face vector berhasil diupdate untuk pegawai {id_pegawai}")
                    
                except Pegawai.DoesNotExist:
                    # Buat pegawai baru
                    pegawai = Pegawai.objects.create(
                        id_pegawai=id_pegawai,
                        name=name,
                        foto=saved_path,
                        face_vector=face_vector_json  # SIMPAN DI KOLOM FACE_VECTOR
                    )
                    
                    print(f"✅ Pegawai baru dibuat dengan face vector: {id_pegawai}")
                
                response = {
                    'status': 1,
                    'message': 'Foto berhasil diupload dan face vector tersimpan di database!',
                    'filename': file_name,
                    'vector_length': len(face_vector),
                    'id_pegawai': id_pegawai,
                    'saved_to': 'tabel_pegawai.face_vector'
                }
                
            else:
                # Gagal extract face vector, tetap simpan foto tanpa face_vector
                try:
                    pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
                    pegawai.foto = saved_path
                    if name:
                        pegawai.name = name
                    pegawai.save()
                except Pegawai.DoesNotExist:
                    pegawai = Pegawai.objects.create(
                        id_pegawai=id_pegawai,
                        name=name,
                        foto=saved_path,
                        face_vector=None  # NULL karena gagal extract
                    )
                
                response = {
                    'status': 0,
                    'message': 'Foto tersimpan tapi gagal extract face vector',
                    'filename': file_name,
                    'id_pegawai': id_pegawai,
                    'face_detected': False
                }
            
            print(f"📝 Response: {response}")
            return JsonResponse(response)
            
        except Exception as e:
            print(f"🚨 Error: {str(e)}")
            return JsonResponse({
                'status': 0,
                'message': f'Error processing: {str(e)}'
            })



@csrf_exempt
def edit_image(request):
    time.sleep(3)
    face_id = request.POST['face_id']
    url_image = request.POST['url_image']
    name = request.POST['name']

    biometrik = Biometrik.objects.filter(face_id=face_id)
    if(biometrik.count()==0):
        response = {'status':2,'message':"Gagal. Data Face_id Tidak Ditemukan."}
    else:
        id_pegawai = str(biometrik[0].id_pegawai)
        file_name = str(id_pegawai)
        biometrik_new = Biometrik.objects.filter(id_pegawai=id_pegawai).exclude(face_id=face_id)
        url_image_array = []
        if(biometrik_new.count()>0):
            for data_bio in biometrik_new:
                url_image_array.append(data_bio.image)
            url_image_array.append(url_image)
        else:
           url_image_array.append(url_image) 
        adding_face = main.add_face(url_image_array,file_name)

        if(adding_face==False):
            url_image_array = []
            biometrik_new2 = Biometrik.objects.filter(id_pegawai=id_pegawai)
    
            if(biometrik_new2.count()>0):
                for data_bio in biometrik_new2:
                    url_image_array.append(data_bio.image)
                # print(url_image_array)
                main.add_face(url_image_array,file_name)

        if(adding_face):
            face_id = update_image_db(face_id,name,url_image)
            response = {'status':1,'message':"Berhasil","face_id":face_id}
        else:
            response = {'status':0,'message':"Gagal"}
    print(response)
    return JsonResponse(response) 

def update_image_db(face_id,name,url_image):
    biometrik = Biometrik.objects.filter(face_id=face_id)
    biometrik.update(name=name,image=url_image)
    return biometrik[0].face_id

@csrf_exempt
def hapus_image(request):
    time.sleep(3)
    face_id = request.POST['face_id']
    biometrik = Biometrik.objects.filter(face_id=face_id)
    if(biometrik.count()>0):
        id_pegawai = str(biometrik[0].id_pegawai)

        # hapus db
        delete = biometrik.delete()

        # cek biometrik ada berapa
        biometrik_new = Biometrik.objects.filter(id_pegawai=id_pegawai)
        if(biometrik_new.count()==0):
            if(os.path.exists(path_dataset+id_pegawai+'.txt')):
                os.remove(path_dataset+id_pegawai+'.txt')
        else:
            url_image_array = []
            for data_bio in biometrik_new:
                url_image_array.append(data_bio.image)
            file_name = str(id_pegawai)
            adding_face = main.add_face(url_image_array,file_name)

        if(delete):
            response = {'status':1,'message':"Berhasil."}
        else:
            response = {'status':0,'message':"Gagal."}
    else:
        response = {'status':0,'message':"Gagal. face_id tidak ditemukan"}
    print(response)
    return JsonResponse(response) 

@csrf_exempt
def verify_image(request):
    if request.method != 'POST':
        return HttpResponseServerError("Invalid request method")

    id_pegawai = request.POST.get('id_pegawai')
    image_file = request.FILES.get('image')

    if not id_pegawai or not image_file:
        return HttpResponseServerError("Missing id_pegawai or image file")

    biometrik = Biometrik.objects.filter(id_pegawai=id_pegawai)

    if not biometrik.exists():
        return JsonResponse({'status': 0, 'message': "Id Pegawai Tidak ditemukan."})

    # Simpan gambar ke folder verification/<id_pegawai>/
    folder_path = os.path.join('verification', str(id_pegawai))
    file_name = f"{int(time.time())}_{image_file.name}"
    saved_path = default_storage.save(os.path.join(folder_path, file_name), ContentFile(image_file.read()))
    image_url = request.build_absolute_uri(os.path.join(settings.MEDIA_URL, saved_path))

    try:
        # Gunakan image_path sebagai input ke verify_face
        cek_image = main.verify_face(image_url, id_pegawai)

        if cek_image:
            response = {'status': 1, 'message': "Cocok."}
        else:
            response = {'status': 0, 'message': "Tidak Cocok."}

    finally:
        # Hapus gambar setelah proses selesai
        if os.path.exists(image_url):
            os.remove(image_url)

    print(response)
    return JsonResponse(response)


    



@csrf_exempt
def upload_profile_photo(request):
    if request.method == 'POST':
        try:
            id_pegawai = request.POST.get('id_pegawai')
            profile_image = request.FILES.get('profile_image')
            
            if not id_pegawai or not profile_image:
                return JsonResponse({
                    'status': 'error',
                    'message': 'id_pegawai dan profile_image harus diisi'
                }, status=400)
            
            # Validasi file
            allowed_extensions = ['.jpg', '.jpeg', '.png']
            file_extension = os.path.splitext(profile_image.name)[1].lower()
            
            if file_extension not in allowed_extensions:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Format file tidak didukung. Gunakan JPG, JPEG, atau PNG'
                }, status=400)
            
            # Batasi ukuran file (max 5MB)
            if profile_image.size > 5 * 1024 * 1024:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Ukuran file maksimal 5MB'
                }, status=400)
            
            # HAPUS FOTO LAMA TERLEBIH DAHULU
            with connection.cursor() as cursor:
                cursor.execute("SELECT image FROM pegawai WHERE id_pegawai = %s", [id_pegawai])
                result = cursor.fetchone()
                
                if result and result[0]:
                    old_file_path = os.path.join(settings.MEDIA_ROOT, result[0])
                    if os.path.exists(old_file_path):
                        try:
                            os.remove(old_file_path)
                            print(f"✅ Foto lama berhasil dihapus: {old_file_path}")
                        except Exception as e:
                            print(f"⚠️ Gagal hapus foto lama: {e}")
            
            # Buat nama file unik (REPLACE, bukan tambah)
            timestamp = int(time.time())
            file_name = f"profile_{id_pegawai}_{timestamp}{file_extension}"
            
            # Simpan file ke folder profile
            folder_path = os.path.join('profile', str(id_pegawai))
            file_path = os.path.join(folder_path, file_name)
            
            # Simpan file baru
            saved_path = default_storage.save(file_path, ContentFile(profile_image.read()))
            
            # Update kolom IMAGE di database (REPLACE)
            with connection.cursor() as cursor:
                cursor.execute("""
                    UPDATE pegawai 
                    SET image = %s
                    WHERE id_pegawai = %s
                """, [saved_path, id_pegawai])
                
                # Verifikasi update berhasil
                cursor.execute("SELECT ROW_COUNT()")
                affected_rows = cursor.fetchone()[0]
                
                if affected_rows == 0:
                    return JsonResponse({
                        'status': 'error',
                        'message': 'Pegawai tidak ditemukan'
                    }, status=404)
            
            # URL foto untuk response
            photo_url = request.build_absolute_uri(os.path.join(settings.MEDIA_URL, saved_path))
            
            return JsonResponse({
                'status': 'success',
                'message': 'Foto profil berhasil diupdate',
                'data': {
                    'foto_url': photo_url,
                    'file_path': saved_path
                }
            })
            
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': f'Error: {str(e)}'
            }, status=500)
    
    return JsonResponse({
        'status': 'error',
        'message': 'Method tidak diizinkan'
    }, status=405)

@csrf_exempt
def get_profile_photo(request, id_pegawai):
    if request.method == 'GET':
        try:
            with connection.cursor() as cursor:
                # Ambil dari kolom IMAGE yang sudah ada
                cursor.execute("SELECT image FROM pegawai WHERE id_pegawai = %s", [id_pegawai])
                result = cursor.fetchone()
                
                if result and result[0]:
                    # Cek apakah file benar-benar ada
                    file_path = os.path.join(settings.MEDIA_ROOT, result[0])
                    if os.path.exists(file_path):
                        photo_url = request.build_absolute_uri(os.path.join(settings.MEDIA_URL, result[0]))
                        return JsonResponse({
                            'status': 'success',
                            'data': {
                                'foto_url': photo_url,
                                'has_photo': True
                            }
                        })
                    else:
                        # File tidak ada, hapus referensi di database
                        cursor.execute("UPDATE pegawai SET image = NULL WHERE id_pegawai = %s", [id_pegawai])
                        
                return JsonResponse({
                    'status': 'success',
                    'data': {
                        'foto_url': None,
                        'has_photo': False
                    }
                })
                    
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'status': 'error',
        'message': 'Method tidak diizinkan'
    }, status=405)

@csrf_exempt 
def delete_profile_photo(request, id_pegawai):
    """Endpoint untuk hapus foto profil"""
    if request.method == 'DELETE':
        try:
            with connection.cursor() as cursor:
                # Ambil path foto lama
                cursor.execute("SELECT image FROM pegawai WHERE id_pegawai = %s", [id_pegawai])
                result = cursor.fetchone()
                
                if result and result[0]:
                    # Hapus file fisik
                    old_file_path = os.path.join(settings.MEDIA_ROOT, result[0])
                    if os.path.exists(old_file_path):
                        os.remove(old_file_path)
                    
                    # Hapus referensi di database
                    cursor.execute("UPDATE pegawai SET image = NULL WHERE id_pegawai = %s", [id_pegawai])
                    
                    return JsonResponse({
                        'status': 'success',
                        'message': 'Foto profil berhasil dihapus'
                    })
                else:
                    return JsonResponse({
                        'status': 'error',
                        'message': 'Foto profil tidak ditemukan'
                    }, status=404)
                    
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'status': 'error',
        'message': 'Method tidak diizinkan'
    }, status=405)




@csrf_exempt
def compare_biometrik_with_huffman(id_pegawai, request):
    """
    Membandingkan gambar di folder /biometrik dengan gambar di folder /huffman_images
    tanpa mengubah sistem face recognition yang sudah ada.
    
    Args:
        id_pegawai (str): ID pegawai yang akan diverifikasi
        
    Returns:
        bool: True jika wajah cocok, False jika tidak cocok
    """
    import os
    import shutil
    import tempfile
    from django.conf import settings
    import time
    
    # Import face recognition system yang sudah ada
    from .face_recognition import main  # Sesuaikan dengan struktur import Anda
    
    # 1. Path ke file gambar di folder biometrik dan huffman_images
    biometrik_path = os.path.join(settings.MEDIA_ROOT, 'biometrik', str(id_pegawai))  # Sesuaikan ekstensi file
    huffman_path = os.path.join(settings.MEDIA_ROOT, 'huffman_images', str(id_pegawai))  # Sesuaikan ekstensi file
    
    # Periksa apakah kedua file ada
    if not os.path.exists(biometrik_path):
        raise FileNotFoundError(f"Biometrik image not found for ID: {id_pegawai}")
    
    if not os.path.exists(huffman_path):
        raise FileNotFoundError(f"Huffman decoded image not found for ID: {id_pegawai}")
    
    biometrik_files = [f for f in os.listdir(biometrik_path) if os.path.isfile(os.path.join(biometrik_path, f)) and 
                      (f.lower().endswith('.jpg') or f.lower().endswith('.png') or f.lower().endswith('.jpeg'))]
    
    if not biometrik_files:
        raise FileNotFoundError(f"No biometric image files found in directory for ID: {id_pegawai}")
    
    # Cari file gambar hasil dekompresi Huffman
    huffman_files = [f for f in os.listdir(huffman_path) if os.path.isfile(os.path.join(huffman_path, f)) and 
                     (f.lower().endswith('.jpg') or f.lower().endswith('.png') or f.lower().endswith('.jpeg'))]
    
    if not huffman_files:
        raise FileNotFoundError(f"No Huffman decoded image files found in directory for ID: {id_pegawai}")
    
    # Gunakan file pertama yang ditemukan (atau Anda bisa menambahkan logika untuk memilih file tertentu)
    biometrik_path = os.path.join(biometrik_path, biometrik_files[0])
    huffman_path = os.path.join(huffman_path, huffman_files[0])
    print(f"Biometrik path: {biometrik_path}")
    print(f"Huffman path: {huffman_path}")

    # 2. Siapkan file gambar Huffman di lokasi temporary yang bisa dibaca oleh sistem face recognition
    # Buat direktori verification/<id_pegawai>/ jika belum ada
    verification_path = os.path.join(settings.MEDIA_ROOT, 'verification', str(id_pegawai))
    os.makedirs(verification_path, exist_ok=True)
    
    # Salin gambar Huffman ke direktori verification dengan nama unik (timestamp)
    timestamp = int(time.time())
    verification_filename = f"{timestamp}_huffman_verify.png"  # Gunakan ekstensi yang sama dengan gambar Huffman
    verification_path = os.path.join(verification_path, verification_filename)
    
    # Salin file
    shutil.copy2(huffman_path, verification_path)
    
    print(f"Biometrik path: {biometrik_path}")
    print(f"Huffman path: {huffman_path}")
    print(f"Verification path: {verification_path}")

    try:        # Buat URL relatif media
        if os.path.exists(verification_path):
            print(f"Verification file exists at: {verification_path}")
        else:
            print(f"Verification file DOES NOT exist at: {verification_path}")

        
        media_url_path = os.path.join(settings.MEDIA_URL.strip('/'), relative_path.replace('\\', '/'))
        if not media_url_path.startswith('/'):
            media_url_path = '/' + media_url_path
        
        # Buat URL absolut
        absolute_url = request.build_absolute_uri(media_url_path)

        print(f"Absolute URL: {absolute_url}")
        
        # Panggil verify_face dengan URL absolut
        is_match = main.verify_face(absolute_url, id_pegawai)
        
        return is_match
    except Exception as e:
        print(f"Verification error: {e}")
        raise
    finally:
        # Tidak perlu menghapus file untuk debugging
        pass

@csrf_exempt  
def verify_huffman_biometrik(request):
    """
    Endpoint untuk memverifikasi wajah dari gambar hasil dekompresi Huffman dengan data biometrik
    """
    if request.method != 'POST':
        return HttpResponseBadRequest("Invalid request method")
    
    try:
        # Ambil data dari request
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            # Jika bukan JSON, anggap sebagai form data
            data = request.POST
        
        id_pegawai = data.get('id_pegawai')
        
        if not id_pegawai:
            return JsonResponse({'status': 0, 'message': "ID Pegawai diperlukan"})
        
        # Periksa apakah ID Pegawai ada di database
        biometrik = Biometrik.objects.filter(id_pegawai=id_pegawai)
        if not biometrik.exists():
            return JsonResponse({'status': 0, 'message': "ID Pegawai tidak ditemukan"})
        
        # Lakukan verifikasi menggunakan fungsi baru yang tidak mengubah sistem yang sudah ada
        is_match = compare_biometrik_with_huffman(id_pegawai, request)
        
        if is_match:
            response = {'status': 1, 'message': "Cocok."}
        else:
            response = {'status': 0, 'message': "Tidak Cocok."}
        
    except FileNotFoundError as e:
        response = {'status': 0, 'message': f"File tidak ditemukan: {str(e)}"}
    except Exception as e:
        import traceback
        traceback.print_exc()
        response = {'status': 0, 'message': f"Error: {str(e)}"}
    
    print(response)
    return JsonResponse(response)



from sipreti.face_recognition.main import add_face_local

@csrf_exempt
def process_face_view(request):
    """
    View Django untuk membuat vektor wajah dari gambar hasil dekompresi
    dengan fokus pada konversi gambar grayscale menjadi RGB
    """
    if request.method != 'POST':
        return JsonResponse({"success": False, "message": "Hanya metode POST yang diizinkan"}, status=405)
    
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"success": False, "message": "Format JSON tidak valid"}, status=400)
    
    # Ambil ID pegawai
    id_pegawai = data.get('id_pegawai')
    if not id_pegawai:
        return JsonResponse({"success": False, "message": "ID pegawai diperlukan"}, status=400)
    
    # Path ke folder gambar hasil dekompresi
    huffman_folder = os.path.join(settings.MEDIA_ROOT, 'huffman_images', id_pegawai)
    
    if not os.path.exists(huffman_folder):
        return JsonResponse({
            "success": False, 
            "message": f"Folder {huffman_folder} tidak ditemukan"
        }, status=404)
    
    image_paths = []  # Ganti dari image_urls ke image_paths
    colorized_files = []
    
    # Proses gambar: cek dan konversi ke RGB jika perlu
    for filename in os.listdir(huffman_folder):
        # Hanya proses file gambar asli (bukan hasil konversi sebelumnya)
        if filename.lower().endswith(('.jpg', '.jpeg', '.png')) and not filename.startswith(('rgb_', 'color_')):
            try:
                # Path gambar asli
                image_path = os.path.join(huffman_folder, filename)
                print(f"Memeriksa gambar: {image_path}")
                
                # Baca gambar
                img = cv2.imread(image_path)
                
                if img is None:
                    print(f"Gagal membaca gambar: {image_path}")
                    continue
                
                # Cek apakah gambar adalah grayscale (semua channel RGB sama)
                is_grayscale = True
                # Sampel beberapa piksel untuk efisiensi
                height, width = img.shape[:2]
                num_samples = min(100, height * width)
                
                for _ in range(num_samples):
                    y = np.random.randint(0, height)
                    x = np.random.randint(0, width)
                    pixel = img[y, x]
                    
                    # Jika channel RGB berbeda, gambar berwarna
                    if not (pixel[0] == pixel[1] == pixel[2]):
                        is_grayscale = False
                        break
                
                # Jika gambar grayscale, buat versi RGB dengan warna
                if is_grayscale:
                    print(f"Gambar {filename} terdeteksi sebagai grayscale, mengkonversi ke RGB dengan warna...")
                    
                    # Konversi ke grayscale yang sebenarnya
                    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
                    
                    # Tingkatkan kontras
                    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
                    enhanced_gray = clahe.apply(gray)
                    
                    # 1. Buat versi berwarna dengan colormap
                    colored_img = cv2.applyColorMap(enhanced_gray, cv2.COLORMAP_BONE)
                    color_filename = f"color_{filename}"
                    color_path = os.path.join(huffman_folder, color_filename)
                    cv2.imwrite(color_path, colored_img)
                    print(f"Gambar berwarna (colormap) disimpan di: {color_path}")
                    colorized_files.append(color_filename)
                    
                    # 2. Tambahkan URL gambar berwarna
                    color_path = request.build_absolute_uri(f"{settings.MEDIA_URL}huffman_images/{id_pegawai}/{color_filename}")
                    image_paths.append(color_path)
                
                # Selalu tambahkan URL gambar asli
                original_path = request.build_absolute_uri(f"{settings.MEDIA_URL}huffman_images/{id_pegawai}/{filename}")
                image_path.append(image_path)
                
            except Exception as e:
                print(f"Error memproses gambar {filename}: {str(e)}")
    
    # Tambahkan semua gambar berwarna yang sudah ada sebelumnya
    for filename in os.listdir(huffman_folder):
        if filename.startswith('color_') and filename not in colorized_files:
            color_path = request.build_absolute_uri(f"{settings.MEDIA_URL}huffman_images/{id_pegawai}/{filename}")
            if color_path not in image_path:
                image_path.append(color_path)
    
    if not image_path:
        return JsonResponse({
            "success": False,
            "message": "Tidak ada gambar yang ditemukan"
        }, status=404)

    # Debug: Periksa apakah gambar sudah RGB
    print("============= MEMERIKSA FORMAT GAMBAR =============")
    image_formats = []
    
    for filename in os.listdir(huffman_folder):
        if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
            image_path = os.path.join(huffman_folder, filename)
            
            try:
                # Baca gambar
                img = cv2.imread(image_path)
                
                if img is None:
                    print(f"Gagal membaca gambar: {image_path}")
                    continue
                
                # Dapatkan informasi dasar
                height, width = img.shape[:2]
                channels = 1 if len(img.shape) == 2 else img.shape[2]
                
                # Periksa apakah gambar efektif grayscale (semua channel RGB sama)
                is_effectively_grayscale = True
                
                if channels >= 3:
                    # Sampel beberapa piksel
                    num_samples = min(20, height * width)
                    for _ in range(num_samples):
                        y = np.random.randint(0, height)
                        x = np.random.randint(0, width)
                        pixel = img[y, x]
                        if not (pixel[0] == pixel[1] == pixel[2]):
                            is_effectively_grayscale = False
                            break
                
                # Ambil contoh beberapa piksel
                sample_pixels = []
                sample_points = [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1), (width//2, height//2)]
                
                for x, y in sample_points:
                    pixel = img[y, x]
                    if channels >= 3:
                        pixel_info = f"({x},{y}): B={pixel[0]}, G={pixel[1]}, R={pixel[2]}"
                    else:
                        pixel_info = f"({x},{y}): Val={pixel}"
                    sample_pixels.append(pixel_info)
                
                # Tambahkan ke daftar format
                image_formats.append({
                    "filename": filename,
                    "dimensions": f"{width}x{height}",
                    "channels": channels,
                    "format": "RGB" if channels >= 3 else "Grayscale",
                    "is_effectively_grayscale": is_effectively_grayscale,
                    "sample_pixels": sample_pixels[:2]  # batasi output untuk kejelasan
                })
                
            except Exception as e:
                print(f"Error checking image {filename}: {str(e)}")
    
    # Cetak hasil
    print(json.dumps(image_formats, indent=2))
    
    # Hitung statistik
    rgb_count = sum(1 for info in image_formats if info.get("format") == "RGB" and not info.get("is_effectively_grayscale"))
    grayscale_count = sum(1 for info in image_formats if info.get("format") == "Grayscale" or info.get("is_effectively_grayscale"))
    colormap_count = sum(1 for info in image_formats if info.get("filename").startswith("color_"))
    
    print(f"TOTAL GAMBAR: {len(image_formats)}")
    print(f"GAMBAR RGB MURNI: {rgb_count}")
    print(f"GAMBAR GRAYSCALE: {grayscale_count}")
    print(f"GAMBAR COLORMAP: {colormap_count}")
    print("===================================================")
    
    try:
        # UBAH: Gunakan fungsi add_face_local dengan PATH bukan URL
        print(f"🔄 Memproses {len(image_paths)} gambar dengan add_face_local...")
        face_vector = add_face_local(image_paths)  # Panggil function Anda
        
        if face_vector:
            # TAMBAHAN: Simpan ke database tabel pegawai
            import json
            face_vector_json = json.dumps(face_vector)
            
            try:
                # Update pegawai dengan face vector
                from .models import Pegawai  # Sesuaikan import
                
                pegawai, created = Pegawai.objects.get_or_create(
                    id_pegawai=id_pegawai,
                    defaults={'name': f'Pegawai {id_pegawai}'}  # Default name jika belum ada
                )
                
                pegawai.face_vector = face_vector_json
                pegawai.save()
                
                print(f"✅ Face vector berhasil disimpan ke database untuk pegawai {id_pegawai}")
                
                return JsonResponse({
                    "success": True,
                    "message": "Berhasil membuat dan menyimpan vektor wajah ke database!",
                    "id_pegawai": id_pegawai,
                    "vector_length": len(face_vector),
                    "image_count": len(image_paths),
                    "colorized_count": len(colorized_files),
                    "saved_to_database": True
                })
                
            except Exception as db_error:
                print(f"❌ Error simpan ke database: {str(db_error)}")
                
                # Tetap return success karena face vector berhasil dibuat
                return JsonResponse({
                    "success": True,
                    "message": f"Face vector berhasil dibuat tapi gagal simpan ke database: {str(db_error)}",
                    "vector_length": len(face_vector),
                    "image_count": len(image_paths),
                    "saved_to_database": False
                })
        else:
            return JsonResponse({
                "success": False,
                "message": "Gagal membuat vektor wajah dari gambar",
                "image_count": len(image_paths)
            })
            
    except Exception as e:
        print(f"🚨 Error dalam add_face_local: {str(e)}")
        return JsonResponse({
            "success": False,
            "message": f"Error: {str(e)}"
        }, status=500)

# digunakan untuk verifikasi setelah mendapatkan hasil decode
def auto_verify_after_enrollment(record_id, id_pegawai, image_path):
    """
    Function BARU untuk verify setelah enrollment - PANGGIL MAIN
    """
    try:
        print(f"🔄 Auto verify starting for record {record_id}")
        
        # PANGGIL verify_face di main
        import sipreti.face_recognition.main as main
        
        # Buat URL dari image path
        from django.conf import settings
        relative_path = os.path.relpath(image_path, settings.MEDIA_ROOT)
        image_url = f"http://localhost:8000{settings.MEDIA_URL}{relative_path.replace(os.sep, '/')}"
        
        print(f"🔄 Calling main.verify_face...")
        
        # PANGGIL VERIFY_FACE DI MAIN
        verify_result = main.verify_face(image_url, str(id_pegawai))
        
        print(f"📊 Main verify_face result: {verify_result}")
        
        return verify_result
        
    except Exception as e:
        print(f"❌ Auto verify error: {e}")
        return False
    
    
# ini create vektor yang dari mobile
def face_vector(id_pegawai, latest_image_path=None, mobile_timing=None):
    """
    Function simple untuk auto-create face vector - FIXED VERSION
    """
    import time
    start_time = time.time()

    try:
        import os
        import json
        from django.conf import settings
        from sipreti.face_recognition.main import add_face_local
        
        if mobile_timing:
            print(f"📱 Mobile timing received: {mobile_timing}")

        # Cari folder gambar
        huffman_folder = os.path.join(settings.MEDIA_ROOT, 'huffman_images', str(id_pegawai))
        
        if not os.path.exists(huffman_folder):
            return {"success": False, "message": "Folder tidak ditemukan"}
        
        # Kumpulkan gambar - PRIORITASKAN GAMBAR TERBARU
        image_paths = []
        if latest_image_path and os.path.exists(latest_image_path):
            image_paths = [latest_image_path]
            print(f"🎯 Using latest image: {os.path.basename(latest_image_path)}")
        else:
            # Ambil semua gambar dan urutkan berdasarkan waktu
            all_images = []
            for filename in os.listdir(huffman_folder):
                if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                    image_path = os.path.join(huffman_folder, filename)
                    mtime = os.path.getmtime(image_path)
                    all_images.append((mtime, image_path, filename))
            
            # Urutkan berdasarkan waktu terbaru
            all_images.sort(reverse=True)
            
            # Ambil maksimal 3 gambar terbaru untuk efisiensi
            image_paths = [img[1] for img in all_images[:3]]
            
            for _, _, filename in all_images[:3]:
                print(f"Found: {filename}")
        
        if not image_paths:
            return {"success": False, "message": "Tidak ada gambar"}
        
        # Buat face vector
        add_face_start = time.time()
        print(f"🔄 Creating face vector from {len(image_paths)} images...")
        face_vector_data = add_face_local(image_paths)
        add_face_time = time.time() - add_face_start
        
        # PERBAIKAN UTAMA: Cek dengan benar
        print(f"🔍 Received from add_face_local:")
        print(f"   Type: {type(face_vector_data)}")
        print(f"   Value: {face_vector_data}")
        print(f"   Is not False: {face_vector_data is not False}")
        print(f"   Is not None: {face_vector_data is not None}")
        
        # KONDISI YANG BENAR untuk mengecek face_vector_data
        if (face_vector_data is not None and 
            face_vector_data is not False and 
            len(face_vector_data) > 0):
            
            print(f"✅ Face vector data valid, length: {len(face_vector_data)}")
            db_save_start = time.time()
            # Simpan ke database
            from .models import KompresiHuffman

            # SELALU BUAT RECORD BARU (TIDAK PERNAH UPDATE)
            from django.utils import timezone

            record = KompresiHuffman.objects.create(
                id_pegawai=str(id_pegawai),   
                width=0,
                height=0,
                frequency_model="{}",  # FIX: STRING
                code_table="{}",       # FIX: STRING
                compressed_file=b'',
                face_vector=json.dumps(face_vector_data),
                created_at=timezone.now()  # FIX: TIMEZONE
            ) 
            db_save_time = time.time() - db_save_start

            print(f"✅ Created NEW record: {id_pegawai}")
            print(f"   Record ID: {record.id}")

            # Hitung total untuk user asli
            total_count = KompresiHuffman.objects.filter(
                id_pegawai__startswith=f"{id_pegawai}_"
            ).count()

            print(f"📊 Total records for user {id_pegawai}: {total_count}")

            verify_start = time.time()
            print(f"🔄 Calling auto verify function...")

            # PANGGIL FUNCTION BARU
            verify_result = auto_verify_after_enrollment(record.id, str(id_pegawai), image_paths[0])
            verify_time = time.time() - verify_start

            verification_status = "✅ VERIFIED" if verify_result else "❌ FAILED"

            total_face_time = time.time() - start_time
            
            # ✅ BUAT TIMING SUMMARY
            server_timing = {
                'add_face_ms': round(add_face_time * 1000),
                'db_save_ms': round(db_save_time * 1000),
                'verify_ms': round(verify_time * 1000),
                'total_face_ms': round(total_face_time * 1000)
            }
            
            print(f"⏱️ Face processing timing: {server_timing}")
            
            # ✅ SIMPAN TIMING LOG (OPSIONAL)
            if mobile_timing:
                try:
                    save_timing_to_db(id_pegawai, mobile_timing, server_timing, verify_result)
                except Exception as e:
                    print(f"⚠️ Failed to save timing log: {e}")

            return {
                "success": True, 
                "message": f"Face vector saved! {verification_status}", 
                "auto_verification": verify_result,
                "timing": {
                    "mobile": mobile_timing,
                    "server": server_timing
                },
                "kompresi_id": record.id
            }
        else:
            total_time = time.time() - start_time
            print(f"❌ Face vector creation failed after {total_time:.3f}s")
            return {"success": False, "message": "Failed to create face vector"}
                  
    except Exception as e:
        import traceback
        print(f"❌ Error: {str(e)}")
        traceback.print_exc()
        return {"success": False, "message": str(e)}

# MENYIMPAN HASIL WAKTUNYA
def save_timing_to_db(id_pegawai, mobile_timing, server_timing, verify_result, euclidean_distance=None, 
                      original_size=None, compressed_size=None):
    """Simpan timing data ke database"""
    try:
        from .models import TimingLog
        
        timing_log = TimingLog.objects.create(
            id_pegawai=id_pegawai,
            
            # Mobile timing
            mobile_capture=mobile_timing.get('capture_time'),
            mobile_huffman=mobile_timing.get('huffman_time'),
            mobile_sending=mobile_timing.get('sending_time'),
            mobile_total=mobile_timing.get('total_mobile_time'),
            
            # Server timing
            server_decode=server_timing.get('decode_time_ms'),
            server_add_face=server_timing.get('add_face_ms'),
            server_verify=server_timing.get('verify_ms'),
            server_total=server_timing.get('total_face_ms'),
            
            # Quality
            euclidean_distance=euclidean_distance,
            verification_success=verify_result,
            
            # File info
            original_size_bytes=original_size,
            compressed_size_bytes=compressed_size,
        )
        
        print(f"✅ Timing data saved with ID: {timing_log.id_timing}")
        return timing_log.id_timing
        
    except Exception as e:
        print(f"❌ Failed to save timing: {e}")
        import traceback
        traceback.print_exc()
        return None


@csrf_exempt 
def get_timing_stats(request):
    """API untuk statistik timing"""
    from .models import TimingLog 
    try:
        id_pegawai = request.GET.get('id_pegawai')
        
        if id_pegawai:
            logs = TimingLog.objects.filter(id_pegawai=id_pegawai)
        else:
            logs = TimingLog.objects.all()
        
        if not logs.exists():
            return JsonResponse({'error': 'No timing data found'}, status=404)
        
        from django.db.models import Avg
        # Hitung rata-rata
        total_logs = logs.count()
        avg_mobile = logs.aggregate(avg=Avg('mobile_total'))['avg'] or 0
        avg_server = logs.aggregate(avg=Avg('server_total'))['avg'] or 0
        success_count = logs.filter(verification_success=True).count()
        
        return JsonResponse({
            'status': 'success',
            'stats': {
                'total_requests': total_logs,
                'avg_mobile_time_ms': round(avg_mobile, 2),
                'avg_server_time_ms': round(avg_server, 2),
                'avg_total_time_ms': round(avg_mobile + avg_server, 2),
                'success_rate': round((success_count / total_logs) * 100, 2) if total_logs > 0 else 0
            }
        })
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
        

# FUNGSI HELPER untuk mengakses vectors yang sudah terkumpul
def get_accumulated_vectors(id_pegawai):
    """
    Fungsi untuk mengambil semua vectors yang sudah terkumpul untuk user
    """
    try:
        from .models import KompresiHuffman
        import json
        
        record = KompresiHuffman.objects.get(id_pegawai=str(id_pegawai))
        
        if record.face_vector:
            vector_data = json.loads(record.face_vector)
            
            # Jika format baru (accumulative)
            if isinstance(vector_data, dict) and 'vectors' in vector_data:
                return {
                    "success": True,
                    "total_vectors": vector_data['count'],
                    "vectors": vector_data['vectors'],
                    "timestamps": vector_data['timestamps'],
                    "image_files": vector_data['image_files'],
                    "latest_vector": vector_data['vectors'][-1] if vector_data['vectors'] else None
                }
            # Jika format lama (single vector)
            elif isinstance(vector_data, list):
                return {
                    "success": True,
                    "total_vectors": 1,
                    "vectors": [vector_data],
                    "timestamps": ["unknown"],
                    "image_files": ["legacy"],
                    "latest_vector": vector_data
                }
        
        return {"success": False, "message": "No vectors found"}
        
    except Exception as e:
        return {"success": False, "message": str(e)}


def get_average_vector(id_pegawai):
    """
    Fungsi untuk menghitung rata-rata dari semua vectors
    """
    try:
        import numpy as np
        
        vectors_data = get_accumulated_vectors(id_pegawai)
        
        if vectors_data["success"] and vectors_data["total_vectors"] > 0:
            vectors = vectors_data["vectors"]
            
            # Hitung rata-rata
            average_vector = np.mean(vectors, axis=0).tolist()
            
            return {
                "success": True,
                "average_vector": average_vector,
                "based_on_vectors": len(vectors),
                "vector_length": len(average_vector)
            }
        else:
            return {"success": False, "message": "No vectors to average"}
            
    except Exception as e:
        return {"success": False, "message": str(e)}









def rle_decode_rgb(encoded_tuples, shape):
    """
    Decode RLE tuples menjadi array 3D RGB
    """
    height, width = shape
    decoded = []
    
    # Decode RLE untuk RGB
    for rgb_values, count in encoded_tuples:
        # rgb_values adalah [R, G, B]
        for _ in range(count):
            decoded.append(rgb_values)
    
    # Konversi ke numpy array
    decoded_array = np.array(decoded, dtype=np.uint8)
    
    # Validasi ukuran
    expected_size = height * width
    if len(decoded_array) != expected_size:
        raise ValueError(f"Decoded data size ({len(decoded_array)}) doesn't match expected size ({expected_size})")
    
    # Reshape ke bentuk gambar RGB (height, width, 3)
    return decoded_array.reshape(height, width, 3)

def rle_decode_grayscale(encoded_tuples, shape):
    """
    Decode RLE tuples menjadi array 2D grayscale (untuk backward compatibility)
    """
    height, width = shape
    decoded = []
    
    for value, count in encoded_tuples:
        decoded.extend([value] * count)
    
    decoded_array = np.array(decoded, dtype=np.uint8)
    
    expected_size = height * width
    if len(decoded_array) != expected_size:
        raise ValueError(f"Decoded data size ({len(decoded_array)}) doesn't match expected size ({expected_size})")
    
    return decoded_array.reshape(height, width)

@csrf_exempt
def rle_decode_image(request):
    if request.method != 'POST':
        return HttpResponseServerError("Invalid request method")

    try:
        # Parse JSON body
        body_unicode = request.body.decode('utf-8')
        body_data = json.loads(body_unicode)

        id_pegawai = body_data.get('id_pegawai')
        if not id_pegawai:
            return HttpResponseBadRequest("Missing id_pegawai field")
        
        compressed_b64 = body_data.get('compressed_data')
        shape = body_data.get('shape')
        channels = body_data.get('channels', 1)  # Default 1 untuk grayscale
        mode = body_data.get('mode', 'grayscale')  # Default grayscale

        if not compressed_b64 or not shape:
            return HttpResponseBadRequest("Missing 'compressed_data' or 'shape' fields in request")

        if not isinstance(shape, list) or len(shape) != 2:
            return HttpResponseBadRequest("Invalid 'shape' format")

        # Decode base64 -> decompress gzip -> parse JSON
        compressed_bytes = base64.b64decode(compressed_b64)
        decompressed_bytes = gzip.decompress(compressed_bytes)
        decoded_payload = json.loads(decompressed_bytes.decode('utf-8'))

        encoded = decoded_payload.get('encoded')
        if not encoded:
            return HttpResponseBadRequest("Decoded payload missing 'encoded' field")

        # Proses berdasarkan mode (RGB atau grayscale)
        if mode.upper() == 'RGB' and channels == 3:
            print(f"Processing RGB image with shape: {shape}")
            
            # Untuk RGB, encoded_tuples berformat [[R,G,B], count]
            encoded_tuples = []
            for rgb_list, count in encoded:
                if len(rgb_list) != 3:
                    raise ValueError(f"Invalid RGB data: expected 3 values, got {len(rgb_list)}")
                encoded_tuples.append((rgb_list, int(count)))
            
            # Decode RLE RGB
            decoded_img = rle_decode_rgb(encoded_tuples, tuple(shape))
            
            # Konversi dari RGB ke BGR untuk OpenCV
            decoded_img_bgr = cv2.cvtColor(decoded_img, cv2.COLOR_RGB2BGR)
            
        else:
            print(f"Processing grayscale image with shape: {shape}")
            
            # Untuk grayscale, encoded_tuples berformat [value, count]
            encoded_tuples = [(int(val), int(count)) for val, count in encoded]
            
            # Decode RLE grayscale
            decoded_img_bgr = rle_decode_grayscale(encoded_tuples, tuple(shape))

        # Siapkan direktori penyimpanan
        output_dir = os.path.join(settings.MEDIA_ROOT, "rle_images", str(id_pegawai))
        os.makedirs(output_dir, exist_ok=True)

        # Buat nama file berdasarkan waktu dan mode
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_decoded_{mode.lower()}.jpg"
        save_path = os.path.join(output_dir, filename)

        # Simpan sebagai gambar PNG
        success = cv2.imwrite(save_path, decoded_img_bgr)
        
        if not success:
            raise Exception("Failed to save image")

        # Informasi tambahan untuk response
        if mode.upper() == 'RGB':
            shape_info = f"{shape[0]}x{shape[1]}x{channels}"
        else:
            shape_info = f"{shape[0]}x{shape[1]}"

        return JsonResponse({
            "message": f"Decoded {mode} image saved successfully",
            "saved_path": save_path,
            "filename": filename,
            "original_shape": shape,
            "channels": channels,
            "mode": mode,
            "shape_info": shape_info,
            "status": "success"
        })

    except Exception as e:
        print(f"Error in rle_decode_image: {str(e)}")
        return HttpResponseServerError(f"Error decoding image: {str(e)}")

# Fungsi tambahan untuk testing/debugging
def test_rle_rgb_decode():
    """
    Fungsi untuk testing decode RGB
    """
    # Contoh data RGB sederhana
    test_encoded = [
        [[255, 0, 0], 5],    # 5 pixel merah
        [[0, 255, 0], 3],    # 3 pixel hijau  
        [[0, 0, 255], 2]     # 2 pixel biru
    ]
    test_shape = (2, 5)  # 2 tinggi, 5 lebar = 10 pixel total
    
    try:
        result = rle_decode_rgb(test_encoded, test_shape)
        print(f"Test successful! Result shape: {result.shape}")
        print(f"Result:\n{result}")
        return True
    except Exception as e:
        print(f"Test failed: {e}")
        return False

def simple_arithmetic_decode(encoded_sequence, shape):
    """
    Simple Arithmetic Decode - konsisten dengan struktur RLE
    Format encoded_sequence: [pixel_value, frequency, pixel_value, frequency, ...]
    """
    height, width = shape
    total_pixels = height * width
    
    # Parse encoded sequence
    decoded_pixels = []
    
    # Proses sequence berpasangan [value, frequency]
    for i in range(0, len(encoded_sequence), 2):
        if i + 1 < len(encoded_sequence):
            pixel_value = int(encoded_sequence[i])
            frequency = int(encoded_sequence[i + 1])
            
            # Tambahkan pixel sesuai frekuensi
            decoded_pixels.extend([pixel_value] * frequency)
    
    # Pastikan jumlah pixel sesuai
    if len(decoded_pixels) < total_pixels:
        # Pad dengan nilai terakhir atau 0
        last_value = decoded_pixels[-1] if decoded_pixels else 0
        decoded_pixels.extend([last_value] * (total_pixels - len(decoded_pixels)))
    elif len(decoded_pixels) > total_pixels:
        # Trim kelebihan
        decoded_pixels = decoded_pixels[:total_pixels]
    
    # Reshape ke bentuk gambar
    decoded_array = np.array(decoded_pixels, dtype=np.uint8)
    return decoded_array.reshape(height, width)

def reconstruct_rgb_from_channels(red_channel, green_channel, blue_channel):
    """
    Gabungkan 3 channel menjadi RGB image
    """
    height, width = red_channel.shape
    rgb_image = np.zeros((height, width, 3), dtype=np.uint8)
    
    rgb_image[:, :, 0] = red_channel    # Red
    rgb_image[:, :, 1] = green_channel  # Green  
    rgb_image[:, :, 2] = blue_channel   # Blue
    
    return rgb_image


class ArithmeticCoder:
    def __init__(self):
        self.precision = 32  # 32-bit precision
        self.max_val = (1 << self.precision) - 1
        self.quarter = 1 << (self.precision - 2)
        self.half = 2 * self.quarter
        self.three_quarter = 3 * self.quarter
    
    def build_frequency_model(self, data):
        """Build frequency model from data"""
        counter = Counter(data)
        # Ensure all symbols have at least frequency 1
        for symbol in range(256):  # For 8-bit values
            if symbol not in counter:
                counter[symbol] = 1
        return dict(counter)
    
    def build_cumulative_freq(self, freq_model):
        """Build cumulative frequency table"""
        symbols = sorted(freq_model.keys())
        cumulative = {}
        total = 0
        
        for symbol in symbols:
            cumulative[symbol] = total
            total += freq_model[symbol]
        
        return cumulative, total
    
    def encode(self, data):
        """Encode data using arithmetic coding"""
        if not data:
            return b'', {}
        
        # Build frequency model
        freq_model = self.build_frequency_model(data)
        cumulative, total_freq = self.build_cumulative_freq(freq_model)
        
        # Initialize encoding variables
        low = 0
        high = self.max_val
        pending_bits = 0
        output_bits = []
        
        # Encode each symbol
        for symbol in data:
            # Calculate range
            range_size = high - low + 1
            
            # Update high and low
            symbol_freq = freq_model[symbol]
            symbol_cum = cumulative[symbol]
            
            high = low + (range_size * (symbol_cum + symbol_freq)) // total_freq - 1
            low = low + (range_size * symbol_cum) // total_freq
            
            # Output bits and renormalize
            while True:
                if high < self.half:
                    # Output 0
                    output_bits.append(0)
                    for _ in range(pending_bits):
                        output_bits.append(1)
                    pending_bits = 0
                elif low >= self.half:
                    # Output 1
                    output_bits.append(1)
                    for _ in range(pending_bits):
                        output_bits.append(0)
                    pending_bits = 0
                    low -= self.half
                    high -= self.half
                elif low >= self.quarter and high < self.three_quarter:
                    # Pending bit
                    pending_bits += 1
                    low -= self.quarter
                    high -= self.quarter
                else:
                    break
                
                # Scale up
                low = (low << 1) & self.max_val
                high = ((high << 1) | 1) & self.max_val
        
        # Output final bits
        pending_bits += 1
        if low < self.quarter:
            output_bits.append(0)
            for _ in range(pending_bits):
                output_bits.append(1)
        else:
            output_bits.append(1)
            for _ in range(pending_bits):
                output_bits.append(0)
        
        # Convert bits to bytes
        # Pad to make multiple of 8
        while len(output_bits) % 8 != 0:
            output_bits.append(0)
        
        output_bytes = bytearray()
        for i in range(0, len(output_bits), 8):
            byte = 0
            for j in range(8):
                if i + j < len(output_bits):
                    byte = (byte << 1) | output_bits[i + j]
                else:
                    byte = byte << 1
            output_bytes.append(byte)
        
        return bytes(output_bytes), freq_model
    
    def decode(self, encoded_bytes, freq_model, length):
        """Decode arithmetic coded data"""
        if not encoded_bytes or length == 0:
            return []
        
        # Build cumulative frequency table
        cumulative, total_freq = self.build_cumulative_freq(freq_model)
        symbols = sorted(freq_model.keys())
        
        # Convert bytes to code value
        code = 0
        for byte in encoded_bytes[:4]:  # Use first 4 bytes for initial code
            code = (code << 8) | byte
        
        # Initialize decoding variables
        low = 0
        high = self.max_val
        decoded_data = []
        byte_index = 0
        bit_buffer = 0
        bits_in_buffer = 0
        
        def get_next_bit():
            nonlocal byte_index, bit_buffer, bits_in_buffer
            if bits_in_buffer == 0:
                if byte_index < len(encoded_bytes):
                    bit_buffer = encoded_bytes[byte_index]
                    byte_index += 1
                    bits_in_buffer = 8
                else:
                    return 0  # No more bits
            
            bit = (bit_buffer >> (bits_in_buffer - 1)) & 1
            bits_in_buffer -= 1
            return bit
        
        # Skip initial bits used for code
        for _ in range(32):
            get_next_bit()
        
        # Decode symbols
        for _ in range(length):
            # Find symbol
            range_size = high - low + 1
            scaled_value = ((code - low + 1) * total_freq - 1) // range_size
            
            # Find the symbol that contains scaled_value
            symbol = symbols[0]  # default
            for s in symbols:
                symbol_low = cumulative[s]
                symbol_high = symbol_low + freq_model[s] - 1
                
                if symbol_low <= scaled_value <= symbol_high:
                    symbol = s
                    break
            
            decoded_data.append(symbol)
            
            # Update range
            symbol_cum = cumulative[symbol]
            symbol_freq = freq_model[symbol]
            
            high = low + (range_size * (symbol_cum + symbol_freq)) // total_freq - 1
            low = low + (range_size * symbol_cum) // total_freq
            
            # Renormalize
            while True:
                if high < self.half:
                    pass
                elif low >= self.half:
                    code -= self.half
                    low -= self.half
                    high -= self.half
                elif low >= self.quarter and high < self.three_quarter:
                    code -= self.quarter
                    low -= self.quarter
                    high -= self.quarter
                else:
                    break
                
                low = (low << 1) & self.max_val
                high = ((high << 1) | 1) & self.max_val
                code = ((code << 1) | get_next_bit()) & self.max_val
        
        return decoded_data

# Django Views

@csrf_exempt
def encode_image(request):
    """Encode image using arithmetic coding"""
    if request.method != 'POST':
        return HttpResponseBadRequest("Only POST allowed")
    
    try:
        # Handle file upload
        if 'image' not in request.FILES:
            return JsonResponse({"error": "No image file provided"}, status=400)
        
        image_file = request.FILES['image']
        
        # Load and process image
        img = Image.open(image_file)
        
        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        width, height = img.size
        
        # Convert image to pixel array
        pixels = []
        for y in range(height):
            for x in range(width):
                r, g, b = img.getpixel((x, y))
                pixels.extend([r, g, b])
        
        # Encode using arithmetic coding
        coder = ArithmeticCoder()
        encoded_bytes, freq_model = coder.encode(pixels)
        
        # Prepare response data
        encoded_data = base64.b64encode(encoded_bytes).decode('utf-8')
        
        response_data = {
            "status": "success",
            "encoded_data": encoded_data,
            "model": freq_model,
            "shape": [height, width, 3],
            "mode": "RGB",
            "original_size": len(pixels),
            "encoded_size": len(encoded_bytes),
            "compression_ratio": f"{len(pixels) / len(encoded_bytes):.2f}:1" if len(encoded_bytes) > 0 else "inf:1"
        }
        
        return JsonResponse(response_data)
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def decode_image(request):
    """Decode image using arithmetic coding"""
    if request.method != 'POST':
        return HttpResponseBadRequest("Only POST allowed")

    try:
        data = json.loads(request.body.decode('utf-8'))
        encoded_data = data.get('encoded_data')
        model = data.get('model')
        shape = data.get('shape')
        mode = data.get('mode', 'RGB')

        if not (encoded_data and model and shape):
            return JsonResponse({"error": "Missing required data"}, status=400)

        # Convert model keys from string to int (JSON converts int keys to strings)
        freq_model = {int(k): v for k, v in model.items()}

        # Decode base64 to bytes
        bitstream = base64.b64decode(encoded_data)

        # Decode using arithmetic coding
        coder = ArithmeticCoder()
        decoded_pixels = coder.decode(bitstream, freq_model, np.prod(shape))

        # Reconstruct image array
        image_array = np.array(decoded_pixels, dtype=np.uint8).reshape(shape)

        # Create PIL Image
        if len(shape) == 3 and shape[2] == 3:
            pil_image = Image.fromarray(image_array, mode='RGB')
        elif len(shape) == 2:
            pil_image = Image.fromarray(image_array, mode='L')
        else:
            pil_image = Image.fromarray(image_array, mode='RGB')

        # Save decoded image
        decoded_dir = os.path.join(settings.MEDIA_ROOT, 'decoded_images')
        os.makedirs(decoded_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"arithmetic_decoded_{timestamp}.png"
        filepath = os.path.join(decoded_dir, filename)
        
        pil_image.save(filepath, 'PNG')
        image_url = f"{settings.MEDIA_URL}decoded_images/{filename}"

        return JsonResponse({
            "status": "success",
            "decoded_shape": list(image_array.shape),
            "image_saved": True,
            "image_url": image_url,
            "filename": filename,
            "decoded_pixels": len(decoded_pixels),
            "pixel_stats": {
                "min": int(np.min(image_array)),
                "max": int(np.max(image_array)),
                "mean": float(np.mean(image_array))
            }
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# class TrueArithmeticCoder:
#     """
#     True Arithmetic Coder - EXACT SAME sebagai Flutter
#     """
    
#     @staticmethod
#     def run_length_decode(runs):
#         """Decode RLE runs ke data asli"""
#         if not runs:
#             return []
        
#         decoded = []
#         for run in runs:
#             value, count = run[0], run[1]
#             decoded.extend([value] * count)
        
#         return decoded
    
#     def simple_arithmetic_decode(self, encoded_result):
#         """
#         Simple Arithmetic Decode - EXACT SAME logic sebagai encoding
#         Input: encoded_result dari encoding process
#         Output: decoded pixel data
#         """
#         try:
#             print(f"🔄 Simple Arithmetic decoding...")
            
#             # Get runs dari encoded result
#             runs = encoded_result.get('runs', [])
#             if not runs:
#                 raise Exception("No runs data found in encoded result")
            
#             print(f"   📦 Decoding {len(runs)} runs...")
            
#             # Decode RLE runs ke pixel data asli
#             decoded_data = self.run_length_decode(runs)
            
#             # Validate hasil decode
#             expected_length = encoded_result.get('original_length', 0)
#             if len(decoded_data) != expected_length:
#                 print(f"⚠️ Length mismatch: got {len(decoded_data)}, expected {expected_length}")
            
#             print(f"   ✅ Decoded to {len(decoded_data)} pixels")
            
#             return decoded_data
            
#         except Exception as e:
#             print(f"❌ Error in simple_arithmetic_decode: {e}")
#             raise Exception(f"Decoding failed: {e}")

# # EXACT SAME CLASS dari Flutter - PureRLECoder  
# class PureRLECoder:
#     """
#     Pure RLE Coder - EXACT SAME sebagai Flutter
#     """
    
#     def decode(self, encoded_result):
#         """
#         Pure RLE Decode
#         Input: encoded_result dengan runs
#         Output: decoded pixel data
#         """
#         try:
#             print(f"🔄 Pure RLE decoding...")
            
#             runs = encoded_result.get('runs', [])
#             if not runs:
#                 raise Exception("No runs data found in encoded result")
            
#             print(f"   📦 Decoding {len(runs)} runs...")
            
#             # Decode RLE
#             decoded_data = []
#             for run in runs:
#                 value, count = run[0], run[1]
#                 decoded_data.extend([value] * count)
            
#             # Validate hasil decode
#             expected_length = encoded_result.get('original_length', 0)
#             if len(decoded_data) != expected_length:
#                 print(f"⚠️ Length mismatch: got {len(decoded_data)}, expected {expected_length}")
            
#             print(f"   ✅ Decoded to {len(decoded_data)} pixels")
            
#             return decoded_data
            
#         except Exception as e:
#             print(f"❌ Error in pure RLE decode: {e}")
#             raise Exception(f"RLE Decoding failed: {e}")

# @csrf_exempt
# def arithmetic_decode_image(request):
#     """
#     Decode gambar dari True Arithmetic Coding - SUPPORT RGB dari Flutter
#     Endpoint: POST /arithmetic_decode_image
#     Input: JSON dengan compressed_data
#     """
#     if request.method != 'POST':
#         return JsonResponse({
#             "success": False,
#             "error": "Method not allowed. Use POST."
#         })

#     try:
#         print("🎯 TRUE ARITHMETIC CODING - DECODE (RGB SUPPORT)")
#         print("=" * 50)
        
#         # Parse JSON body dengan error handling yang robust
#         try:
#             body_unicode = request.body.decode('utf-8')
#             body_data = json.loads(body_unicode)
#         except UnicodeDecodeError:
#             try:
#                 body_unicode = request.body.decode('latin-1')
#                 body_data = json.loads(body_unicode)
#                 print("⚠️ Using latin-1 encoding fallback")
#             except Exception:
#                 body_unicode = request.body.decode('utf-8', errors='ignore')
#                 body_data = json.loads(body_unicode)
#                 print("⚠️ Using UTF-8 with ignore errors")
#         except json.JSONDecodeError as e:
#             print(f"❌ JSON decode error: {e}")
#             return JsonResponse({
#                 "success": False,
#                 "error": f"Invalid JSON: {e}"
#             })

#         print(f"📦 Successfully parsed JSON payload")
#         print(f"📦 Payload keys: {list(body_data.keys())}")

#         # Get compressed data
#         compressed_b64 = body_data.get('compressed_data')
#         if not compressed_b64:
#             return JsonResponse({
#                 "success": False,
#                 "error": "Missing 'compressed_data' field"
#             })

#         print(f"📦 Received compressed data: {len(compressed_b64):,} characters")

#         # Log additional data jika ada (data pegawai, dll)
#         additional_keys = [k for k in body_data.keys() if k != 'compressed_data']
#         pegawai_data = {}
#         id_pegawai = 'unknown'  # Default ID pegawai
        
#         if additional_keys:
#             print(f"📤 Additional data received: {additional_keys}")
#             for key in additional_keys:
#                 value = body_data.get(key)
#                 pegawai_data[key] = value
#                 print(f"   {key}: {value}")
                
#                 # Extract ID pegawai untuk folder name
#                 if key == 'id_pegawai':
#                     id_pegawai = str(value)

#         # Decompress GZIP + Base64
#         try:
#             print("📦 Decompressing data...")
#             compressed_bytes = base64.b64decode(compressed_b64)
#             decompressed_bytes = gzip.decompress(compressed_bytes)
#             encoded_result = json.loads(decompressed_bytes.decode('utf-8'))
#             print("✅ Data decompression successful")
#         except Exception as e:
#             print(f"❌ Decompression error: {e}")
#             return JsonResponse({
#                 "success": False,
#                 "error": f"Failed to decompress data: {e}"
#             })

#         print(f"📊 Decoded payload:")
#         print(f"   Method: {encoded_result.get('method', 'unknown')}")
#         print(f"   Original length: {encoded_result.get('original_length', 0):,}")
#         print(f"   Runs: {len(encoded_result.get('runs', [])):,}")
#         print(f"   Image shape: {encoded_result.get('image_shape', 'unknown')}")
#         print(f"   Color mode: {encoded_result.get('color_mode', 'unknown')}")
#         print(f"   Channels: {encoded_result.get('channels', 'unknown')}")
#         print(f"   Original filename: {encoded_result.get('original_filename', 'unknown')}")

#         # Decode menggunakan coder yang sesuai
#         method = encoded_result.get('method', '')
        
#         if method == 'pure_rle':
#             print("📊 Using Pure RLE Decoder...")
#             coder = PureRLECoder()
#             decoded_data = coder.decode(encoded_result)
#         elif method == 'simple_arithmetic':
#             print("📊 Using True Arithmetic Decoder...")
#             coder = TrueArithmeticCoder()
#             decoded_data = coder.simple_arithmetic_decode(encoded_result)
#         else:
#             return JsonResponse({
#                 "success": False,
#                 "error": f"Unsupported method: {method}. Supported: 'simple_arithmetic', 'pure_rle'"
#             })

#         print(f"✅ Decoding completed: {len(decoded_data)} pixels")

#         # Reconstruct image - SUPPORT RGB & GRAYSCALE
#         image_shape = encoded_result.get('image_shape')
#         color_mode = encoded_result.get('color_mode', 'grayscale')
#         channels = encoded_result.get('channels', 1)
        
#         print(f"🎨 Reconstructing image:")
#         print(f"   Color mode: {color_mode}")
#         print(f"   Channels: {channels}")
#         print(f"   Shape: {image_shape}")

#         # Validate image shape
#         if not image_shape:
#             return JsonResponse({
#                 "success": False,
#                 "error": "Missing image_shape"
#             })

#         # Handle RGB vs Grayscale
#         if color_mode == 'RGB' and channels == 3:
#             # RGB Image - shape: [height, width, 3]
#             if len(image_shape) != 3 or image_shape[2] != 3:
#                 return JsonResponse({
#                     "success": False,
#                     "error": f"Invalid RGB image_shape: {image_shape}. Expected [height, width, 3]"
#                 })
            
#             height, width, ch = image_shape
#             expected_pixels = height * width * 3
            
#             if len(decoded_data) != expected_pixels:
#                 print(f"⚠️ RGB pixel count mismatch: got {len(decoded_data)}, expected {expected_pixels}")
#                 return JsonResponse({
#                     "success": False,
#                     "error": f"RGB pixel mismatch. Got {len(decoded_data)}, expected {expected_pixels}"
#                 })

#             # Reshape ke RGB image: [height, width, 3]
#             try:
#                 # Flutter sends RGB data: [R,G,B,R,G,B,...]
#                 decoded_img = np.array(decoded_data, dtype=np.uint8).reshape(height, width, 3)
#                 print(f"✅ RGB Image reconstructed: {decoded_img.shape}")
                
#                 # Debug: Print sample pixel values
#                 if decoded_img.size > 0:
#                     sample_pixel = decoded_img[0, 0]  # First pixel RGB
#                     print(f"🔍 Sample pixel RGB: {sample_pixel}")
                
#             except Exception as e:
#                 return JsonResponse({
#                     "success": False,
#                     "error": f"Failed to reshape RGB image: {e}"
#                 })
#         else:
#             # Grayscale Image - shape: [height, width]
#             if len(image_shape) != 2:
#                 return JsonResponse({
#                     "success": False,
#                     "error": f"Invalid grayscale image_shape: {image_shape}. Expected [height, width]"
#                 })
            
#             height, width = image_shape
#             expected_pixels = height * width
            
#             if len(decoded_data) != expected_pixels:
#                 print(f"⚠️ Grayscale pixel count mismatch: got {len(decoded_data)}, expected {expected_pixels}")
#                 return JsonResponse({
#                     "success": False,
#                     "error": f"Grayscale pixel mismatch. Got {len(decoded_data)}, expected {expected_pixels}"
#                 })

#             # Reshape ke grayscale image: [height, width]
#             try:
#                 decoded_img = np.array(decoded_data, dtype=np.uint8).reshape(height, width)
#                 print(f"✅ Grayscale Image reconstructed: {decoded_img.shape}")
                
#             except Exception as e:
#                 return JsonResponse({
#                     "success": False,
#                     "error": f"Failed to reshape grayscale image: {e}"
#                 })

#         # Save decoded image
#         try:
#             # Create output directory
#             output_dir = os.path.join(settings.MEDIA_ROOT, "arithmetic_images", id_pegawai)
#             os.makedirs(output_dir, exist_ok=True)
#             print(f"📁 Created output directory: {output_dir}")

#             # Generate filename
#             timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
#             original_name = encoded_result.get('original_filename', 'unknown')
            
#             if original_name != 'unknown':
#                 name_part = os.path.splitext(original_name)[0]
#                 filename = f"{timestamp}_{name_part}_{color_mode}_decoded.png"
#             else:
#                 filename = f"{timestamp}_arithmetic_{color_mode}_decoded.png"
            
#             save_path = os.path.join(output_dir, filename)
#             print(f"💾 Saving to: {save_path}")

#             # Save image - pilih method yang sesuai
#             if color_mode == 'RGB':
#                 # For RGB, use PIL to maintain RGB order
#                 from PIL import Image
#                 pil_image = Image.fromarray(decoded_img, mode='RGB')
#                 pil_image.save(save_path, 'PNG')
#                 print(f"✅ RGB image saved using PIL (maintains RGB order)")
#             else:
#                 # For grayscale, use OpenCV
#                 success = cv2.imwrite(save_path, decoded_img)
#                 if not success:
#                     return JsonResponse({
#                         "success": False,
#                         "error": "Failed to save grayscale image with cv2.imwrite"
#                     })
#                 print(f"✅ Grayscale image saved using OpenCV")

#             # Verify file exists and get size
#             if not os.path.exists(save_path):
#                 return JsonResponse({
#                     "success": False,
#                     "error": f"File was not saved: {save_path}"
#                 })
                
#             file_size = os.path.getsize(save_path)
            
#             print(f"✅ Image saved successfully!")
#             print(f"💾 Filename: {filename}")
#             print(f"📦 File size: {file_size:,} bytes ({file_size/1024:.2f} KB)")
#             print(f"📂 Full path: {os.path.abspath(save_path)}")
#             print(f"🎨 Image shape: {decoded_img.shape}")
#             print(f"🌈 Color mode: {color_mode}")

#         except Exception as e:
#             print(f"❌ Error saving image: {e}")
#             import traceback
#             traceback.print_exc()
#             return JsonResponse({
#                 "success": False,
#                 "error": f"Failed to save image: {e}"
#             })

#         # Prepare response
#         response_data = {
#             "success": True,
#             "message": f"{color_mode} image decoded and saved successfully",
#             "saved_path": os.path.abspath(save_path),
#             "filename": filename,
#             "decoded_shape": list(decoded_img.shape),
#             "color_mode": color_mode,
#             "channels": channels,
#             "method": method,
#             "original_filename": encoded_result.get('original_filename', 'unknown'),
#             "file_size_bytes": file_size,
#             "file_size_kb": round(file_size / 1024, 2),
#             "pixel_count": len(decoded_data),
#             "status": f"✅ {color_mode} DECODED",
#             "timestamp": timestamp,
#             "id_pegawai": id_pegawai
#         }
        
#         # Add pegawai data if present
#         if pegawai_data:
#             response_data['pegawai_data'] = pegawai_data
#             print(f"📤 Including pegawai data in response")

#         print(f"🎉 Response ready: success=True")
#         print(f"📂 Final file location: {os.path.abspath(save_path)}")
        
#         return JsonResponse(response_data)

#     except Exception as e:
#         print(f"❌ Unexpected error in decode: {str(e)}")
#         import traceback
#         traceback.print_exc()
#         return JsonResponse({
#             "success": False,
#             "error": f"Unexpected error: {str(e)}",
#             "traceback": traceback.format_exc() if settings.DEBUG else None
#         })






@csrf_exempt
@api_view(['POST'])    
def daftar(request):
    if request.method == 'POST':
        email = request.POST.get('email')
        nama = request.POST.get('nama')
        nip = request.POST.get('nip')
        no_hp = request.POST.get('no_hp')
        password = request.POST.get('password')
        email = request.POST.get('email')
        id_jabatan = request.POST.get('id_jabatan')
        id_unit_kerja = request.POST.get('id_unit_kerja')

        if not nip:
            return JsonResponse({'message': 'NIP wajib diisi'}, status=400)
        
        if Pegawai.objects.filter(nip=nip).exists():
            return JsonResponse({'message': 'NIP sudah terdaftar'}, status=400)
        
        if User.objects.filter(username=email).exists():
            return JsonResponse({'message': 'Email sudah terdaftar'}, status=400)

        try:
            jabatan_obj = Jabatan.objects.get(id_jabatan=id_jabatan)
        except Jabatan.DoesNotExist:
            return JsonResponse({'message': 'Jabatan tidak ditemukan'}, status=400)
        
        try:
            unit_kerja_obj = UnitKerja.objects.get(id_unit_kerja=id_unit_kerja)
        except UnitKerja.DoesNotExist:
            return JsonResponse({'message': 'Unit kerja tidak ditemukan'}, status=400)

        # Buat user
        user = User.objects.create(
            username=email,
            email=email,
            password=make_password(password),
        )

        # Buat pegawai
        Pegawai.objects.create(
            user=user,
            nama=nama,
            nip=nip,
            no_hp=no_hp,
            email=email,
            id_jabatan=jabatan_obj,
            id_unit_kerja=unit_kerja_obj,
        )

        return JsonResponse({'message': 'Akun berhasil dibuat'}, status=201)

    return JsonResponse({'message': 'Hanya menerima POST'}, status=405)

@csrf_exempt
@api_view(['POST'])
def login(request):

    if request.method == 'POST':
        try:
            data = request.data

            nip = data.get('nip')
            email = data.get('email')
            password = data.get('password')

            print("===== DATA MASUK =====")
            print(data)

            pegawai = Pegawai.objects.get(nip=nip, email=email)

            response_data = {
                "id_pegawai": pegawai.id_pegawai,
                "nama": pegawai.nama,
                "nip": pegawai.nip,
                "email": pegawai.email,
                "no_hp": pegawai.no_hp,
                "id_unit_kerja": pegawai.id_unit_kerja.pk if pegawai.id_unit_kerja else None,
            }

            return JsonResponse({"status": "success", "data": response_data}, status=200)

        except Pegawai.DoesNotExist:
            return JsonResponse({"status": "error", "message": "Login gagal, data tidak ditemukan"}, status=401)
        except Exception as e:
            return JsonResponse({"status": "error", "message": str(e)}, status=500)

    return JsonResponse({"status": "error", "message": "Method not allowed"}, status=405)

# MWNGAMBIL DATA UNTUK DITAMPILKAN DI BAWAH PROFIL
def login_pegawai(request, id_pegawai):
    try:
        from .models import Pegawai
        
        # GUNAKAN SELECT_RELATED untuk JOIN otomatis
        pegawai = Pegawai.objects.select_related('id_jabatan', 'id_unit_kerja').get(
            id_pegawai=id_pegawai
        )
        
        response_data = {
            'id_pegawai': pegawai.id_pegawai,
            'nama': pegawai.nama,
            'nip': pegawai.nip,
            'id_jabatan': pegawai.id_jabatan.id if pegawai.id_jabatan else None,
            'nama_jabatan': pegawai.id_jabatan.nama_jabatan if pegawai.id_jabatan else None,
            'id_unit_kerja': pegawai.id_unit_kerja.id if pegawai.id_unit_kerja else None,
            'nama_unit_kerja': pegawai.id_unit_kerja.nama_unit_kerja if pegawai.id_unit_kerja else None,
            # ... field lainnya
        }
        
        return JsonResponse(response_data)
        
    except Pegawai.DoesNotExist:
        return JsonResponse({'error': 'Pegawai tidak ditemukan'}, status=404)


# DIGUNAKAN UNTUK AMBIL DATA CO/CI
def get_attendance(request, id_pegawai):
    """
    Endpoint untuk ambil absensi HARI INI yang TERBARU
    """
    try:
        from .models import LogAbsensi
        
        print(f"📊 Getting TODAY's LATEST attendance for pegawai: {id_pegawai}")
        
        # Ambil tanggal hari ini
        today = timezone.now().date()
        print(f"📊 Today: {today}")
        
        # AMBIL CHECK-IN HARI INI YANG TERBARU
        today_latest_check_in = LogAbsensi.objects.filter(
            id_pegawai=id_pegawai,
            check_mode=0,  # Check-in
            waktu_absensi__date=today,  # HARI INI
            deleted_at__isnull=True
        ).order_by('-waktu_absensi').first()  # YANG TERBARU
        
        # AMBIL CHECK-OUT HARI INI YANG TERBARU
        today_latest_check_out = LogAbsensi.objects.filter(
            id_pegawai=id_pegawai,
            check_mode=1,  # Check-out
            waktu_absensi__date=today,  # HARI INI
            deleted_at__isnull=True
        ).order_by('-waktu_absensi').first()  # YANG TERBARU
        
        print(f"📊 Today's latest check-in: {today_latest_check_in}")
        print(f"📊 Today's latest check-out: {today_latest_check_out}")
        
        # RESPONSE SEDERHANA
        response_data = {
            'success': True,
            'id_pegawai': id_pegawai,
            'today': today.isoformat(),
            # Absensi hari ini yang terbaru
            'today_check_in': today_latest_check_in.waktu_absensi.isoformat() if today_latest_check_in else None,
            'today_check_out': today_latest_check_out.waktu_absensi.isoformat() if today_latest_check_out else None,
            # Status
            'has_checked_in_today': today_latest_check_in is not None,
            'has_checked_out_today': today_latest_check_out is not None,
            # Debug info
            'debug': {
                'total_checkins_today': LogAbsensi.objects.filter(
                    id_pegawai=id_pegawai, 
                    check_mode=0, 
                    waktu_absensi__date=today,
                    deleted_at__isnull=True
                ).count(),
                'total_checkouts_today': LogAbsensi.objects.filter(
                    id_pegawai=id_pegawai, 
                    check_mode=1, 
                    waktu_absensi__date=today,
                    deleted_at__isnull=True
                ).count(),
            }
        }
        
        print(f"📊 Response: {response_data}")
        return JsonResponse(response_data)
        
    except Exception as e:
        print(f"❌ Error getting today's attendance: {e}")
        import traceback
        traceback.print_exc()
        return JsonResponse({
            'success': False,
            'error': str(e),
            'message': 'Gagal mengambil data absensi hari ini'
        }, status=500)


#  DIGUNAKAN UNTUK EDIT INFORMASI PEGAWAI DI BAGIAN AKUN
def get_pegawai_detail(request, id_pegawai):
    try:
        pegawai = Pegawai.objects.get('id_jabatan', 'id_unit_kerja').get(id_pegawai=id_pegawai)
        
        # ✅ Langsung ambil dari field database
        data = {
            'id_pegawai': pegawai.id_pegawai,
            'nama': pegawai.nama,
            'nip': pegawai.nip, 
            'jabatan': pegawai.id_jabatan.nama_jabatan if pegawai.id_jabatan else 'Tidak Diset',
            'unit_kerja': pegawai.id_unit_kerja.nama_unit_kerja if pegawai.id_unit_kerja else 'Tidak Diset',
            'email': pegawai.email,     # ← Dari kolom email
            'no_hp': pegawai.no_hp,     # ← Dari kolom no_hp
            'foto': pegawai.foto.url if pegawai.foto else None,
        }
        
        return JsonResponse({'status': 'success', 'data': data})
    except Pegawai.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Pegawai tidak ditemukan'})
    
#  DIGUNAKAN UNTUK EDIT INFORMASI PEGAWAI DI BAGIAN AKUN
def update_pegawai_info(request, id_pegawai):
    if request.method == 'PUT':
        try:
            pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
            data = json.loads(request.body)
            
            # Update langsung ke kolom database
            if 'nama' in data:
                pegawai.nama = data['nama']
            if 'email' in data:
                pegawai.email = data['email'] if data['email'] else None
            if 'no_hp' in data:
                pegawai.no_hp = data['no_hp'] if data['no_hp'] else None
                
            pegawai.save()
            
            return JsonResponse({'status': 'success', 'message': 'Data berhasil diperbarui'})
        except:
            return JsonResponse({'status': 'error', 'message': 'Gagal update'})
        
@api_view(['POST'])
def log_absensi(request):
    print("Data diterima:", request.data)

    id_pegawai = request.data.get('id_pegawai')
    jenis = request.data.get('jenis', 0)
    lokasi = request.data.get('lokasi')
    waktu = timezone.now()
    check_mode = request.data.get('check_mode')
    latitude = request.data.get('latitude')
    longitude = request.data.get('longitude')

    print("jenis =", jenis)
    print("check_mode =", check_mode)

    if check_mode not in [0, 1, '0', '1']:
        return Response({'message': 'check_mode tidak valid'}, status=400)
    
    try:
        # Ambil objek pegawai berdasarkan ID
        pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
    except Pegawai.DoesNotExist:
        return Response({'message': 'Pegawai tidak ditemukan'}, status=404)

    # Simpan ke model Absensi
    LogAbsensi.objects.create(
        id_pegawai=pegawai,
        jenis_absensi=jenis,
        nama_lokasi=lokasi,
        waktu_absensi=waktu,
        check_mode=check_mode, 
        latitude=latitude,
        longitude=longitude,       
    )

    try:
        requests.post('http://localhost:8080/sipreti/log_absensi', data={
            'id_pegawai': id_pegawai,
            'jenis_absensi': jenis,
            'check_mode': check_mode,
            'nama_lokasi': lokasi,
            'waktu_absensi': waktu.isoformat(),
            'latitude': latitude,
            'longitude': longitude,
    })

    except Exception as e:
        print('Gagal kirim ke CI:', e)

    return Response({'message': 'Berhasil disimpan'}, status=200)

@api_view(['POST'])
def create_user_android(request):
    print("Raw request data:", request.body)
    print("Parsed data:", request.data)
    # Rest of your view...

@api_view(['POST'])
def register_android_device(request):
    try:
        # Ambil data dari request
        data = request.data
        id_pegawai = data.get('id_pegawai')
        username = data.get('username')
        device_id = data.get('device_id')
        device_brand = data.get('device_brand')
        device_model = data.get('device_model')
        device_os_version = data.get('device_os_version')
        device_sdk_version = data.get('device_sdk_version')
        last_login = data.get('last_login')
        
        try:
            pegawai = Pegawai.objects.get(id_pegawai=id_pegawai)
        except Pegawai.DoesNotExist:
            return Response({'status': 'error', 'message': f'Pegawai dengan ID {id_pegawai} tidak ditemukan'}, status=404)
        
        # Simpan ke database
        user_android = UserAndroid.objects.create(
            id_pegawai=pegawai,
            username=username,
            device_id=device_id,
            device_brand=device_brand,
            device_model=device_model,
            device_os_version=device_os_version,
            device_sdk_version=device_sdk_version,
            last_login=last_login
        )
        
        return Response({'status': 'success', 'id': user_android.id}, status=201)
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=400)

@api_view(['GET'])
def get_radius(request):
    try:
        radius_list = RadiusAbsen.objects.all()
        data = []
        for r in radius_list:
            data.append({
                'id_radius': r.id_radius,
                'ukuran': r.ukuran,
                'satuan': r.satuan,
            })
        return Response(data)
    except Exception as e:
        return Response({'error': str(e)}, status=500)
    

@api_view(['GET'])
def get_lokasi_unit_kerja(request):
    try:
        unit_list = UnitKerja.objects.all()
        data = []
        for unit in unit_list:
            data.append({
                'id_unit_kerja': unit.id_unit_kerja,
                'nama_unit': unit.nama_unit,
                'alamat': unit.alamat,
                # 'latitude': unit.latitude,
                # 'longitude': unit.longitude,
                'radius': {
                    'id_radius': unit.radius.id_radius if unit.radius else None,
                    'ukuran': unit.radius.ukuran if unit.radius else None,
                    'satuan': unit.radius.satuan if unit.radius else None,
                }
            })
        return Response(data)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

class BiometrikViewSet(viewsets.ModelViewSet):
    queryset = Biometrik.objects.all()
    serializer_class = BiometrikSerializer

@csrf_exempt
def get_image(request):
    if request.method == 'POST':
        image_url = request.POST.get('image_url')  # atau 'GET' jika dari query param
        # Bisa tambahkan logika validasi atau pengolahan URL jika perlu

        return JsonResponse({'status': 'success', 'image_url': image_url})
    return JsonResponse({'status': 'failed', 'message': 'Invalid request method'})


@csrf_exempt
@api_view(['GET'])
def get_face_vector(request, id_pegawai):
    vector_data = {'id_pegawai': id_pegawai, 'face_vector': 'sample_vector_data'}
        
        # Log data yang akan dikirim
    logger.info(f"Sending data to CI for ID: {id_pegawai}")
    logger.debug(f"Vector data: {json.dumps(vector_data)}")
        
        # Kirim ke CI
    ci_endpoint = "http://192.168.1.39:8000/pegawai/lihat_vektor/"
    
    try:
        response = requests.post(
            ci_endpoint,
            json=vector_data,
            headers={'Content-Type': 'application/json'},
            timeout=10,
        )
        
        # Log response
        logger.info(f"CI Response status: {response.status_code}")
        logger.debug(f"CI Response content: {response.text}")
        
        if response.status_code == 200:
            return JsonResponse({'status': 'success', 'message': 'Data sent to CI'})
        else:
            return JsonResponse({'status': 'error', 'message': f'CI returned status code {response.status_code}'})

    except Exception as e:
        logger.error(f"Error sending data to CI: {str(e)}")
        return JsonResponse({'status': 'error', 'message': str(e)})


def kirim_gambar(request):
    if request.method == 'POST':
        image_file = request.FILES.get('image')
        id_pegawai = request.POST.get('id_pegawai')
        name = request.POST.get('name')

        if image_file:
            file_name = f"pegawai_{id_pegawai}.jpg"
            path = default_storage.save(f"images/{file_name}", ContentFile(image_file.read()))
            image_url = default_storage.url(path)

            # simpan URL gambar ke database
            Biometrik.objects.create(
                id_pegawai=id_pegawai,
                nama=name,
                image=image_url,
                face_vector=f"{file_name}.txt"
            )

            return JsonResponse({'status': 'success', 'image_url': image_url})




@csrf_exempt
def enroll_face(request):
    if request.method == 'POST':
        if 'url_foto' in request.FILES and 'id_pegawai' in request.POST:
            file = request.FILES['url_foto']
            id_pegawai = request.POST['id_pegawai']
            file_name = file.name

            # Simpan file secara lokal
            url_image = save_uploaded_file(file)

            # Generate vektor
            success = add_face([url_image], id_pegawai)

            if success:
                face_id = insert_image_db(id_pegawai, file_name, url_image)
                return JsonResponse({
                    'status': 1,
                    'message': 'Vektor berhasil dibuat',
                    'face_id': face_id,
                    'url': url_image
                })
            else:
                return JsonResponse({
                    'status': 0,
                    'message': 'Gagal mendeteksi wajah'
                })
        else:
            return JsonResponse({
                'status': 0,
                'message': 'Data tidak lengkap'
            })
    return JsonResponse({'status': 0, 'message': 'Gunakan metode POST'})


logger = logging.getLogger(__name__)

class HuffmanNode:
    def __init__(self, value=None, frequency=0, left=None, right=None):
        self.value = value  # Nilai pixel (0-255) atau None untuk node internal
        self.frequency = frequency  # Frekuensi kemunculan
        self.left = left
        self.right = right

def build_huffman_tree(frequencies):
    """Membangun pohon Huffman dari frekuensi"""
    # Konversi dictionary frekuensi ke list node
    nodes = []
    for value, freq in frequencies.items():
        nodes.append(HuffmanNode(value=int(value), frequency=freq))
    
    # Urutkan nodes berdasarkan frekuensi (terendah dulu)
    while len(nodes) > 1:
        # Urutkan nodes berdasarkan frekuensi
        nodes.sort(key=lambda node: node.frequency)
        
        # Ambil dua node dengan frekuensi terendah
        left = nodes.pop(0)
        right = nodes.pop(0)
        
        # Buat node baru dengan children dari dua node tadi
        parent = HuffmanNode(
            value=None,  # Node internal tidak punya nilai
            frequency=left.frequency + right.frequency,
            left=left,
            right=right
        )
        
        # Tambahkan node baru ke list
        nodes.append(parent)
    
    # Kembalikan root dari pohon Huffman
    return nodes[0] if nodes else None

def bytes_to_bits(byte_data, padding_bits):
    """
    Konversi bytes ke bits dengan implementasi yang persis sama dengan Dart
    Ingat: byte terakhir berisi informasi padding
    """
    # Debug log untuk melihat nilai
    logger.debug(f"Dekompresi: byte_data length={len(byte_data)}, padding_bits={padding_bits}")
    
    # Proses semua byte KECUALI byte terakhir (padding info)
    bits = []
    for i in range(len(byte_data) - 1):
        byte = byte_data[i]
        # Pastikan urutan bit sama dengan kode Dart
        for j in range(7, -1, -1):
            bits.append(1 if (byte & (1 << j)) else 0)
    
    # Jika ada padding (bitPos != 7 di Dart), hapus bit padding
    if padding_bits > 0:
        # Di _bitsToBytes Dart, padding dihitung sebagai (bitPos + 1) % 8
        # Kita perlu membuang sejumlah padding_bits bit terakhir
        bits = bits[:-padding_bits]
    
    return bits

def decode_huffman(compressed_data, root, original_length, width, height):
    """Dekode bitstream Huffman ke piksel original dengan penanganan error yang lebih baik"""
    # Ambil byte padding dari byte terakhir
    padding_bits = compressed_data[-1]
    
    # Konversi bytes ke bits dengan memperhatikan padding
    bits = bytes_to_bits(compressed_data, padding_bits)
    
    # Log statistik bits
    logger.debug(f"Total bits: {len(bits)}, Padding: {padding_bits}")
    logger.debug(f"Expected original length: {original_length}, Calculated image size: {width}x{height}={width*height}")
    
    # Dekode bitstream ke nilai piksel
    decoded_pixels = []
    current_node = root
    
    try:
        for bit in bits:
            # Traverse pohon Huffman sesuai bit
            if bit == 0:
                current_node = current_node.left
            else:
                current_node = current_node.right
            
            # Jika mencapai leaf node (punya nilai)
            if current_node and current_node.value is not None:
                decoded_pixels.append(current_node.value)
                current_node = root  # Reset ke root
                
                # Jika sudah mencapai panjang original, berhenti
                if len(decoded_pixels) >= original_length:
                    break
    except Exception as e:
        logger.error(f"Error saat dekode: {e}")
        logger.error(traceback.format_exc())
    
    # Periksa hasil dekompresi
    if len(decoded_pixels) != original_length:
        logger.warning(f"Jumlah piksel hasil dekode ({len(decoded_pixels)}) tidak sama dengan panjang original ({original_length})")
        
        # Penyesuaian jumlah piksel
        if len(decoded_pixels) < original_length:
            # Tambahkan piksel hitam jika kurang
            padding_needed = original_length - len(decoded_pixels)
            logger.warning(f"Menambahkan {padding_needed} piksel hitam")
            decoded_pixels.extend([0] * padding_needed)
        else:
            # Potong kelebihan piksel
            logger.warning(f"Memotong {len(decoded_pixels) - original_length} piksel berlebih")
            decoded_pixels = decoded_pixels[:original_length]
    
    # Statistik piksel
    if decoded_pixels:
        min_val = min(decoded_pixels)
        max_val = max(decoded_pixels)
        avg_val = sum(decoded_pixels) / len(decoded_pixels)
        logger.info(f"Statistik piksel - Min: {min_val}, Max: {max_val}, Avg: {avg_val:.2f}")
    
    return decoded_pixels


# Definisi class HuffmanNode
class HuffmanNode:
    def __init__(self, value=None, frequency=0):
        self.value = value
        self.frequency = frequency
        self.left = None
        self.right = None

# Fungsi helper untuk membangun pohon Huffman dari JSON
def build_huffman_tree_from_json(json_data):
    """
    Membangun pohon Huffman dari format JSON yang dikirim oleh Flutter
    """
    if json_data is None:
        return None
    
    # Format array dari serialisasi optimized
    if isinstance(json_data, list):
        def build_tree_from_array(array, index=0):
            if index >= len(array) or array[index] == -1:
                return None, index + 1
            
            if array[index] >= 0:  # Leaf node
                return HuffmanNode(value=array[index]), index + 1
            
            # Internal node (-2)
            node = HuffmanNode()
            index += 1
            
            node.left, index = build_tree_from_array(array, index)
            node.right, index = build_tree_from_array(array, index)
            
            return node, index
        
        root, _ = build_tree_from_array(json_data)
        return root
    
    # Format dictionary/object dengan left/right
    if isinstance(json_data, dict):
        node = HuffmanNode(
            value=json_data.get("value"),
            frequency=json_data.get("frequency", 0)
        )
        
        if "left" in json_data and json_data["left"] is not None:
            node.left = build_huffman_tree_from_json(json_data["left"])
        
        if "right" in json_data and json_data["right"] is not None:
            node.right = build_huffman_tree_from_json(json_data["right"])
        
        return node
    
    # Format tidak dikenali
    raise ValueError(f"Unrecognized Huffman tree format: {json_data}")

# Fungsi untuk melakukan dekode Huffman
def huffman_decode(encoded_data, huffman_tree, shape):
    """
    Fungsi untuk melakukan dekode Huffman dari data terkompresi
    
    Parameters:
    encoded_data (str/bytes): Data terkompresi, bisa base64 string atau bytes
    huffman_tree (HuffmanNode): Pohon Huffman untuk dekode
    shape (tuple): Dimensi gambar (height, width)
    
    Returns:
    numpy.ndarray: Gambar hasil dekompresi dalam format grayscale
    """
    try:
        # Jika encoded_data adalah string base64, decode dulu
        if isinstance(encoded_data, str):
            encoded_bytes = base64.b64decode(encoded_data)
        else:
            encoded_bytes = encoded_data
        
        # Konversi data terkompresi ke bitstream
        bitstream = []
        for i in range(len(encoded_bytes) - 1):  # Abaikan byte terakhir (padding)
            byte = encoded_bytes[i]
            for j in range(7, -1, -1):
                bit = (byte >> j) & 1
                bitstream.append(bit)
        
        # Cek padding bits di byte terakhir
        if len(encoded_bytes) > 0:
            padding_bits = encoded_bytes[-1]
            if padding_bits < 8:
                # Tambahkan bit dari byte terakhir kecuali padding
                byte = encoded_bytes[-2] if len(encoded_bytes) > 1 else 0
                for j in range(7, padding_bits - 1, -1):
                    bit = (byte >> j) & 1
                    bitstream.append(bit)
        
        # Decode bitstream menggunakan pohon Huffman
        decoded_pixels = []
        current_node = huffman_tree
        
        for bit in bitstream:
            if bit == 0:
                current_node = current_node.left
            else:
                current_node = current_node.right
            
            # Jika leaf node (tidak punya anak)
            if current_node is not None and current_node.left is None and current_node.right is None:
                decoded_pixels.append(current_node.value)
                current_node = huffman_tree  # Reset ke root
        
        # Pastikan jumlah pixel sesuai dengan dimensi
        expected_pixels = shape[0] * shape[1]
        
        if len(decoded_pixels) < expected_pixels:
            print(f"Warning: Pixel kurang. Got {len(decoded_pixels)}, expected {expected_pixels}")
            # Padding dengan nilai 0 jika kurang
            decoded_pixels.extend([0] * (expected_pixels - len(decoded_pixels)))
        elif len(decoded_pixels) > expected_pixels:
            print(f"Warning: Pixel berlebih. Got {len(decoded_pixels)}, expected {expected_pixels}")
            # Potong jika berlebih
            decoded_pixels = decoded_pixels[:expected_pixels]
        
        # Konversi ke array 2D untuk gambar
        # Perhatikan shape: Django mengharapkan (height, width)
        decoded_image = np.array(decoded_pixels, dtype=np.uint8).reshape(shape)
        
        return decoded_image
    
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error in huffman_decode: {e}")
        raise

def fix_base64_padding(base64_string):
    """Memperbaiki padding base64 jika tidak lengkap"""
    # Base64 harus memiliki panjang yang merupakan kelipatan 4
    missing_padding = len(base64_string) % 4
    if missing_padding:
        base64_string += '=' * (4 - missing_padding)
    return base64_string



# KOMPRESI HUFFMAN (MENJADIKAN DECODE)
# Endpoint untuk menerima data dan melakukan dekompresi
@csrf_exempt
def upload_encoded_huffman_image(request):
    """
    Endpoint untuk menerima data kompresi Huffman dan melakukan dekompresi
    """
    import time
    start_time = time.time()

    if request.method != "POST":
        return HttpResponseBadRequest("Invalid method")

    try:
        # Tambahkan log untuk debugging
        print("Received request for Huffman decoding")
        
        # Ambil JSON dari body request
        data = json.loads(request.body)
        
        # Log data yang diterima
        print(f"Request data keys: {data.keys()}")
        
        mobile_timing = {
            'capture_time': data.get('capture_time'),
            'huffman_time': data.get('huffman_time'), 
            'sending_time': data.get('sending_time'),
            'total_mobile_time': data.get('total_mobile_time')
        }
        print(f"📱 Mobile timing: {mobile_timing}")

        # TAMBAHKAN INI: Ambil id_pegawai dari data
        id_pegawai = data.get("id_pegawai")
        is_rgb = data.get("is_rgb", False)
        print(f"Is RGB image: {is_rgb}")

        decode_start = time.time()
        
        if is_rgb:
            # PERUBAHAN: Terima data dengan format yang lebih sederhana
            print("Processing RGB image with simple format")
            
            # Ambil data
            shape = tuple(data.get("shape", [0, 0]))  # Fallback to [0, 0] if missing
            
            # PERBAIKAN: Periksa apakah semua data yang dibutuhkan tersedia
            required_keys = ['red_encoded', 'green_encoded', 'blue_encoded', 
                             'red_root', 'green_root', 'blue_root']
            for key in required_keys:
                if key not in data:
                    print(f"Missing required data: {key}")
                    return HttpResponseBadRequest(f"Missing required data: {key}")
            
            # Ambil encoded data dan root
            red_encoded = data.get("red_encoded", "")
            green_encoded = data.get("green_encoded", "")
            blue_encoded = data.get("blue_encoded", "")
            
            red_root_base64 = data.get("red_root", "")
            green_root_base64 = data.get("green_root", "")
            blue_root_base64 = data.get("blue_root", "")
            
            print(f"Received RGB data with shape: {shape}")
            print(f"Red encoded length: {len(red_encoded)}")
            print(f"Green encoded length: {len(green_encoded)}")
            print(f"Blue encoded length: {len(blue_encoded)}")
            
            # Fungsi untuk memperbaiki padding base64
            def fix_base64_padding(s):
                missing_padding = len(s) % 4
                if missing_padding:
                    s += '=' * (4 - missing_padding)
                return s
            
            # Decode data
            try:
                # Perbaiki padding dan decode base64
                red_root_base64 = fix_base64_padding(red_root_base64)
                green_root_base64 = fix_base64_padding(green_root_base64)
                blue_root_base64 = fix_base64_padding(blue_root_base64)
                
                red_root_bytes = base64.b64decode(red_root_base64)
                green_root_bytes = base64.b64decode(green_root_base64)
                blue_root_bytes = base64.b64decode(blue_root_base64)
                
                # Parse JSON untuk root
                red_root_json = red_root_bytes.decode('utf-8')
                green_root_json = green_root_bytes.decode('utf-8')
                blue_root_json = blue_root_bytes.decode('utf-8')
                
                red_root = json.loads(red_root_json)
                green_root = json.loads(green_root_json)
                blue_root = json.loads(blue_root_json)
                
                # Build Huffman trees
                red_huff_root = build_huffman_tree_from_json(red_root)
                green_huff_root = build_huffman_tree_from_json(green_root)
                blue_huff_root = build_huffman_tree_from_json(blue_root)
                
                # Dekode setiap channel
                print("Starting RGB channel decoding...")
                red_channel = huffman_decode(red_encoded, red_huff_root, shape)
                green_channel = huffman_decode(green_encoded, green_huff_root, shape)
                blue_channel = huffman_decode(blue_encoded, blue_huff_root, shape)
                
                # Gabungkan ketiga channel
                height, width = shape
                decoded_image = np.zeros((height, width, 3), dtype=np.uint8)
                decoded_image[:, :, 0] = blue_channel  # B channel (OpenCV uses BGR)
                decoded_image[:, :, 1] = green_channel # G channel
                decoded_image[:, :, 2] = red_channel   # R channel
                
                print(f"Successfully decoded RGB image with shape {decoded_image.shape}")
            except Exception as e:
                print(f"Error during RGB decoding: {e}")
                import traceback
                traceback.print_exc()
                return HttpResponseBadRequest(f"Error during RGB decoding: {e}")
            
        else:
        # 1. Proses encoded_data
            encoded_data = data["encoded_data"]
            print(f"Encoded data type: {type(encoded_data)}")
            print(f"Encoded data length (base64): {len(encoded_data)}")
            
            # 2. Proses shape - harus list/tuple [height, width]
            shape = tuple(data["shape"])
            print(f"Shape: {shape}")
            
            # 3. Proses root
            root_base64 = data["root"]
            print(f"Root base64 length: {len(root_base64)}")
            
            # Decode root dari base64
            try:
                root_bytes = base64.b64decode(root_base64)
                print(f"Root bytes length after base64 decode: {len(root_bytes)}")
                
                # Coba parse sebagai pickle
                try:
                    huff_root = pickle.loads(root_bytes)
                    print("Successfully decoded root using pickle")
                except Exception as pickle_error:
                    print(f"Pickle error: {pickle_error}")
                    
                    # Jika gagal, coba parse sebagai JSON
                    try:
                        root_json = root_bytes.decode('utf-8')
                        root_data = json.loads(root_json)
                        print(f"Parsed root JSON. Type: {type(root_data)}")
                        
                        # Bangun pohon Huffman dari JSON
                        huff_root = build_huffman_tree_from_json(root_data)
                        print("Successfully built Huffman tree from JSON")
                    except Exception as json_error:
                        print(f"JSON parse error: {json_error}")
                        return HttpResponseBadRequest(f"Failed to parse root as JSON: {json_error}")
            except Exception as base64_error:
                print(f"Base64 decode error: {base64_error}")
                return HttpResponseBadRequest(f"Invalid base64 in root: {base64_error}")

            # Lakukan dekompresi Huffman
            print("Starting Huffman decode...")
            decoded_image = huffman_decode(encoded_data, huff_root, shape)
            print(f"Huffman decode complete. Image shape: {decoded_image.shape}")

            # Konversi dari grayscale (2D) ke BGR (3D) untuk konsistensi output
            if len(decoded_image.shape) == 2:
                decoded_image = cv2.cvtColor(decoded_image, cv2.COLOR_GRAY2BGR)
                print(f"Converted grayscale to BGR. New shape: {decoded_image.shape}")

        decode_time = time.time() - decode_start

        # Buat folder huffman_images jika belum ada
        output_dir = os.path.join(settings.MEDIA_ROOT, "huffman_images", str(id_pegawai))
        os.makedirs(output_dir, exist_ok=True)

        # Buat nama file berdasarkan waktu
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_decoded.jpg"
        save_path = os.path.join(output_dir, filename)

        # Simpan gambar
        cv2.imwrite(save_path, decoded_image)
        print(f"Image saved to: {save_path}")
        
        face_start = time.time()  # ✅ TIMER FACE PROCESSING
        
        # ✅ PASS TIMING DATA KE FACE_VECTOR
        result = face_vector(id_pegawai, save_path, mobile_timing)# Pass path gambar terbaru
        print(f"Face vector result: {result}")

        face_time = time.time() - face_start  # ✅ HITUNG WAKTU FACE
        total_server_time = time.time() - start_time  # ✅ TOTAL SERVER TIME
        
        print(f"⏱️ Server timing: decode={decode_time:.3f}s, face={face_time:.3f}s, total={total_server_time:.3f}s")

        # URL untuk akses gambar
        media_url = f"{settings.MEDIA_URL.rstrip('/')}/huffman_images/{id_pegawai}/{filename}"

        # PERBAIKAN: RETURN HASIL DARI FACE_VECTOR, BUKAN RESPONSE UPLOAD
        if result.get("success"):
            # Tambahkan info file ke hasil face_vector
            result["timing"] = {
                "mobile": mobile_timing,
                "server": {
                    "decode_time_ms": round(decode_time * 1000),
                    "face_processing_ms": round(face_time * 1000), 
                    "total_server_ms": round(total_server_time * 1000)
                }
            }
            result["filename"] = filename
            result["path"] = save_path 
            result["url"] = media_url
            
            print(f"🔧 DEBUG: Final response to send: {result}")
            return JsonResponse(result)
        else:
            # Jika face_vector gagal, return error
            print(f"❌ DEBUG: face_vector failed: {result}")
            return JsonResponse(result, status=400)

    except Exception as e:
        import traceback
        print(f"Error in upload_encoded_huffman_image: {e}")
        traceback.print_exc()
        return HttpResponseBadRequest(str(e))

@csrf_exempt
def handle_kompresi(request):
    if request.method == 'POST':
        try:
            # Coba parse data JSON
            data = json.loads(request.body)
            
            # Ekstrak data dari request
            encoded_data = data.get('encoded_data')
            root = data.get('root')
            shape = data.get('shape')
            timestamp = data.get('timestamp')
            user_id = data.get('user_id')
            
            # Validasi data
            if not encoded_data or not root or not shape:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Missing required data'
                }, status=400)
            
            # Decode base64 data
            decoded_data = base64.b64decode(encoded_data)
            
            # Buat direktori untuk menyimpan data (gunakan direktori yang Anda inginkan)
            kompresi_dir = os.path.join(settings.MEDIA_ROOT, 'kompresi')
            os.makedirs(kompresi_dir, exist_ok=True)
            
            # Buat nama file berdasarkan user ID dan timestamp
            filename = f"{user_id}_{timestamp}.bin"
            file_path = os.path.join(kompresi_dir, filename)
            
            # Simpan data ke file
            with open(file_path, 'wb') as f:
                f.write(decoded_data)
            
            # Simpan metadata ke database
            dimensions = shape.split('x')
            width = int(dimensions[0]) if len(dimensions) > 0 else 0
            height = int(dimensions[1]) if len(dimensions) > 1 else 0
            
            # Buat objek kompresi (sesuaikan dengan model Anda)
            kompresi = Kompresi.objects.create(
                user_id=user_id,
                file_path=file_path,
                root_data=root,
                shape=shape,
                width=width,
                height=height,
                timestamp=timestamp
            )
            
            return JsonResponse({
                'status': 'success',
                'message': 'Data kompresi berhasil disimpan',
                'kompresi_id': kompresi.id,
                'file_path': file_path
            })
            
        except json.JSONDecodeError:
            return JsonResponse({
                'status': 'error',
                'message': 'Invalid JSON format'
            }, status=400)
            
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'status': 'error',
        'message': 'Method not allowed'
    }, status=405)

# @csrf_exempt
# def kompresi_handler(request):
#     if request.method == 'POST':
#         try:

#             # Test: Log all incoming data
#             logger.info("Menerima POST request ke /sipreti/kompresi/")
#             logger.info(f"POST data keys: {request.POST.keys()}")
#             logger.info(f"FILES keys: {request.FILES.keys()}")
#             logger.info(f"Headers: {dict(request.headers)}")
#             logger.info(f"Content Type: {request.content_type}")

#             # Ambil data dari request
#             id_pegawai = request.POST.get('id_pegawai')
#             width = int(request.POST.get('width'))
#             height = int(request.POST.get('height'))
#             frequency_model = request.POST.get('frequency_model')
#             code_table = request.POST.get('code_table')
#             compression_type = request.POST.get('compression_type', 'huffman')
#             original_length = int(request.POST.get('original_length'))
                        
#             # Metrik kompresi
#             original_size = int(request.POST.get('original_size', 0))
#             compressed_size = int(request.POST.get('compressed_size', 0))
#             compression_ratio = float(request.POST.get('compression_ratio', 0.0))
#             compression_time_ms = int(request.POST.get('compression_time_ms', 0))
            
#             # Ambil file yang dikirim
#             compressed_file = request.FILES.get('compressed_file').read()
            
#             # Simpan data ke database
#             kompresi = KompresiHuffman(
#                 id_pegawai=id_pegawai,
#                 width=width,
#                 height=height,
#                 frequency_model=frequency_model,
#                 code_table=code_table,
#                 compressed_file=compressed_file,
#                 compression_type=compression_type,
#                 original_length=original_length,
#                 original_size=original_size,
#                 compressed_size=compressed_size,
#                 compression_ratio=compression_ratio,
#                 compression_time_ms=compression_time_ms
#             )
#             kompresi.save()
            
#             # Log informasi
#             logger.info(f"Menerima data kompresi: {id_pegawai}")
#             logger.info(f"Dimensi: {width}x{height}")
#             logger.info(f"Panjang bitstream: {len(compressed_file)} bytes")
#             logger.info(f"Rasio kompresi: {compression_ratio}x")
#             verification_result = None

#             try:
#                 # Panggil fungsi verifikasi langsung (bukan dalam thread)
#                 verification_result = verifikasi_dari_kompresi(request, kompresi.id)
#                 logger.info(f"Verifikasi otomatis berhasil untuk kompresi ID: {kompresi.id}")
#             except Exception as e:
#                 logger.error(f"Verifikasi otomatis gagal untuk kompresi ID: {kompresi.id}: {str(e)}")
#                 logger.error(f"Traceback: {traceback.format_exc()}")
            
#             return JsonResponse({
#                 'status': 'success',
#                 'message': 'Data kompresi berhasil disimpan dan verifikasi otomatis dijalankan',
#                 'kompresi_id': kompresi.id,
#                 'verification_result': verification_result.content.decode('utf-8') if hasattr(verification_result, 'content') else None
#             })
            
#         except Exception as e:
#             logger.error(f"Error menerima data kompresi: {e}")
#             return JsonResponse({
#                 'status': 'error',
#                 'message': str(e)
#             }, status=400)
    
#     return JsonResponse({
#         'status': 'error',
#         'message': 'Method tidak didukung'
#     }, status=405)

@require_GET
def get_decompressed_image(request, kompresi_id):
    """Endpoint untuk mendapatkan gambar hasil dekompresi"""
    try:
        # Ambil data kompresi dari database
        kompresi = KompresiHuffman.objects.get(id=kompresi_id)
        
        # Parse data frekuensi dan kode
        frequencies = json.loads(kompresi.frequency_model)
        code_table = json.loads(kompresi.code_table)
        
        # Log dimensi dan info kompresi
        logger.info(f"Dekompresi ID: {kompresi_id}, Dimensi: {kompresi.width}x{kompresi.height}")
        logger.info(f"Data kompresi: {len(kompresi.compressed_file)} bytes, Original: {kompresi.original_length} pixels")
        
        # Validasi dimensi
        if kompresi.width * kompresi.height != kompresi.original_length:
            logger.error(f"Dimensi tidak sesuai: {kompresi.width}x{kompresi.height}={kompresi.width*kompresi.height}, Original length: {kompresi.original_length}")
        
        # Rekonstruksi pohon Huffman
        root = build_huffman_tree(frequencies)
        
        # Validasi pohon Huffman
        leaf_count, is_valid = validate_huffman_tree(root)
        logger.info(f"Pohon Huffman - Leaf count: {leaf_count}, Valid: {is_valid}")
        
        # Dekode data terkompresi dengan handling error
        decoded_pixels = decode_huffman(
            kompresi.compressed_file, 
            root, 
            kompresi.original_length,
            kompresi.width,
            kompresi.height
        )
        
        # Reshape ke array 2D
        try:
            # Coba bentuk array sesuai dimensi (height, width)
            pixels_array = np.array(decoded_pixels, dtype=np.uint8).reshape(kompresi.height, kompresi.width)
            
            # Simpan gambar untuk analisa (saat development)
            debug_image = Image.fromarray(pixels_array, mode='L')
            debug_path = f"D:/ABSENSI DEVI/lancar/pemkot/media/debug_images/debug_{kompresi_id}.png"
            debug_image.save(debug_path)
            
            # Coba buat 3 variasi orientasi untuk mengatasi masalah rotasi
            # 1. Original
            image_original = Image.fromarray(pixels_array, mode='L')
            
            # 2. Rotasi 270° (mengembalikan dari quarterTurns: 1)
            image_rotated = image_original.rotate(270, expand=True)
            
            # 3. Flip horizontal (mengembalikan dari Matrix4.rotationY(3.14))
            image_flipped = ImageOps.mirror(image_original)
            
            # 4. Kombinasi rotasi dan flip
            image_combo = ImageOps.mirror(image_original.rotate(270, expand=True))
            
            # Simpan semua variasi untuk debug
            debug_paths = [
                f"D:/ABSENSI DEVI/lancar/pemkot/media/debug_images/original_{kompresi_id}.png",
                f"D:/ABSENSI DEVI/lancar/pemkot/media/debug_images/rotated_{kompresi_id}.png",
                f"D:/ABSENSI DEVI/lancar/pemkot/media/debug_images/flipped_{kompresi_id}.png",
                f"D:/ABSENSI DEVI/lancar/pemkot/media/debug_images/combo_{kompresi_id}.png"
            ]
            
            image_original.save(debug_paths[0])
            image_rotated.save(debug_paths[1])
            image_flipped.save(debug_paths[2])
            image_combo.save(debug_paths[3])
            
            # Gunakan gambar rotated & flipped (kemungkinan yang benar)
            image = image_combo
            
            # Respons dengan gambar PNG
            response = HttpResponse(content_type="image/png")
            image.save(response, "PNG")
            
            return response
            
        except Exception as e:
            logger.error(f"Error saat reshape array: {e}")
            logger.error(traceback.format_exc())
            return HttpResponseServerError(f"Error saat membentuk gambar: {e}")
        
    except KompresiHuffman.DoesNotExist:
        return HttpResponseNotFound(f"Data kompresi ID {kompresi_id} tidak ditemukan")
    except Exception as e:
        logger.error(f"Error umum: {e}")
        logger.error(traceback.format_exc())
        return HttpResponseServerError(f"Error umum: {e}")










@csrf_exempt
@require_http_methods(["GET", "POST"])
def compare_images(request, kompresi_id):
    """Endpoint untuk membandingkan gambar asli dengan hasil dekompresi"""
    
    try:
        # Ambil data kompresi
        kompresi = KompresiHuffman.objects.get(id=kompresi_id)
        
        # 1. Dapatkan gambar hasil dekompresi
        # Parse frekuensi model
        frequencies = json.loads(kompresi.frequency_model)
        # Bangun pohon Huffman
        root = build_huffman_tree(frequencies)
        # Dekode data kompresi
        compressed_data = kompresi.compressed_file
        # Decode Huffman
        decoded_pixels = decode_huffman(
            compressed_data, 
            root, 
            kompresi.original_length
        )
        # Ubah list pixel menjadi array numpy
        decoded_array = np.array(decoded_pixels, dtype=np.uint8)
        decoded_image = decoded_array.reshape((kompresi.height, kompresi.width))
        
        # 2. Ambil gambar asli dari database (atau file)
        # Asumsikan gambar asli disimpan di model Pegawai
        try:
            pegawai = Pegawai.objects.get(id=kompresi.id_pegawai)
            # Asumsi: pegawai memiliki field image_binary (data gambar asli)
            original_image_bytes = pegawai.image_binary
            
            # Konversi gambar asli ke array
            original_image = Image.open(io.BytesIO(original_image_bytes))
            original_array = np.array(original_image.convert('L'))
            
        except Pegawai.DoesNotExist:
            logger.error(f"Pegawai dengan ID {kompresi.id_pegawai} tidak ditemukan")
            return JsonResponse({
                'status': 'error',
                'message': 'Pegawai tidak ditemukan'
            }, status=404)
        
        # 3. Bandingkan gambar
        # Metode 1: Pixel-by-pixel comparison
        if original_array.shape != decoded_image.shape:
            logger.error(f"Ukuran gambar berbeda! Original: {original_array.shape}, Decoded: {decoded_image.shape}")
            return JsonResponse({
                'status': 'error',
                'message': 'Ukuran gambar tidak sama'
            }, status=400)
        
        # Hitung perbedaan pixel
        pixel_diff = np.abs(original_array.astype(np.int16) - decoded_image.astype(np.int16))
        num_different_pixels = np.count_nonzero(pixel_diff)
        total_pixels = original_array.size
        
        # Metode 2: Structural Similarity Index (SSIM)
        from skimage.metrics import structural_similarity as ssim
        ssim_index = ssim(original_array, decoded_image)
        
        # Metode 3: Mean Squared Error (MSE)
        mse = np.mean((original_array - decoded_image) ** 2)
        
        # Metode 4: Peak Signal-to-Noise Ratio (PSNR)
        if mse > 0:
            psnr = 20 * np.log10(255.0 / np.sqrt(mse))
        else:
            psnr = float('inf')  # Perfect match
        
        # 4. Return hasil perbandingan
        comparison_result = {
            'status': 'success',
            'kompresi_id': kompresi_id,
            'dimensions': {
                'width': kompresi.width,
                'height': kompresi.height
            },
            'metrics': {
                'different_pixels': int(num_different_pixels),
                'total_pixels': int(total_pixels),
                'pixel_accuracy': float(1 - (num_different_pixels / total_pixels)),
                'ssim': float(ssim_index),
                'mse': float(mse),
                'psnr': float(psnr)
            },
            'is_identical': num_different_pixels == 0
        }
        
        # Simpan atau log hasil perbandingan
        logger.info(f"Perbandingan gambar untuk ID {kompresi_id}:")
        logger.info(f"Pixel berbeda: {num_different_pixels} dari {total_pixels}")
        logger.info(f"SSIM: {ssim_index:.4f}")
        logger.info(f"PSNR: {psnr:.2f} dB")
        
        return JsonResponse(comparison_result)
        
    except KompresiHuffman.DoesNotExist:
        logger.error(f"KompresiHuffman dengan ID {kompresi_id} tidak ditemukan")
        return JsonResponse({
            'status': 'error',
            'message': 'Data kompresi tidak ditemukan'
        }, status=404)
        
    except Exception as e:
        logger.error(f"Error membandingkan gambar: {e}")
        return JsonResponse({
            'status': 'error',
            'message': str(e)
        }, status=500)

def unit_kerja_list(request):
    radius_aktif = RadiusAbsen.objects.filter(is_active=True).first()

    if radius_aktif:
        # Update semua unit kerja untuk pakai radius aktif
        UnitKerja.objects.update(radius=radius_aktif) 

    data = list(UnitKerja.objects.select_related('radius').values(
        'id_unit_kerja', 
        'nama_unit_kerja', 
        'latitude',
        'longitude',
        'radius',
    ))
    
    # Ganti nama key agar tetap 'radius'
    for item in data:
        item['radius'] = radius_aktif.ukuran if radius_aktif else 0
    
    return JsonResponse(data, safe=False)

@api_view(['GET'])
def jabatan_list(request):
    data = list(Jabatan.objects.values('id_jabatan', 'nama_jabatan'))
    return JsonResponse(data, safe=False)

def get_detail_json(request, id):
    try:
        radius = RadiusAbsen.objects.get(pk=id)
        data = {
            'id': radius.id,
            'radius': radius.radius,
            'satuan': radius.satuan
        }
        return JsonResponse(data)
    except RadiusAbsen.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)
    
logger = logging.getLogger(__name__)

class HuffmanNode:
    def __init__(self, value=None, frequency=0, left=None, right=None):
        self.value = value  # Nilai pixel (0-255) atau None untuk node internal
        self.frequency = frequency  # Frekuensi kemunculan
        self.left = left
        self.right = right

def build_huffman_tree(frequencies):
    """Membangun pohon Huffman dari frekuensi"""
    # Konversi dictionary frekuensi ke list node
    nodes = []
    for value, freq in frequencies.items():
        nodes.append(HuffmanNode(value=int(value), frequency=freq))
    
    # Proses nodes sampai hanya tersisa satu node (root)
    while len(nodes) > 1:
        # Urutkan nodes berdasarkan frekuensi
        nodes.sort(key=lambda node: node.frequency)
        
        # Ambil dua node dengan frekuensi terendah
        left = nodes.pop(0)
        right = nodes.pop(0)
        
        # Buat node baru dengan children dari dua node tadi
        parent = HuffmanNode(
            value=None,
            frequency=left.frequency + right.frequency,
            left=left,
            right=right
        )
        
        # Tambahkan node baru ke list
        nodes.append(parent)
    
    # Kembalikan root dari pohon Huffman
    return nodes[0] if nodes else None

# Fungsi verifikasi dari kompresi
def verifikasi_dari_kompresi(request, kompresi_id):
    """
    Melakukan verifikasi wajah dari data kompresi Huffman
    """
    kompresi = get_object_or_404(KompresiHuffman, id=kompresi_id)
    
    # Cek apakah ada hasil uncompress
    if not kompresi.hasil_uncompress:
        raise Exception("Tidak ada hasil uncompress. Lakukan uncompress terlebih dahulu.")
    
    # Catat waktu mulai
    start_time = time.time()
    
    # Waktu dekompresi (anggap 0 karena sudah dilakukan sebelumnya)
    dekompresi_ms = 0
    
    # Lakukan verifikasi wajah - simulasikan proses
    # Ganti kode di bawah ini dengan algoritma verifikasi wajah yang sebenarnya
    # Contoh sederhana: Anggap verifikasi selalu berhasil dengan nilai kecocokan 0.9
    is_verified = True
    nilai_kecocokan = 0.9
    
    # Hitung waktu verifikasi
    verifikasi_ms = int((time.time() - start_time) * 1000)
    
    # Simpan log verifikasi
    log = LogVerifikasi(
        kompresi=kompresi,
        status_verifikasi=is_verified,
        nilai_kecocokan=nilai_kecocokan,
        waktu_dekompresi_ms=dekompresi_ms,
        waktu_verifikasi_ms=verifikasi_ms
    )
    log.save()
    
    # Jika request ada (dipanggil dari admin), tambahkan pesan sukses
    if request:
        messages.success(request, f"Verifikasi berhasil dengan nilai kecocokan {nilai_kecocokan:.2f}")
    
    return {
        'status': is_verified,
        'nilai_kecocokan': nilai_kecocokan,
        'waktu_verifikasi_ms': verifikasi_ms
    }

def validate_compression_data(data):
    """
    Memvalidasi format data kompresi yang diterima dari mobile.
    
    Args:
        data: Dictionary berisi data kompresi yang diterima
        
    Returns:
        (bool, str): Tuple berisi status validasi (True/False) dan pesan (kosong jika valid, pesan error jika tidak valid)
    """
    required_fields = ['id_pegawai', 'width', 'height', 'compressed_file', 
                      'frequency_model', 'original_length']
    
    # Cek field yang required
    for field in required_fields:
        if field not in data or data[field] is None:
            return False, f"Field '{field}' tidak ditemukan atau null"
    
    # Validasi tipe data
    try:
        width = int(data['width'])
        height = int(data['height'])
        original_length = int(data['original_length'])
        
        if width <= 0 or height <= 0:
            return False, f"Dimensi gambar tidak valid: {width}x{height}"
        
        if original_length <= 0:
            return False, f"Panjang original tidak valid: {original_length}"
        
        # Cek kecocokan dimensi dengan original_length
        expected_length = width * height
        is_rgb = data.get('is_rgb', False)
        if is_rgb:
            expected_length *= 3
            
        if original_length != expected_length:
            return False, f"Ketidakcocokan dimensi: {width}x{height} {'(RGB)' if is_rgb else ''} seharusnya memiliki {expected_length} piksel, tapi dilaporkan {original_length}"
        
        # Validasi frequency_model
        frequency_model = data['frequency_model']
        if not isinstance(frequency_model, dict) and not isinstance(frequency_model, str):
            return False, "Format frequency_model tidak valid"
            
        # Jika frequency_model adalah string, coba parse sebagai JSON
        if isinstance(frequency_model, str):
            try:
                import json
                frequency_model = json.loads(frequency_model)
            except json.JSONDecodeError:
                return False, "Gagal mem-parse frequency_model sebagai JSON"
        
        # Cek isi frequency_model (harus berisi key numerik)
        for key in frequency_model:
            try:
                int_key = int(key)
                if int_key < 0 or int_key > 255:
                    return False, f"Nilai key dalam frequency_model ({key}) di luar range valid (0-255)"
            except ValueError:
                return False, f"Key dalam frequency_model ({key}) bukan nilai numerik yang valid"
        
        # Validasi compressed_file
        compressed_file = data['compressed_file']
        if not compressed_file or len(compressed_file) == 0:
            return False, "Data terkompresi kosong"
            
        # Jika sampai di sini, semua validasi berhasil
        return True, ""
        
    except (ValueError, TypeError) as e:
        return False, f"Error validasi format data: {str(e)}"

# API endpoint untuk menerima data kompresi dari mobile
@api_view(['POST'])
# def receive_compression(request):
#     try:
#         # Ambil data dari request
#         id_pegawai = request.data.get('id_pegawai')
#         width = request.data.get('width')
#         height = request.data.get('height')
#         compressed_file = request.data.get('compressed_file')
#         frequency_model = request.data.get('frequency_model')
#         original_length = request.data.get('original_length')
#         is_rgb = request.data.get('is_rgb', False)
        
#         # Hitung ukuran asli dan terkompresi
#         original_size = original_length * (3 if is_rgb else 1)
#         compressed_size = len(compressed_file) if compressed_file else 0
        
#         # Hitung rasio kompresi
#         compression_ratio = original_size / compressed_size if compressed_size > 0 else 0
        
#         # Simpan data kompresi
#         kompresi = KompresiHuffman(
#             id_pegawai=id_pegawai,
#             width=width,
#             height=height,
#             compressed_file=compressed_file,
#             frequency_model=frequency_model,
#             original_length=original_length,
#             original_size=original_size,
#             compressed_size=compressed_size,
#             compression_ratio=compression_ratio,
#             is_rgb=is_rgb
#         )
#         kompresi.save()  # Ini akan memicu signal post_save yang melakukan uncompress dan verifikasi otomatis
        
#         # Respons sukses
#         return Response({
#             'status': 'success',
#             'message': 'Data kompresi berhasil diterima dan sedang diproses',
#             'kompresi_id': kompresi.id
#         }, status=status.HTTP_201_CREATED)
        
#     except Exception as e:
#         import traceback
#         logger.error(f"Error saat menerima data kompresi: {str(e)}")
#         logger.error(traceback.format_exc())
#         return Response({
#             'status': 'error',
#             'message': f'Gagal memproses data kompresi: {str(e)}'
#         }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def receive_compression(request):
    try:
        # Ambil data dari request
        id_pegawai = request.data.get('id_pegawai')
        width = int(request.data.get('width'))
        height = int(request.data.get('height'))
        compressed_file = request.data.get('compressed_file')
        
        # Parse frequency_model (key string ke int)
        frequency_model_str = request.data.get('frequency_model')
        if isinstance(frequency_model_str, str):
            frequency_model = json.loads(frequency_model_str)
        else:
            frequency_model = frequency_model_str
            
        # Parse code_table
        code_table_str = request.data.get('code_table')
        if isinstance(code_table_str, str):
            code_table = json.loads(code_table_str)
        else:
            code_table = code_table_str
            
        original_length = int(request.data.get('original_length'))
        is_rgb = request.data.get('is_rgb', False)
        
        # Simpan data kompresi
        kompresi = KompresiHuffman(
            id_pegawai=id_pegawai,
            width=width,
            height=height,
            compressed_file=compressed_file,
            frequency_model=json.dumps(frequency_model),  # Konversi ke string JSON
            code_table=json.dumps(code_table),  # Simpan code_table jika perlu
            original_length=original_length,
            original_size=int(request.data.get('original_size', 0)),
            compressed_size=int(request.data.get('compressed_size', 0)),
            compression_ratio=float(request.data.get('compression_ratio', 0)),
            is_rgb=is_rgb
        )
        kompresi.save()

        # Respons sukses
        return Response({
            'status': 'success',
            'message': 'Data kompresi berhasil diterima dan sedang diproses',
            'kompresi_id': kompresi.id
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        import traceback
        logger.error(f"Error saat menerima data kompresi: {str(e)}")
        logger.error(traceback.format_exc())
        return Response({
            'status': 'error',
            'message': f'Gagal memproses data kompresi: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)

        
        

def bytes_to_bits(byte_data, padding):
    """Konversi bytes ke list bit, dengan memperhatikan padding bit terakhir"""
    bits = []
    
    # Proses semua byte kecuali yang terakhir (info padding)
    for i in range(len(byte_data) - 1):
        byte = byte_data[i]
        for j in range(7, -1, -1):  # MSB ke LSB
            bits.append(1 if (byte & (1 << j)) else 0)
    
    # Hapus bit padding di akhir sesuai dengan byte padding
    if padding > 0 and len(bits) > padding:
        bits = bits[:-padding]
    
    return bits

def decode_huffman(compressed_data, root, original_length):
    """Dekode bitstream Huffman menggunakan pohon Huffman"""
    # Ambil padding dari byte terakhir
    padding = compressed_data[-1]
    
    # Konversi bytestream ke bitstream
    bits = bytes_to_bits(compressed_data[:-1], padding)
    
    # Dekode bitstream
    decoded_pixels = []
    node = root
    
    for bit in bits:
        # Traverse pohon sesuai bit
        if bit == 0:
            node = node.left
        else:
            node = node.right
        
        # Jika mencapai leaf node, tambahkan nilai ke hasil dan reset ke root
        if node and node.value is not None:
            decoded_pixels.append(node.value)
            node = root
            
            # Jika sudah mencapai panjang original, berhenti
            if len(decoded_pixels) >= original_length:
                break
    
    # Pastikan hasil dekompresi sesuai dengan panjang original
    if len(decoded_pixels) < original_length:
        # Jika kurang, tambahkan piksel hitam (0)
        decoded_pixels.extend([0] * (original_length - len(decoded_pixels)))
    elif len(decoded_pixels) > original_length:
        # Jika lebih, potong kelebihan
        decoded_pixels = decoded_pixels[:original_length]
    
    return decoded_pixels

def validate_huffman_tree(root):
    """Validasi struktur dan integritas pohon Huffman"""
    if root is None:
        return 0, False
    
    # Fungsi rekursif untuk traversal dan validasi
    def _count_leaf_nodes(node):
        if node is None:
            return 0
        
        # Jika leaf node (memiliki nilai)
        if node.value is not None:
            return 1
        
        # Jika internal node, harus memiliki kedua child
        if node.left is None or node.right is None:
            raise ValueError("Invalid Huffman tree: internal node missing child")
        
        # Rekursif ke child nodes
        return _count_leaf_nodes(node.left) + _count_leaf_nodes(node.right)
    
    try:
        leaf_count = _count_leaf_nodes(root)
        return leaf_count, True
    except ValueError as e:
        logger.error(f"Validasi pohon Huffman gagal: {e}")
        return 0, False
    
def visualize_byte_patterns(pixel_data, width, height, filename):
    """Simpan visualisasi pola byte untuk debugging"""
    from matplotlib import pyplot as plt
    import numpy as np
    
    # Reshape ke gambar 2D
    try:
        image_array = np.array(pixel_data, dtype=np.uint8).reshape(height, width)
        
        # Plot heatmap
        plt.figure(figsize=(10, 10))
        plt.imshow(image_array, cmap='gray')
        plt.colorbar(label='Pixel Value')
        plt.title(f'Pixel Value Distribution ({width}x{height})')
        plt.savefig(filename)
        plt.close()
        
        # Plot histogram
        plt.figure(figsize=(10, 6))
        plt.hist(pixel_data, bins=256, range=(0, 255), density=True)
        plt.title('Pixel Value Histogram')
        plt.xlabel('Pixel Value')
        plt.ylabel('Frequency')
        plt.savefig(filename.replace('.png', '_histogram.png'))
        plt.close()
        
        return True
    except Exception as e:
        logger.error(f"Visualization error: {e}")
        return False
    

def verify_image_data(decoded_pixels, width, height):
    """Verifikasi apakah data gambar valid"""
    # Cek jumlah piksel
    if len(decoded_pixels) != width * height:
        logger.error(f"Pixel count mismatch: got {len(decoded_pixels)}, expected {width*height}")
        return False
    
    # Cek range nilai piksel
    min_val = min(decoded_pixels)
    max_val = max(decoded_pixels)
    if min_val < 0 or max_val > 255:
        logger.error(f"Pixel value range invalid: min={min_val}, max={max_val}")
        return False
    
    # Cek distribusi nilai (gambar valid biasanya memiliki distribusi nilai yang bervariasi)
    unique_values = len(set(decoded_pixels))
    if unique_values < 10:  # Terlalu sedikit nilai unik mungkin menandakan error
        logger.warning(f"Low pixel diversity: only {unique_values} unique values")
    
    # Cek koherensi spasial (pixel tetangga seharusnya serupa dalam kebanyakan gambar)
    spatial_coherence = calculate_spatial_coherence(decoded_pixels, width, height)
    logger.info(f"Spatial coherence: {spatial_coherence:.2f}")
    
    return True

def calculate_spatial_coherence(pixels, width, height):
    """Hitung koherensi spasial sebagai metrik kualitas gambar"""
    import numpy as np
    
    # Reshape ke 2D
    image = np.array(pixels, dtype=np.float32).reshape(height, width)
    
    # Hitung perbedaan dengan piksel tetangga
    h_diff = np.abs(image[:, 1:] - image[:, :-1]).mean()
    v_diff = np.abs(image[1:, :] - image[:-1, :]).mean()
    
    # Rata-rata perbedaan (lebih rendah = lebih koheren)
    avg_diff = (h_diff + v_diff) / 2
    
    # Normalisasi (0-1, dimana 1 = sangat koheren)
    max_possible_diff = 255.0
    coherence = 1.0 - (avg_diff / max_possible_diff)
    
    return coherence


@csrf_exempt
def kompresi_handler(request):
    if request.method == 'POST':
        try:
            import logging
            logger = logging.getLogger(__name__)
            logger.info("Menerima POST request ke /sipreti/kompresi/")
            
            # Ambil data dari request
            id_pegawai = request.POST.get('id_pegawai')
            width = int(request.POST.get('width'))
            height = int(request.POST.get('height'))
            frequency_model = request.POST.get('frequency_model')
            code_table = request.POST.get('code_table')
            compression_type = request.POST.get('compression_type', 'huffman')
            original_length = int(request.POST.get('original_length'))
            
            # Metrik kompresi
            original_size = int(request.POST.get('original_size', 0))
            compressed_size = int(request.POST.get('compressed_size', 0))
            compression_ratio = float(request.POST.get('compression_ratio', 0.0))
            compression_time_ms = int(request.POST.get('compression_time_ms', 0))
            
            # Ambil file yang dikirim
            compressed_file = request.FILES.get('compressed_file').read()
            
            # Simpan data ke database
            kompresi = KompresiHuffman(
                id_pegawai=id_pegawai,
                width=width,
                height=height,
                frequency_model=frequency_model,
                code_table=code_table,
                compressed_file=compressed_file,
                compression_type=compression_type,
                original_length=original_length,
                original_size=original_size,
                compressed_size=compressed_size,
                compression_ratio=compression_ratio,
                compression_time_ms=compression_time_ms
            )
            kompresi.save()
            
            # Log informasi
            logger.info(f"Menerima data kompresi: {id_pegawai}")
            logger.info(f"Dimensi: {width}x{height}")
            logger.info(f"Panjang bitstream: {len(compressed_file)} bytes")
            logger.info(f"Rasio kompresi: {compression_ratio}x")
            
            return JsonResponse({
                'status': 'success',
                'message': 'Data kompresi berhasil disimpan',
                'kompresi_id': kompresi.id
            })
            
        except Exception as e:
            logger.error(f"Error menerima data kompresi: {e}")
            logger.error(traceback.format_exc())
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            }, status=400)
    
    return JsonResponse({
        'status': 'error',
        'message': 'Method tidak didukung'
    }, status=405)

@require_GET
def get_decompressed_image(request, kompresi_id):
    """Endpoint untuk mendapatkan gambar yang sudah didekode"""
    logger.info(f"Request GET /sipreti/dekompresi/{kompresi_id}/")
    
    try:
        # Ambil data kompresi dari database
        kompresi = KompresiHuffman.objects.get(id=kompresi_id)
        
        # Tambahan logging untuk debug
        logger.info(f"ID: {kompresi_id}, Width: {kompresi.width}, Height: {kompresi.height}")
        logger.info(f"Original Length: {kompresi.original_length}, Compressed size: {len(kompresi.compressed_file)}")
        
        # Parse frekuensi model
        frequencies = json.loads(kompresi.frequency_model)
        
        # Bangun pohon Huffman
        root = build_huffman_tree(frequencies)
        
        # Dekode data kompresi
        compressed_data = kompresi.compressed_file
        
        # Tambahan check byte terakhir (padding)
        padding_value = compressed_data[-1]
        logger.info(f"Padding value: {padding_value}")
        
        # Decode Huffman
        decoded_pixels = decode_huffman(compressed_data, root, kompresi.original_length)
        
        # Verifikasi hasil dekompresi
        if not verify_image_data(decoded_pixels, kompresi.width, kompresi.height):
            logger.warning("Normal decompression produced invalid image, trying alternative method")
            # Coba metode alternatif
            decoded_pixels = alternative_decode_huffman(compressed_data, root, kompresi.original_length)
        
        # Simpan visualisasi untuk analisis
        debug_path = f"/tmp/debug_image_{kompresi_id}"
        visualize_byte_patterns(decoded_pixels, kompresi.width, kompresi.height, f"{debug_path}_pattern.png")
        
        # Kirim respons gambar
        response = HttpResponse(content_type="image/png")
        image.save(response, "PNG")
        
        return response
        
    except KompresiHuffman.DoesNotExist:
        return HttpResponseServerError(f"Data kompresi dengan ID {kompresi_id} tidak ditemukan.")
    except Exception as e:
        logger.error(f"Error menampilkan hasil dekompresi: {str(e)}")
        logger.error(traceback.format_exc())
        return HttpResponseServerError(f"Terjadi kesalahan: {str(e)}")

logger = logging.getLogger(__name__)
def tampilkan_hasil_dekompresi(request, kompresi_id):
    try:
        # Import model KompresiHuffman (pastikan nama ini sesuai dengan di models.py)
        from .models import KompresiHuffman
        
        # Dapatkan objek kompresi
        kompresi = get_object_or_404(KompresiHuffman, id=kompresi_id)
        
        # Periksa apakah hasil uncompress sudah ada
        if kompresi.hasil_uncompress and hasattr(kompresi.hasil_uncompress, 'path'):
            file_path = kompresi.hasil_uncompress.path
            
            # Periksa apakah file ada
            if os.path.exists(file_path):
                # Baca file gambar
                with open(file_path, 'rb') as f:
                    image_data = f.read()
                
                # Return sebagai respons HTTP
                return HttpResponse(image_data, content_type='image/png')
            else:
                print(f"[VIEW] File tidak ditemukan: {file_path}", file=sys.stderr)
        
        # Jika hasil uncompress belum ada, lakukan uncompress on-the-fly
        print(f"[VIEW] Hasil uncompress belum ada, melakukan uncompress...", file=sys.stderr)
        
        # Import admin class untuk memanggil uncompress_object
        from .admin import KompresiHuffmanAdmin
        
        # Buat instance admin dan lakukan uncompress
        admin_instance = KompresiHuffmanAdmin(KompresiHuffman, None)
        image = admin_instance.uncompress_object(None, kompresi_id)
        
        # Konversi gambar ke format HTTP response
        if isinstance(image, Image.Image):
            buffer = BytesIO()
            image.save(buffer, format='PNG')
            buffer.seek(0)
            return HttpResponse(buffer.getvalue(), content_type='image/png')
        
        # Jika uncompress berhasil tapi tidak menghasilkan gambar, coba ambil dari file
        if kompresi.hasil_uncompress and hasattr(kompresi.hasil_uncompress, 'path'):
            file_path = kompresi.hasil_uncompress.path
            if os.path.exists(file_path):
                with open(file_path, 'rb') as f:
                    image_data = f.read()
                return HttpResponse(image_data, content_type='image/png')
        
        # Jika semua cara gagal, return 404
        print(f"[VIEW] Tidak dapat menemukan atau menghasilkan gambar untuk ID {kompresi_id}", file=sys.stderr)
        return HttpResponseNotFound("Gambar hasil dekompresi tidak ditemukan")
        
    except Exception as e:
        import traceback
        print(f"[VIEW] Error saat menampilkan hasil dekompresi ID {kompresi_id}: {str(e)}", file=sys.stderr)
        print(traceback.format_exc(), file=sys.stderr)
        return HttpResponse(f"Error: {str(e)}", status=500)


def halaman_verifikasi(request, kompresi_id=None):
    """
    Halaman web sederhana untuk melakukan verifikasi wajah dari data kompresi.
    """
    # Ambil semua data kompresi
    kompresi_data = KompresiHuffman.objects.all().order_by('-created_at')
    
    # Jika kompresi_id disediakan, pilih data tersebut
    kompresi_terpilih = None
    if kompresi_id:
        kompresi_terpilih = get_object_or_404(KompresiHuffman, id=kompresi_id)
    
    context = {
        'kompresi_data': kompresi_data,
        'kompresi_terpilih': kompresi_terpilih,
    }
    
    return render(request, 'verifikasi_wajah.html', context)

def pegawai_list_view(request):
    """Tampilan daftar pegawai dengan biometrik"""
    # Ambil pegawai yang memiliki biometrik
    pegawai_dengan_biometrik = Pegawai.objects.filter(
        id_pegawai__in=Biometrik.objects.values_list('id_pegawai', flat=True).distinct()
    )
    
    # Dapatkan jumlah biometrik untuk setiap pegawai
    pegawai_dengan_jumlah = []
    for pegawai in pegawai_dengan_biometrik:
        biometriks = Biometrik.objects.filter(id_pegawai=pegawai)
        
        # Buat HTML untuk gambar
        thumbnail_html = '<div style="display: flex; flex-wrap: wrap; gap: 5px;">'
        for bm in biometriks[:5]:  # Tampilkan maksimal 5 gambar
            if bm.image:
                thumbnail_html += f"""
                <a href="/admin/sipreti/biometrik/{bm.id}/change/">
                    <img src="{bm.image.url}" 
                         style="width: 60px; height: 60px; object-fit: cover; border-radius: 4px;"
                         title="{bm.name}" />
                </a>
                """
        
        # Tambahkan teks jika ada lebih banyak gambar
        if biometriks.count() > 5:
            thumbnail_html += f'<div style="display: flex; align-items: center; margin-left: 5px;">+{biometriks.count() - 5} lainnya</div>'
        
        thumbnail_html += '</div>'
        
        # Buat HTML untuk tombol proses
        process_button = f"""
        <a href="/sipreti/biometrikpegawaigroup/{pegawai.id_pegawai}/process/" 
           class="button" 
           style="display: inline-block; background-color: #417690; color: white; 
                  padding: 5px 10px; border-radius: 4px; text-decoration: none;">
            Proses Semua Wajah
        </a>
        """
        
        # Tambahkan tombol untuk melihat daftar biometrik
        view_button = f"""
        <a href="/admin/sipreti/biometrik/?id_pegawai__id_pegawai={pegawai.id_pegawai}" 
           class="button" 
           style="display: inline-block; background-color: #79aec8; color: white; 
                  padding: 5px 10px; border-radius: 4px; text-decoration: none; margin-left: 5px;">
            Lihat Detail
        </a>
        """
        
        pegawai_dengan_jumlah.append({
            'pegawai': pegawai,
            'jumlah': biometriks.count(),
            'thumbnails': mark_safe(thumbnail_html),
            'action_buttons': mark_safe(process_button + view_button)
        })
    
    # Siapkan data untuk template
    context = {
        'title': 'Biometrik (Dikelompokkan berdasarkan Pegawai)',
        'cl': {
            'result_count': len(pegawai_dengan_jumlah),
            'full_result_count': len(pegawai_dengan_jumlah),
            'result_list': pegawai_dengan_jumlah,
        },
        'headers': ['ID', 'Nama Pegawai', 'Jumlah Foto', 'Preview', 'Tindakan'],
    }
    
    # Tangani filter dan pencarian jika ada
    query = request.GET.get('q')
    if query:
        pegawai_dengan_jumlah = [p for p in pegawai_dengan_jumlah 
                                 if query.lower() in p['pegawai'].nama.lower() or
                                    query in str(p['pegawai'].id_pegawai)]
        context['cl']['result_count'] = len(pegawai_dengan_jumlah)
        context['cl']['result_list'] = pegawai_dengan_jumlah
    
    # Render halaman
    return render(request, 'biometrik_pegawai_list.html', context)

def process_all_view(request, pegawai_id):
    """Proses semua foto untuk satu pegawai"""
    try:
        # Dapatkan pegawai
        pegawai = get_object_or_404(Pegawai, id_pegawai=pegawai_id)
        
        # Ambil semua biometrik untuk pegawai
        biometriks = Biometrik.objects.filter(id_pegawai=pegawai)
        
        if not biometriks.exists():
            messages.warning(request, f"Tidak ada data biometrik untuk pegawai {pegawai.nama}")
            return redirect('/sipreti/biometrikpegawaigroup/')
        
        # Dapatkan URL semua gambar
        url_image_array = [request.build_absolute_uri(bm.image.url) for bm in biometriks if bm.image]
        
        # Proses semua wajah
        success = add_face(url_image_array, str(pegawai_id))
        
        # Tampilkan pesan hasil
        if success:
            messages.success(request, f"Berhasil memproses {len(url_image_array)} foto wajah untuk pegawai {pegawai.nama}")
        else:
            messages.error(request, f"Gagal memproses foto wajah untuk pegawai {pegawai.nama}. Pastikan wajah terlihat jelas.")
            
        return redirect('/sipreti/biometrikpegawaigroup/')
        
    except Exception as e:
        messages.error(request, f"Terjadi kesalahan: {str(e)}")
        return redirect('/sipreti/biometrikpegawaigroup/')
    


# KOMPRESI ARITHMETIC
logger = logging.getLogger(__name__)

class ArithmeticDecoder:
    """Class untuk melakukan dekode arithmetic coding"""
    
    def __init__(self, compressed_data, frequency_table, message_length):
        self.compressed_data = compressed_data  # Data terkompresi
        self.frequency_table = frequency_table  # Tabel frekuensi
        self.message_length = message_length  # Panjang pesan asli
        
        # Hitung total frekuensi dan probability ranges
        self.total_frequency = sum(frequency_table.values())
        self.probability_range = self._calculate_probability_range()
    
    def _calculate_probability_range(self):
        """Menghitung rentang probabilitas untuk setiap symbol"""
        probability_range = {}
        
        # Track batas bawah untuk setiap symbol
        lower_bound = 0.0
        
        # Urutkan symbol untuk konsistensi
        sorted_symbols = sorted(self.frequency_table.keys())
        
        # Hitung probability range untuk setiap symbol
        for symbol in sorted_symbols:
            freq = self.frequency_table[symbol]
            
            # Batas bawah adalah nilai dari lower_bound
            # Batas atas adalah lower_bound + (freq / total)
            upper_bound = lower_bound + (freq / self.total_frequency)
            
            # Simpan range untuk symbol ini
            probability_range[symbol] = (lower_bound, upper_bound)
            
            # Update lower_bound untuk symbol berikutnya
            lower_bound = upper_bound
        
        return probability_range
    
    def decode(self):
        """Decode the compressed data using arithmetic coding algorithm"""
        # Parse the encoded value (we assume it's stored as a float)
        encoded_value = float(self.compressed_data)
        
        decoded_message = []
        
        # Decode each symbol
        for _ in range(self.message_length):
            # Find which symbol is at the encoded value
            symbol = self._find_symbol(encoded_value)
            
            # Add the symbol to the decoded message
            decoded_message.append(int(symbol))
            
            # Update the encoded value
            lower_bound, upper_bound = self.probability_range[symbol]
            range_width = upper_bound - lower_bound
            
            # Scale encoded_value for the next iteration
            encoded_value = (encoded_value - lower_bound) / range_width
        
        return decoded_message
    
    def _find_symbol(self, value):
        """Find which symbol corresponds to the given value"""
        for symbol, (lower, upper) in self.probability_range.items():
            if lower <= value < upper:
                return symbol
        
        # Edge case: if value exactly equals 1.0
        for symbol, (lower, upper) in self.probability_range.items():
            if lower <= value <= upper:
                return symbol
        
        raise ValueError(f"Could not find symbol for value {value}")


@csrf_exempt
@require_GET
def get_decompressed_arithmetic_image(request, kompresi_id):
    """Endpoint untuk mendapatkan gambar yang sudah didekode dengan arithmetic coding"""
    logger.info(f"=== DEKOMPRESI ARITHMETIC DEBUG ===")
    logger.info(f"Method: {request.method}")
    logger.info(f"URL: {request.build_absolute_uri()}")
    logger.info(f"Headers: {dict(request.headers)}")
    logger.info(f"Kompresi ID: {kompresi_id}")
    logger.info(f"User Agent: {request.META.get('HTTP_USER_AGENT', 'Unknown')}")
    
    # Handle OPTIONS request untuk CORS
    if request.method == 'OPTIONS':
        response = HttpResponse()
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Content-Type'
        return response
    
    try:
        # Convert kompresi_id to int (just to be safe)
        kompresi_id = int(kompresi_id)
        
        # Log untuk debugging
        logger.info(f"Request GET /sipreti/dekompresi_arithmetic/{kompresi_id}/")
        
        # Ambil data kompresi dari database
        kompresi = KompresiArithmetic.objects.get(id=kompresi_id)
        
        if request.method == 'HEAD':
            response = HttpResponse(content_type='image/png')
            response['Access-Control-Allow-Origin'] = '*'
            # Optionally add content length estimate
            response['Content-Length'] = '50000'  # Perkiraan ukuran
            return response
        
        # Parse frequency model
        frequency_model = json.loads(kompresi.frequency_model)
        
        # Dekode data kompresi dengan arithmetic decoder
        compressed_data = kompresi.compressed_file.decode('utf-8') if isinstance(kompresi.compressed_file, bytes) else kompresi.compressed_file
        
        # Buat decoder arithmetic
        decoder = ArithmeticDecoder(
            compressed_data=compressed_data,
            frequency_table=frequency_model,
            message_length=kompresi.original_length
        )
        
        # Decode data
        decoded_pixels = decoder.decode()
        
        # Ubah list pixel menjadi array numpy
        pixels_array = np.array(decoded_pixels, dtype=np.uint8)
        
        # Reshape image
        image_array = pixels_array.reshape((kompresi.height, kompresi.width))
        mode = 'L'  # Grayscale
        
        # Buat gambar dari array
        image = Image.fromarray(image_array, mode=mode)
        
        # Return as image response
        response = HttpResponse(content_type="image/png")
        image.save(response, "PNG")
        
        print(f"Dekompresi arithmetic berhasil untuk ID: {kompresi_id}", file=sys.stderr)
        return response
        
    except KompresiArithmetic.DoesNotExist:
        return HttpResponseServerError(f"Data kompresi arithmetic dengan ID {kompresi_id} tidak ditemukan.")
    except Exception as e:
        logger.error(f"Error menampilkan hasil dekompresi arithmetic: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        return HttpResponseServerError(f"Terjadi kesalahan: {str(e)}")


@csrf_exempt
@require_POST
def verifikasi_dari_kompresi_arithmetic(request, kompresi_id):
    """
    Fungsi untuk melakukan dekompresi dan verifikasi wajah dari data kompresi arithmetic.
    """
    try:
        # 1. Ambil data kompresi dari database
        logger.info(f"Memulai verifikasi untuk kompresi arithmetic ID: {kompresi_id}")
        start_time = time.time()
        
        try:
            kompresi = KompresiArithmetic.objects.get(id=kompresi_id)
        except KompresiArithmetic.DoesNotExist:
            return JsonResponse({
                'status': 0, 
                'message': f"Data kompresi arithmetic dengan ID {kompresi_id} tidak ditemukan."
            })
        
        id_pegawai = kompresi.id_pegawai
        
        # Cek apakah pegawai ada di database
        biometrik = Biometrik.objects.filter(id_pegawai=id_pegawai)
        if not biometrik.exists():
            return JsonResponse({
                'status': 0, 
                'message': f"Data biometrik untuk pegawai ID {id_pegawai} tidak ditemukan."
            })
        
        # 2. Dekode data kompresi menjadi gambar
        logger.info(f"Memulai proses dekompresi arithmetic untuk ID: {kompresi_id}")
        dekompresi_start = time.time()
        
        # Parse model frekuensi
        frequency_model = json.loads(kompresi.frequency_model)
        
        # Buat decoder arithmetic
        compressed_data = kompresi.compressed_file.decode('utf-8') if isinstance(kompresi.compressed_file, bytes) else kompresi.compressed_file
        
        decoder = ArithmeticDecoder(
            compressed_data=compressed_data,
            frequency_table=frequency_model,
            message_length=kompresi.original_length
        )
        
        # Decode data
        decoded_pixels = decoder.decode()
        
        # Ubah list pixel menjadi array numpy
        pixels_array = np.array(decoded_pixels, dtype=np.uint8)
        
        # Reshape array sesuai dimensi gambar
        image_array = pixels_array.reshape((kompresi.height, kompresi.width))
        
        # Buat gambar dari array
        image = Image.fromarray(image_array, mode='L')
        
        dekompresi_time = time.time() - dekompresi_start
        logger.info(f"Dekompresi arithmetic selesai dalam {dekompresi_time:.2f} detik")
        
        # 3. Simpan gambar sementara
        folder_path = os.path.join('verification', str(id_pegawai))
        file_name = f"decompressed_arithmetic_{kompresi_id}_{int(time.time())}.png"
        
        # Konversi gambar ke bytes
        img_byte_arr = BytesIO()
        image.save(img_byte_arr, format='PNG')
        img_byte_arr.seek(0)
        
        # Simpan gambar ke folder verification/<id_pegawai>/
        saved_path = default_storage.save(
            os.path.join(folder_path, file_name),
            ContentFile(img_byte_arr.getvalue())
        )
        
        image_url = os.path.join(settings.MEDIA_ROOT, saved_path)
        logger.info(f"Gambar hasil dekompresi arithmetic disimpan di: {image_url}")
        
        # 4. Verifikasi wajah dengan fungsi yang sudah ada
        try:
            logger.info(f"Memulai verifikasi wajah untuk pegawai ID: {id_pegawai}")
            verifikasi_start = time.time()
            
            # Import main.py yang berisi fungsi verify_face
            from .face_recognition import main
            cek_image = main.verify_face(image_url, id_pegawai)
            
            verifikasi_time = time.time() - verifikasi_start
            logger.info(f"Verifikasi selesai dalam {verifikasi_time:.2f} detik")
            
            # Siapkan variabel untuk nilai kecocokan
            nilai_kecocokan_value = None
            if isinstance(cek_image, tuple) and len(cek_image) > 1:
                nilai_kecocokan_value = cek_image[1]
                
            # Buat entri log
            log = LogVerifikasiArithmetic.objects.create(
                kompresi_id=kompresi.id,
                status_verifikasi=bool(cek_image),
                nilai_kecocokan=nilai_kecocokan_value,
                waktu_dekompresi_ms=int(dekompresi_time * 1000),
                waktu_verifikasi_ms=int(verifikasi_time * 1000)
            )
            
            if cek_image:
                logger.info(f"Verifikasi BERHASIL untuk pegawai ID: {id_pegawai}")
                response = {
                    'status': 1, 
                    'message': "Wajah terverifikasi (COCOK)",
                    'kompresi_id': kompresi_id,
                    'id_pegawai': id_pegawai,
                    'dekompresi_time_ms': int(dekompresi_time * 1000),
                    'verifikasi_time_ms': int(verifikasi_time * 1000),
                    'total_time_ms': int((time.time() - start_time) * 1000)
                }
                
                if nilai_kecocokan_value is not None:
                    response['nilai_kecocokan'] = nilai_kecocokan_value
            else:
                logger.warning(f"Verifikasi GAGAL untuk pegawai ID: {id_pegawai}")
                response = {
                    'status': 0, 
                    'message': "Wajah tidak terverifikasi (TIDAK COCOK)",
                    'kompresi_id': kompresi_id,
                    'id_pegawai': id_pegawai,
                    'dekompresi_time_ms': int(dekompresi_time * 1000),
                    'verifikasi_time_ms': int(verifikasi_time * 1000),
                    'total_time_ms': int((time.time() - start_time) * 1000)
                }
                
                if nilai_kecocokan_value is not None:
                    response['nilai_kecocokan'] = nilai_kecocokan_value
                    
        finally:
            # 5. Hapus gambar sementara
            if os.path.exists(image_url):
                os.remove(image_url)
                logger.info(f"Gambar sementara dihapus: {image_url}")
        
        # 6. Cek jika request berasal dari halaman admin, redirect kembali
        if request.META.get('HTTP_REFERER') and 'admin' in request.META.get('HTTP_REFERER', ''):
            from django.shortcuts import redirect
            return redirect(f'/admin/sipreti/kompresiarithmetic/{kompresi_id}/change/')
        
        # 7. Return hasil verifikasi sebagai JSON
        return JsonResponse(response)
        
    except Exception as e:
        logger.error(f"Error pada verifikasi dari kompresi arithmetic: {str(e)}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        
        # Cek jika request berasal dari halaman admin, redirect kembali
        if request.META.get('HTTP_REFERER') and 'admin' in request.META.get('HTTP_REFERER', ''):
            from django.shortcuts import redirect
            from django.contrib import messages
            messages.error(request, f"Gagal melakukan verifikasi arithmetic: {str(e)}")
            return redirect(f'/admin/sipreti/kompresiarithmetic/{kompresi_id}/change/')
        
        return JsonResponse({
            'status': 0, 
            'message': f"Terjadi kesalahan: {str(e)}",
            'kompresi_id': kompresi_id,
            'id_pegawai': id_pegawai if 'id_pegawai' in locals() else None,
            'error_detail': traceback.format_exc()
        }, status=500)


@require_GET
def tampilkan_hasil_dekompresi_arithmetic(request, kompresi_id):
    """
    Fungsi untuk menampilkan hasil dekompresi arithmetic sebagai gambar.
    Berguna untuk debugging atau menampilkan gambar di halaman web.
    """
    if kompresi_id is None or kompresi_id == 'None':
        # Return gambar default
        return HttpResponse("ID kompresi tidak valid", content_type="text/plain", status=400)
    
    try:
        print(f"Memulai dekompresi arithmetic untuk ID: {kompresi_id}", file=sys.stderr)
        # Ambil data kompresi dari database
        kompresi = KompresiArithmetic.objects.get(id=kompresi_id)
        
        # Parse frequency model
        frequency_model = json.loads(kompresi.frequency_model)
        
        # Buat decoder arithmetic
        compressed_data = kompresi.compressed_file.decode('utf-8') if isinstance(kompresi.compressed_file, bytes) else kompresi.compressed_file
        
        decoder = ArithmeticDecoder(
            compressed_data=compressed_data,
            frequency_table=frequency_model,
            message_length=kompresi.original_length
        )
        
        # Decode data
        decoded_pixels = decoder.decode()
        
        # Ubah list pixel menjadi array numpy
        pixels_array = np.array(decoded_pixels, dtype=np.uint8)
        
        # Reshape array sesuai dimensi gambar
        image_array = pixels_array.reshape((kompresi.height, kompresi.width))
        
        # Buat gambar dari array
        image = Image.fromarray(image_array, mode='L')
        
        # Konversi gambar ke HTTP response
        response = HttpResponse(content_type="image/png")
        image.save(response, "PNG")
    
        print(f"Dekompresi arithmetic berhasil untuk ID: {kompresi_id}", file=sys.stderr)
        return response
        
    except KompresiArithmetic.DoesNotExist:
        return HttpResponseServerError(f"Data kompresi arithmetic dengan ID {kompresi_id} tidak ditemukan.")
    except Exception as e:
        logger.error(f"Error menampilkan hasil dekompresi arithmetic: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        return HttpResponseServerError(f"Terjadi kesalahan: {str(e)}")


@csrf_exempt
@require_http_methods(["GET", "POST"])
def compare_arithmetic_images(request, kompresi_id):
    """Endpoint untuk membandingkan gambar asli dengan hasil dekompresi arithmetic"""
    
    try:
        # Ambil data kompresi
        kompresi = KompresiArithmetic.objects.get(id=kompresi_id)
        
        # 1. Dapatkan gambar hasil dekompresi arithmetic
        # Parse model frekuensi
        frequency_model = json.loads(kompresi.frequency_model)
        
        # Buat decoder arithmetic
        compressed_data = kompresi.compressed_file.decode('utf-8') if isinstance(kompresi.compressed_file, bytes) else kompresi.compressed_file
        
        decoder = ArithmeticDecoder(
            compressed_data=compressed_data,
            frequency_table=frequency_model,
            message_length=kompresi.original_length
        )
        
        # Decode data
        decoded_pixels = decoder.decode()
        
        # Ubah list pixel menjadi array numpy
        decoded_array = np.array(decoded_pixels, dtype=np.uint8)
        decoded_image = decoded_array.reshape((kompresi.height, kompresi.width))
        
        # 2. Ambil gambar asli dari database (atau file)
        # Asumsikan gambar asli disimpan di model Pegawai
        try:
            pegawai = Pegawai.objects.get(id=kompresi.id_pegawai)
            # Asumsi: pegawai memiliki field image_binary (data gambar asli)
            original_image_bytes = pegawai.image_binary
            
            # Konversi gambar asli ke array
            original_image = Image.open(BytesIO(original_image_bytes))
            original_array = np.array(original_image.convert('L'))
            
        except Pegawai.DoesNotExist:
            logger.error(f"Pegawai dengan ID {kompresi.id_pegawai} tidak ditemukan")
            return JsonResponse({
                'status': 'error',
                'message': 'Pegawai tidak ditemukan'
            }, status=404)
        
        # 3. Bandingkan gambar
        # Metode 1: Pixel-by-pixel comparison
        if original_array.shape != decoded_image.shape:
            logger.error(f"Ukuran gambar berbeda! Original: {original_array.shape}, Decoded: {decoded_image.shape}")
            return JsonResponse({
                'status': 'error',
                'message': 'Ukuran gambar tidak sama'
            }, status=400)
        
        # Hitung perbedaan pixel
        pixel_diff = np.abs(original_array.astype(np.int16) - decoded_image.astype(np.int16))
        num_different_pixels = np.count_nonzero(pixel_diff)
        total_pixels = original_array.size
        
        # Metode 2: Structural Similarity Index (SSIM)
        from skimage.metrics import structural_similarity as ssim
        ssim_index = ssim(original_array, decoded_image)
        
        # Metode 3: Mean Squared Error (MSE)
        mse = np.mean((original_array - decoded_image) ** 2)
        
        # Metode 4: Peak Signal-to-Noise Ratio (PSNR)
        if mse > 0:
            psnr = 20 * np.log10(255.0 / np.sqrt(mse))
        else:
            psnr = float('inf')  # Perfect match
        
        # 4. Return hasil perbandingan
        comparison_result = {
            'status': 'success',
            'kompresi_id': kompresi_id,
            'dimensions': {
                'width': kompresi.width,
                'height': kompresi.height
            },
            'metrics': {
                'different_pixels': int(num_different_pixels),
                'total_pixels': int(total_pixels),
                'pixel_accuracy': float(1 - (num_different_pixels / total_pixels)),
                'ssim': float(ssim_index),
                'mse': float(mse),
                'psnr': float(psnr)
            },
            'is_identical': num_different_pixels == 0
        }
        
        # Simpan atau log hasil perbandingan
        logger.info(f"Perbandingan gambar arithmetic untuk ID {kompresi_id}:")
        logger.info(f"Pixel berbeda: {num_different_pixels} dari {total_pixels}")
        logger.info(f"SSIM: {ssim_index:.4f}")
        logger.info(f"PSNR: {psnr:.2f} dB")
        
        return JsonResponse(comparison_result)
        
    except KompresiArithmetic.DoesNotExist:
        logger.error(f"KompresiArithmetic dengan ID {kompresi_id} tidak ditemukan")
        return JsonResponse({
            'status': 'error',
            'message': 'Data kompresi arithmetic tidak ditemukan'
        }, status=404)
        
    except Exception as e:
        logger.error(f"Error membandingkan gambar arithmetic: {e}")
        return JsonResponse({
            'status': 'error',
            'message': str(e)
        }, status=500)


def halaman_verifikasi_arithmetic(request, kompresi_id=None):
    """
    Halaman web sederhana untuk melakukan verifikasi wajah dari data kompresi arithmetic.
    """
    # Ambil semua data kompresi
    kompresi_data = KompresiArithmetic.objects.all().order_by('-created_at')
    
    # Jika kompresi_id disediakan, pilih data tersebut
    kompresi_terpilih = None
    if kompresi_id:
        kompresi_terpilih = get_object_or_404(KompresiArithmetic, id=kompresi_id)
    
    context = {
        'kompresi_data': kompresi_data,
        'kompresi_terpilih': kompresi_terpilih,
    }
    
    return render(request, 'verifikasi_wajah_arithmetic.html', context)



def process_and_compress_image(image_file, id_pegawai):
    """
    Mengkonversi gambar ke grayscale dan melakukan kompresi dengan algoritma Huffman
    
    Args:
        image_file: File gambar yang diunggah
        id_pegawai: ID pegawai pemilik gambar
        
    Returns:
        tuple: (image_url, kompresi_id) - URL gambar asli yang disimpan dan ID data kompresi
    """
    # Baca gambar menggunakan PIL
    image = Image.open(image_file)
    
    # Konversi ke grayscale
    gray_image = image.convert('L')
    
    # Simpan gambar grayscale ke folder media/biometrik/<id_pegawai>/
    folder_path = os.path.join('biometrik', str(id_pegawai))
    file_name = f"gray_{int(time.time())}_{image_file.name}"
    
    # Simpan gambar grayscale sementara ke buffer
    img_buffer = io.BytesIO()
    gray_image.save(img_buffer, format='PNG')
    img_buffer.seek(0)
    
    # Simpan gambar grayscale ke storage
    saved_path = default_storage.save(os.path.join(folder_path, file_name), ContentFile(img_buffer.getvalue()))
    image_url = os.path.join(settings.MEDIA_URL, saved_path)
    
    # Kompresi dengan algoritma Huffman
    # Ambil data pixel dari gambar grayscale
    pixel_array = np.array(gray_image)
    height, width = pixel_array.shape
    pixels = pixel_array.flatten()  # Ubah 2D array menjadi 1D
    original_length = len(pixels)
    
    # Hitung frekuensi setiap nilai pixel (0-255)
    frequencies = {}
    for pixel in pixels:
        pixel_val = int(pixel)
        if pixel_val in frequencies:
            frequencies[pixel_val] += 1
        else:
            frequencies[pixel_val] = 1
    
    # Bangun pohon Huffman dan tabel kode
    root = build_huffman_tree(frequencies)
    code_table = build_huffman_code_table(root)
    
    # Kompresi data pixel
    compressed_data, padding = compress_data(pixels, code_table)
    
    # Tambahkan informasi padding ke akhir data
    compressed_bytes = compressed_data + bytes([padding])
    
    # Hitung metrik kompresi
    original_size = original_length
    compressed_size = len(compressed_bytes)
    compression_ratio = original_size / compressed_size if compressed_size > 0 else 0
    
    # Simpan data kompresi ke database
    kompresi = KompresiHuffman(
        id_pegawai=id_pegawai,
        width=width,
        height=height,
        frequency_model=json.dumps(frequencies),
        code_table=json.dumps(code_table),
        compressed_file=compressed_bytes,
        compression_type='huffman',
        original_length=original_length,
        original_size=original_size,
        compressed_size=compressed_size,
        compression_ratio=compression_ratio
    )
    kompresi.save()
    
    # Log informasi kompresi
    logger.info(f"Gambar berhasil dikonversi ke grayscale dan dikompresi (ID: {kompresi.id})")
    logger.info(f"Dimensi: {width}x{height}, Rasio kompresi: {compression_ratio:.2f}x")
    
    return image_url, kompresi.id

def build_huffman_code_table(root):
    """Membangun tabel kode Huffman dari pohon Huffman"""
    codes = {}
    
    def traverse(node, code):
        # Jika node adalah leaf, simpan kode
        if node.value is not None:
            codes[node.value] = code
            return
        
        # Traverse ke kiri dengan menambahkan '0'
        if node.left:
            traverse(node.left, code + '0')
        
        # Traverse ke kanan dengan menambahkan '1'
        if node.right:
            traverse(node.right, code + '1')
    
    # Mulai traversal dari root dengan kode kosong
    if root:
        traverse(root, '')
    
    return codes

def compress_data(pixels, code_table):
    """Kompresi data pixel menggunakan tabel kode Huffman"""
    # Gabungkan semua kode bit
    bitstream = ''
    for pixel in pixels:
        bitstream += code_table[int(pixel)]
    
    # Hitung padding yang diperlukan
    padding = 8 - (len(bitstream) % 8) if len(bitstream) % 8 != 0 else 0
    
    # Tambahkan padding
    bitstream += '0' * padding
    
    # Konversi bitstream ke bytes
    bytes_array = bytearray()
    for i in range(0, len(bitstream), 8):
        byte = bitstream[i:i+8]
        bytes_array.append(int(byte, 2))
    
    return bytes(bytes_array), padding


# pencocokan threshold
from scipy.spatial.distance import euclidean

def compare_files(request):
    """
    API view untuk membandingkan file dengan jarak Euclidean.
    Terima parameter file1 dan file2 (path ke file) melalui GET atau POST.
    """
    file1_path = request.GET.get('file1') or request.POST.get('file1')
    file2_path = request.GET.get('file2') or request.POST.get('file2')
    
    if not file1_path or not file2_path:
        return JsonResponse({'error': 'Harap berikan path untuk kedua file'}, status=400)
    
    try:
        # Hitung jarak Euclidean
        distance = calculate_euclidean_distance(file1_path, file2_path)
        
        return JsonResponse({
            'success': True,
            'file1': file1_path,
            'file2': file2_path,
            'euclidean_distance': float(distance)
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def calculate_euclidean_distance(file1_path, file2_path):
    """
    Fungsi untuk menghitung jarak Euclidean antara dua file
    """
    # Load data dari file
    vector1 = load_file_data(file1_path)
    vector2 = load_file_data(file2_path)
    
    # Pastikan kedua vektor memiliki panjang yang sama
    min_length = min(len(vector1), len(vector2))
    vector1 = vector1[:min_length]
    vector2 = vector2[:min_length]
    
    # Hitung jarak Euclidean
    distance = euclidean(vector1, vector2)
    return distance

def load_file_data(file_path):
    """
    Fungsi untuk memuat data dari file.
    Sesuaikan fungsi ini berdasarkan format file Anda.
    """
    # PENTING: Sesuaikan bagian ini sesuai dengan jenis file Anda
    # Contoh untuk file teks
    with open(file_path, 'rb') as file:  # Gunakan 'rb' untuk file biner
        data = file.read()
    
    # Ubah data menjadi vektor numerik
    # Untuk file biner, kita bisa langsung menggunakan byte values
    if isinstance(data, bytes):
        vector = np.frombuffer(data, dtype=np.uint8)
    else:
        vector = np.array([ord(char) for char in data])
    
    return vector


from scipy.spatial.distance import euclidean
from PIL import Image
import numpy as np
import os
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt

@csrf_exempt
@require_http_methods(["GET"])
def compare_images_euclidean(request):
    """
    API endpoint untuk membandingkan dua gambar dengan jarak Euclidean.
    Contoh penggunaan: /sipreti/compare-euclidean/?path1=/path/to/image1.png&path2=/path/to/image2.png
    """
    path1 = request.GET.get('path1')
    path2 = request.GET.get('path2')
    
    if not path1 or not path2:
        return JsonResponse({
            'status': 'error',
            'message': 'Harap berikan parameter path1 dan path2'
        }, status=400)
    
    path1 = fix_path_format(path1)
    path2 = fix_path_format(path2)
    
    error_paths = []
    if not os.path.exists(path1) or not os.path.isfile(path1):
        error_paths.append(path1)
    
    if not os.path.exists(path2) or not os.path.isfile(path2):
        error_paths.append(path2)
    
    if error_paths:
        return JsonResponse({
            'status': 'error',
            'message': f'File tidak ditemukan: {", ".join(error_paths)}',
            'detail': {
                'missing_files': error_paths,
                'checked_paths': [path1, path2]
            }
        }, status=404)
    
    try:
        # Panggil fungsi perbandingan yang telah diperbaiki
        result = compare_images_improved(path1, path2)
        
        # Pastikan semua nilai NumPy dikonversi ke tipe Python standard
        result = convert_numpy_types(result)
        
        return JsonResponse({
            'status': 'success',
            **result
        })
    except Exception as e:
        import traceback
        error_detail = traceback.format_exc()
        print(f"Error comparing images: {str(e)}")
        print(error_detail)
        return JsonResponse({
            'status': 'error',
            'message': str(e),
            'error_detail': error_detail
        }, status=500)

def convert_numpy_types(obj):
    """
    Konversi semua tipe data NumPy ke tipe data Python standard
    """
    import numpy as np
    
    if isinstance(obj, dict):
        return {k: convert_numpy_types(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_numpy_types(v) for v in obj]
    elif isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return convert_numpy_types(obj.tolist())
    elif isinstance(obj, (np.bool_, np.bool)):
        return bool(obj)
    else:
        return obj

def fix_path_format(path):
    """
    Perbaiki format path untuk Windows:
    1. Hapus leading slash jika ada
    2. Convert forward slash ke backslash jika di Windows
    """
    import os
    # Hapus trailing slash jika ada
    if path.startswith('/'):
        path = path[1:]
    
    # Convert forward slash ke backslash di Windows
    if os.name == 'nt':  # 'nt' adalah Windows
        path = path.replace('/', '\\')
    
    return path

def compare_images_improved(image1_path, image2_path, target_size=(256, 256)):
    """
    Membandingkan dua gambar wajah dengan menggunakan histogram similarity
    sebagai metode utama untuk keputusan akhir
    """
    import numpy as np
    from PIL import Image
    from scipy.spatial.distance import euclidean
    import os
    
    try:
        # Buka gambar
        img1 = Image.open(image1_path)
        img2 = Image.open(image2_path)
        
        # Konversi ke grayscale
        if img1.mode != 'L':
            img1 = img1.convert('L')
        if img2.mode != 'L':
            img2 = img2.convert('L')
        
        # Dapatkan dimensi asli
        original_size1 = img1.size
        original_size2 = img2.size
        
        # Resize kedua gambar ke ukuran target yang sama
        img1_resized = img1.resize(target_size, Image.LANCZOS)
        img2_resized = img2.resize(target_size, Image.LANCZOS)
        
        # Konversi ke array NumPy dan flatten
        arr1 = np.array(img1_resized).flatten()
        arr2 = np.array(img2_resized).flatten()
        
        # Hitung jarak Euclidean (tetap dihitung untuk informasi)
        distance = float(euclidean(arr1, arr2))
        
        # Hitung similarity (nilai 0-1, 1 = identik)
        max_possible_distance = 255.0 * np.sqrt(arr1.size)
        
        # Normalisasi jarak ke 0-1 (1 = paling berbeda)
        normalized_distance = distance / max_possible_distance
        
        # Konversi ke persentase kemiripan (0-100%)
        similarity_percentage = float((1.0 - normalized_distance) * 100)
        
        # Definisikan threshold Euclidean (tetap ada untuk informasi)
        distance_threshold = 0.6  # Normalized distance <= 0.6 untuk dianggap cocok
        percentage_threshold = 70.0  # Similarity percentage >= 70% untuk dianggap cocok
        
        # Keputusan berdasarkan threshold Euclidean (tetap ada untuk informasi)
        is_similar_by_distance = normalized_distance <= distance_threshold
        is_similar_by_percentage = similarity_percentage >= percentage_threshold
        
        # Hitung histogram untuk masing-masing gambar
        hist1 = np.histogram(np.array(img1), bins=50)[0]
        hist2 = np.histogram(np.array(img2), bins=50)[0]
        
        # Normalisasi histogram
        hist1 = hist1.astype(float) / hist1.sum() if hist1.sum() > 0 else hist1
        hist2 = hist2.astype(float) / hist2.sum() if hist2.sum() > 0 else hist2
        
        # Hitung jarak histogram
        hist_distance = float(np.sqrt(((hist1 - hist2) ** 2).sum()))
        hist_similarity = float(1.0 - hist_distance) if hist_distance <= 1.0 else 0.0
        hist_similarity_percentage = hist_similarity * 100
        
        # Definisikan threshold untuk histogram similarity
        hist_threshold = 0.7  # Histogram similarity >= 0.7 untuk dianggap cocok
        hist_percentage_threshold = 70.0  # Histogram percentage >= 70% untuk dianggap cocok
        
        # Keputusan berdasarkan histogram
        is_similar_by_hist = hist_similarity >= hist_threshold
        is_similar_by_hist_percentage = hist_similarity_percentage >= hist_percentage_threshold
        
        # PERUBAHAN: Keputusan final menggunakan histogram
        is_similar = is_similar_by_hist and is_similar_by_hist_percentage
        
        # Info tambahan
        aspect_ratio1 = original_size1[0] / original_size1[1] if original_size1[1] > 0 else 0
        aspect_ratio2 = original_size2[0] / original_size2[1] if original_size2[1] > 0 else 0
        
        return {
            "image1": os.path.basename(image1_path),
            "image2": os.path.basename(image2_path),
            "original_size1": original_size1,
            "original_size2": original_size2,
            "aspect_ratio1": float(aspect_ratio1),
            "aspect_ratio2": float(aspect_ratio2),
            "target_size": target_size,
            
            # Metrik Euclidean (hanya untuk informasi)
            "euclidean_distance": float(distance),
            "max_possible_distance": float(max_possible_distance),
            "normalized_distance": float(normalized_distance),
            "distance_threshold": float(distance_threshold),
            "similarity_percentage": float(similarity_percentage),
            "percentage_threshold": float(percentage_threshold),
            "is_similar_by_distance": bool(is_similar_by_distance),
            "is_similar_by_percentage": bool(is_similar_by_percentage),
            
            # Metrik histogram (sekarang digunakan untuk keputusan)
            "histogram_similarity": float(hist_similarity),
            "histogram_threshold": float(hist_threshold),
            "histogram_percentage": float(hist_similarity_percentage),
            "histogram_percentage_threshold": float(hist_percentage_threshold),
            "is_similar_by_hist": bool(is_similar_by_hist),
            "is_similar_by_hist_percentage": bool(is_similar_by_hist_percentage),
            
            # Keputusan final berdasarkan histogram
            "is_similar": bool(is_similar),
            "conclusion": "COCOK" if is_similar else "TIDAK COCOK"
        }
    except Exception as e:
        import traceback
        print(f"Error in compare_images_improved: {str(e)}")
        print(traceback.format_exc())
        raise

@csrf_exempt
@require_http_methods(["GET"])
def check_file_exists(request):
    """
    API untuk mengecek apakah file ada sebelum mencoba membandingkan
    """
    paths = request.GET.getlist('path')
    
    if not paths:
        return JsonResponse({
            'status': 'error',
            'message': 'Harap berikan minimal satu parameter path'
        }, status=400)
    
    results = []
    for path in paths:
        results.append({
            'path': path,
            'exists': os.path.exists(path) and os.path.isfile(path),
            'is_directory': os.path.exists(path) and os.path.isdir(path),
            'size': os.path.getsize(path) if os.path.exists(path) and os.path.isfile(path) else None,
            'timestamp': os.path.getmtime(path) if os.path.exists(path) else None
        })
    
    return JsonResponse({
        'status': 'success',
        'files_checked': len(paths),
        'results': results
    })


# KOMPRESI RLE
@csrf_exempt
def kompresi_rle(request):
    if request.method == 'POST':
        try:
            id_pegawai = request.POST.get('id_pegawai')
            width = int(request.POST.get('width'))
            height = int(request.POST.get('height'))
            original_length = int(request.POST.get('original_length'))
            compression_type = request.POST.get('compression_type')
            
            # Metrik kompresi
            original_size = int(request.POST.get('original_size', 0))
            compressed_size = int(request.POST.get('compressed_size', 0))
            compression_ratio = float(request.POST.get('compression_ratio', 1.0))
            compression_time_ms = int(request.POST.get('compression_time_ms', 0))
            
            # Field yang mungkin kosong untuk RLE
            frequency_model = request.POST.get('frequency_model', '{}')
            code_table = request.POST.get('code_table', '{}')
            
            # Cek apakah file ada
            if 'compressed_file' not in request.FILES:
                return JsonResponse({
                    'status': 'error',
                    'message': 'No compressed file provided'
                }, status=400)
            
            compressed_file = request.FILES['compressed_file']
            
            # Cek apakah ini RGB atau grayscale
            is_rgb = request.POST.get('is_rgb', '') == 'true'
            
            # Buat dan simpan objek kompresi
            kompresi = Kompresi(
                id_pegawai=id_pegawai,
                width=width,
                height=height,
                original_length=original_length,
                compression_type=compression_type,
                original_size=original_size,
                compressed_size=compressed_size,
                compression_ratio=compression_ratio,
                compression_time_ms=compression_time_ms,
                frequency_model=json.loads(frequency_model),
                code_table=json.loads(code_table),
                is_rgb=is_rgb,
                compressed_file=compressed_file
            )
            kompresi.save()
            
            return JsonResponse({
                'status': 'success',
                'kompresi_id': kompresi.id
            })
            
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            }, status=400)
    
    return JsonResponse({
        'status': 'error',
        'message': 'Invalid request method'
    }, status=405)

    

# views.py - Buat file ini di aplikasi Django Anda

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from PIL import Image
import os

@csrf_exempt
def count_pixels(request):
    """
    View sederhana untuk menghitung piksel gambar
    Mendukung GET (path) dan POST (upload)
    """
    if request.method == 'GET':
        # Ambil path dari URL parameter
        file_path = request.GET.get('path')
        
        if not file_path:
            return JsonResponse({'error': 'Berikan parameter path. Contoh: ?path=/path/to/image.jpg'}, status=400)
        
        if not os.path.exists(file_path):
            return JsonResponse({'error': f'File tidak ditemukan: {file_path}'}, status=404)
        
        try:
            # Buka gambar dengan PIL
            img = Image.open(file_path)
            width, height = img.size
            
            # Periksa jika RGB atau grayscale
            is_rgb = img.mode in ('RGB', 'RGBA')
            
            # Ambil beberapa sampel piksel
            pixel_samples = []
            key_points = [
                (0, 0),                # Kiri atas
                (width - 1, 0),        # Kanan atas
                (width // 2, height // 2), # Tengah
                (0, height - 1),       # Kiri bawah
                (width - 1, height - 1), # Kanan bawah
            ]
            
            for x, y in key_points:
                pixel = img.getpixel((x, y))
                
                # Format piksel untuk output
                if isinstance(pixel, tuple):
                    if len(pixel) >= 3:
                        r, g, b = pixel[0], pixel[1], pixel[2]
                        a = pixel[3] if len(pixel) > 3 else 255
                    else:
                        r = g = b = pixel[0]
                        a = 255
                else:
                    r = g = b = pixel
                    a = 255
                
                pixel_samples.append({
                    'x': x, 'y': y,
                    'r': r, 'g': g, 'b': b, 'a': a
                })
            
            return JsonResponse({
                'filename': os.path.basename(file_path),
                'width': width,
                'height': height,
                'total_pixels': width * height,
                'is_rgb': is_rgb,
                'samples': pixel_samples
            })
            
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
            
    elif request.method == 'POST':
        # Check if we have an image file
        if 'image' not in request.FILES:
            return JsonResponse({'error': 'Tidak ada file gambar yang diupload'}, status=400)
        
        try:
            image_file = request.FILES['image']
            img = Image.open(image_file)
            width, height = img.size
            
            return JsonResponse({
                'filename': image_file.name,
                'width': width,
                'height': height,
                'total_pixels': width * height
            })
            
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
            
    else:
        return JsonResponse({'error': 'Metode tidak didukung. Gunakan GET atau POST.'}, status=405)
    




# update data diri di mobile
@csrf_exempt
def update_pegawai(request, id_pegawai):
    if request.method != 'PUT':
        return JsonResponse({'status': 'error', 'message': 'Method not allowed'}, status=405)
    
    try:
        pegawai = get_object_or_404(Pegawai, id_pegawai=id_pegawai, deleted_at__isnull=True)
        data = json.loads(request.body)
        
        # Update data
        pegawai.nama = data.get('nama', pegawai.nama)
        pegawai.email = data.get('email', pegawai.email)
        pegawai.no_hp = data.get('no_hp', pegawai.no_hp)
        pegawai.save()
        
        # Update User juga
        if pegawai.user:
            pegawai.user.first_name = pegawai.nama
            pegawai.user.email = pegawai.email
            pegawai.user.save()
        
        return JsonResponse({
            'status': 'success',
            'message': 'Data berhasil diperbarui',
            'data': {
                'id_pegawai': pegawai.id_pegawai,
                'nama': pegawai.nama,
                'email': pegawai.email,
                'no_hp': pegawai.no_hp,
                'nip': pegawai.nip,
                'jabatan': pegawai.id_jabatan.nama_jabatan if pegawai.id_jabatan else 'Tidak Diset',
                'unit_kerja': pegawai.id_unit_kerja.nama_unit_kerja if pegawai.id_unit_kerja else 'Tidak Diset',
            }
        })
        
    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
