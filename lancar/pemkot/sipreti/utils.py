# sipreti/utils.py
from PIL import Image
import io
import os
import heapq
import numpy as np
import pickle
from django.core.files.base import ContentFile

# Definisi kelas untuk Huffman Node
class HuffmanNode:
    def __init__(self, value=None, freq=0, left=None, right=None):
        self.value = value
        self.freq = freq
        self.left = left
        self.right = right
    
    def __lt__(self, other):
        return self.freq < other.freq

# Fungsi untuk mengubah gambar ke grayscale
def convert_to_grayscale(image_path):
    """Mengubah gambar menjadi grayscale"""
    with Image.open(image_path) as img:
        gray_img = img.convert('L')
        
        # Simpan hasil grayscale ke buffer
        buffer = io.BytesIO()
        gray_img.save(buffer, format="PNG")
        buffer.seek(0)
        
        # Convert to numpy array for compression
        gray_array = np.array(gray_img)
        return gray_array

# Fungsi untuk membangun tabel frekuensi
def build_frequency_table(data):
    """Membangun tabel frekuensi dari data"""
    frequency = {}
    for value in data.flatten():
        if value in frequency:
            frequency[value] += 1
        else:
            frequency[value] = 1
    return frequency

# Fungsi untuk membangun pohon Huffman
def build_huffman_tree(frequency):
    """Membangun pohon Huffman dari tabel frekuensi"""
    heap = [HuffmanNode(value, freq) for value, freq in frequency.items()]
    heapq.heapify(heap)
    
    # Bangun pohon Huffman
    while len(heap) > 1:
        left = heapq.heappop(heap)
        right = heapq.heappop(heap)
        
        # Buat node baru dengan frekuensi gabungan
        merged = HuffmanNode(None, left.freq + right.freq, left, right)
        heapq.heappush(heap, merged)
    
    return heap[0] if heap else None  # Root node

# Fungsi untuk membangun kode Huffman
def build_huffman_codes(node, code="", mapping=None):
    """Membangun kode Huffman dari pohon Huffman"""
    if mapping is None:
        mapping = {}
    
    if node:
        if node.value is not None:  # Leaf node
            mapping[node.value] = code
        
        # Traversal rekursif
        build_huffman_codes(node.left, code + "0", mapping)
        build_huffman_codes(node.right, code + "1", mapping)
    
    return mapping

# Fungsi untuk melakukan kompresi Huffman
def huffman_compress(data):
    """Melakukan kompresi Huffman pada data gambar"""
    # Hitung frekuensi
    frequency = build_frequency_table(data)
    
    # Bangun pohon Huffman
    huffman_tree = build_huffman_tree(frequency)
    
    # Dapatkan kode Huffman
    codes = build_huffman_codes(huffman_tree)
    
    # Encode data
    encoded_data = ""
    for value in data.flatten():
        encoded_data += codes[value]
    
    # Padding untuk membuat panjang data kelipatan 8
    padding = 8 - (len(encoded_data) % 8)
    if padding < 8:
        encoded_data += "0" * padding
    
    # Konversi string biner ke bytes
    result = bytearray()
    for i in range(0, len(encoded_data), 8):
        byte = encoded_data[i:i+8]
        result.append(int(byte, 2))
    
    # Simpan juga header informasi untuk dekompresi nanti
    # Format header: ukuran gambar, padding, dan tabel kode
    header = {
        "shape": data.shape,
        "padding": padding,
        "codes": codes
    }
    
    # Serialize header dengan pickle dan gabungkan dengan data terkompresi
    header_bytes = pickle.dumps(header)
    header_size = len(header_bytes).to_bytes(4, byteorder='big')
    
    # Gabungkan semua komponen
    compressed_data = header_size + header_bytes + bytes(result)
    
    return compressed_data, huffman_tree

# Fungsi untuk proses gambar secara lengkap
def process_image(original_image_path):
    """Memproses gambar: grayscale dan kompresi Huffman"""
    # Ubah gambar ke grayscale
    gray_image = convert_to_grayscale(original_image_path)
    
    # Lakukan kompresi Huffman
    compressed_data, huffman_tree = huffman_compress(gray_image)
    
    # Simpan hasil kompresi ke dalam file temporary
    temp_compressed_path = f"{os.path.splitext(original_image_path)[0]}_compressed.bin"
    with open(temp_compressed_path, 'wb') as f:
        f.write(compressed_data)
    
    return temp_compressed_path