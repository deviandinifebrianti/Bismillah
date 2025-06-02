import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RLE extends StatelessWidget {
  final String idPegawai;
  final String latitude;
  final String longitude;
  final String nama;
  final String nip;
  final String idUnitKerja;
  final String lokasi;

  const RLE({
    Key? key,
    required this.idPegawai,
    required this.latitude,
    required this.longitude,
    required this.nama,
    required this.nip,
    required this.idUnitKerja,
    required this.lokasi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kompresi Gambar RLE RGB',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HalamanKompresiGambar(
        idPegawai: idPegawai,
      ),
    );
  }
}

/// Struktur untuk menyimpan data RGB
class PixelRGB {
  final int r, g, b;
  PixelRGB(this.r, this.g, this.b);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PixelRGB && other.r == r && other.g == g && other.b == b;
  }

  @override
  int get hashCode => r.hashCode ^ g.hashCode ^ b.hashCode;

  List<int> toList() => [r, g, b];
}

/// Fungsi Encoding RLE untuk RGB
List<List<dynamic>> rleEncodeRGB(List<List<PixelRGB>> gambar) {
  List<List<dynamic>> encoded = [];

  // Flatten gambar menjadi 1D array
  List<PixelRGB> flatPixels = [];
  for (var baris in gambar) {
    flatPixels.addAll(baris);
  }

  if (flatPixels.isEmpty) return encoded;

  PixelRGB pixelSaatIni = flatPixels[0];
  int jumlah = 1;

  for (int i = 1; i < flatPixels.length; i++) {
    if (flatPixels[i] == pixelSaatIni) {
      jumlah++;
    } else {
      encoded.add([pixelSaatIni.toList(), jumlah]);
      pixelSaatIni = flatPixels[i];
      jumlah = 1;
    }
  }

  // Tambahkan run terakhir
  encoded.add([pixelSaatIni.toList(), jumlah]);

  return encoded;
}

/// Mengkonversi gambar menjadi array 2D RGB
List<List<PixelRGB>> gambarKeArrayRGB(img.Image gambar) {
  int lebar = gambar.width;
  int tinggi = gambar.height;

  List<List<PixelRGB>> hasil = List.generate(
      tinggi, (_) => List<PixelRGB>.filled(lebar, PixelRGB(0, 0, 0)));

  for (int y = 0; y < tinggi; y++) {
    for (int x = 0; x < lebar; x++) {
      // Ambil pixel RGB
      final pixel = gambar.getPixel(x, y);
      final r = img.getRed(pixel);
      final g = img.getGreen(pixel);
      final b = img.getBlue(pixel);

      hasil[y][x] = PixelRGB(r, g, b);
    }
  }

  return hasil;
}

class PemrosesGambarRLE {
  /// Encode file gambar menggunakan RLE RGB dan kirim ke server
  static Future<Map<String, dynamic>> encodeGambar(
      File fileGambar, String serverUrl, String idPegawai) async {
    try {
      // Baca bytes gambar
      final bytes = await fileGambar.readAsBytes();

      // Decode gambar
      final gambar = img.decodeImage(bytes);
      if (gambar == null) {
        throw Exception("Gagal mendecode gambar");
      }

      // Konversi ke array 2D RGB (tidak perlu grayscale)
      final arrayRGB = gambarKeArrayRGB(gambar);

      // Terapkan encoding RLE RGB
      final encoded = rleEncodeRGB(arrayRGB);

      // Siapkan payload
      final payload = {
        "encoded": encoded,
        "shape": [gambar.height, gambar.width],
        "channels": 3, // RGB = 3 channels
        "mode": "RGB"
      };

      // Konversi ke JSON, kompres dengan GZIP, dan encode dengan base64
      final jsonBytes = utf8.encode(jsonEncode(payload));
      final compressed = GZipEncoder().encode(jsonBytes);
      final compressedB64 = base64.encode(compressed!);

      // Data terkompresi dan bentuk gambar
      final hasilKompresi = {
        "compressed_data": compressedB64,
        "shape": [gambar.height, gambar.width],
        "channels": 3,
        "mode": "RGB",
        "id_pegawai": idPegawai, // Tambahkan id_pegawai jika ada
      };

      // Kirim ke server
      final response = await kirimKeServer(hasilKompresi, serverUrl);

      return {...hasilKompresi, "respons_server": response};
    } catch (e) {
      throw Exception("Error saat encoding gambar: $e");
    }
  }

  /// Mengirim data terkompresi ke server Django
  static Future<Map<String, dynamic>> kirimKeServer(
      Map<String, dynamic> data, String serverUrl) async {
    try {
      print("Mengirim data RGB ke server: $serverUrl");
      print("Data yang dikirim: ${jsonEncode({
            "compressed_data": data["compressed_data"].substring(0, 50) +
                "...", // Hanya tampilkan sebagian untuk log
            "shape": data["shape"],
            "channels": data["channels"],
            "mode": data["mode"],
            "id_pegawai": data["id_pegawai"] ?? ""
          })}");

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "compressed_data": data["compressed_data"],
          "shape": data["shape"],
          "channels": data["channels"],
          "mode": data["mode"],
          "id_pegawai":
              data["id_pegawai"] ?? "", // Tambahkan id_pegawai jika ada
        }),
      );

      print("Respons dari server: ${response.statusCode}");
      print("Isi respons: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Server mengembalikan kode status: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      print("Error saat mengirim data: $e");
      throw Exception("Error saat mengirim gambar terkompresi ke server: $e");
    }
  }
}

class HalamanKompresiGambar extends StatefulWidget {
  final String idPegawai;

  const HalamanKompresiGambar({Key? key, required this.idPegawai})
      : super(key: key);

  @override
  _HalamanKompresiGambarState createState() => _HalamanKompresiGambarState();
}

class _HalamanKompresiGambarState extends State<HalamanKompresiGambar> {
  final ImagePicker _picker = ImagePicker();
  File? _gambarAsli;
  String? _dataKompresi;
  List<int>? _bentuk;
  bool _sedangMemproses = false;
  Map<String, dynamic>? _responsServer;

  // URL server Django (ganti dengan URL server Anda)
  final String _urlServer = 'http://192.168.1.14:8000/sipreti/rle_decode_image';

  // Pilih gambar dari galeri atau kamera
  Future<void> _ambilGambar(ImageSource sumber) async {
    final gambarDipilih = await _picker.pickImage(
        source: sumber,
        maxWidth: 800, // Batasi ukuran untuk efisiensi
        maxHeight: 800,
        imageQuality: 90 // 0-100
        );

    if (gambarDipilih != null) {
      setState(() {
        _gambarAsli = File(gambarDipilih.path);
        _dataKompresi = null;
        _bentuk = null;
        _responsServer = null;
      });
    }
  }

  // Proses gambar dengan encoding RLE RGB dan kirim ke server
  Future<void> _prosesGambar() async {
    if (_gambarAsli == null) return;

    setState(() => _sedangMemproses = true);

    try {
      final hasil = await PemrosesGambarRLE.encodeGambar(
          _gambarAsli!, _urlServer, widget.idPegawai);

      setState(() {
        _dataKompresi = hasil['compressed_data'];
        _bentuk = List<int>.from(hasil['shape']);
        _responsServer = hasil['respons_server'];
      });

      // Tampilkan statistik kompresi
      final ukuranAsli = await _gambarAsli!.length();
      final ukuranKompresi = _dataKompresi!.length;
      final rasioKompresi = ukuranAsli / ukuranKompresi;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kompresi RGB selesai!\n'
            'Asli: ${(ukuranAsli / 1024).toStringAsFixed(2)} KB\n'
            'Terkompresi: ${(ukuranKompresi / 1024).toStringAsFixed(2)} KB\n'
            'Rasio: ${rasioKompresi.toStringAsFixed(2)}x\n'
            'Mode: RGB (3 channels)'),
        duration: Duration(seconds: 5),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 10),
      ));
    } finally {
      setState(() => _sedangMemproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Kompresi Gambar RLE RGB',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 2,
        centerTitle: true,
      ),
      body: _sedangMemproses
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.indigo[50]!, Colors.white],
                ),
              ),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.indigo[600]!),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Sedang memproses gambar RGB\ndan mengirim ke server...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.indigo[50]!, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.indigo[600],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Pilih Gambar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _ambilGambar(ImageSource.camera),
                                    icon: Icon(Icons.camera_alt, size: 20),
                                    label: Text('Kamera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[600],
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Tampilan gambar asli
                    if (_gambarAsli != null) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    color: Colors.indigo[600],
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Gambar Asli (RGB)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _gambarAsli!,
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _prosesGambar,
                                  icon: Icon(Icons.play_arrow, size: 24),
                                  label: Text(
                                    'Proses RGB & Kirim ke Server',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Tampilan data terkompresi
                    if (_dataKompresi != null) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.compress,
                                    color: Colors.orange[600],
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Data RGB Terkompresi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  _dataKompresi!.length > 100
                                      ? '${_dataKompresi!.substring(0, 100)}...'
                                      : _dataKompresi!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue[600],
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Bentuk Gambar RGB: ${_bentuk![0]} x ${_bentuk![1]} x 3 channels',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Tampilan respons server
                    if (_responsServer != null) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.cloud_done,
                                    color: Colors.green[600],
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Respons Server',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 42, 173, 190),
                                  border: Border.all(color: Colors.green[200]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildServerResponseItem(
                                      Icons.message,
                                      'Pesan',
                                      _responsServer!['message'] ??
                                          'Tidak ada pesan',
                                    ),
                                    if (_responsServer!.containsKey('filename'))
                                      _buildServerResponseItem(
                                        Icons.file_present,
                                        'Nama File',
                                        _responsServer!['filename'],
                                      ),
                                    if (_responsServer!
                                        .containsKey('saved_path'))
                                      _buildServerResponseItem(
                                        Icons.folder,
                                        'Path',
                                        _responsServer!['saved_path'],
                                      ),
                                    if (_responsServer!.containsKey('mode'))
                                      _buildServerResponseItem(
                                        Icons.mode_edit,
                                        'Mode',
                                        _responsServer!['mode'],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServerResponseItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color.fromARGB(255, 53, 233, 29),
          ),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: const Color.fromARGB(255, 53, 233, 29),
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
