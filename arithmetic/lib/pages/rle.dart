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
import 'package:absensi/pages/huffman.dart';
import 'package:geolocator/geolocator.dart';
import 'package:absensi/pages/checkout.dart';

class RLE extends StatelessWidget {
  final String idPegawai;
  final String latitude;
  final String longitude;
  final String nama;
  final String nip;
  final String idUnitKerja;
  final String lokasi;
  final int jenis;
  final int checkMode;

  const RLE({
    Key? key,
    required this.idPegawai,
    required this.latitude,
    required this.longitude,
    required this.nama,
    required this.nip,
    required this.idUnitKerja,
    required this.lokasi,
    required this.checkMode,
    required this.jenis,
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
        latitude: latitude, // ← TAMBAH INI
        longitude: longitude, // ← TAMBAH INI
        nama: nama, // ← TAMBAH INI
        nip: nip, // ← TAMBAH INI
        idUnitKerja: idUnitKerja, // ← TAMBAH INI
        lokasi: lokasi, // ← TAMBAH INI
        jenis: jenis, // ← TAMBAH INI
        checkMode: checkMode,
      ),
    );
  }
}

class HalamanKompresiGambar extends StatefulWidget {
  final String idPegawai;
  final String latitude; // ← TAMBAH INI
  final String longitude; // ← TAMBAH INI
  final String nama; // ← TAMBAH INI
  final String nip; // ← TAMBAH INI
  final String idUnitKerja; // ← TAMBAH INI
  final String lokasi; // ← TAMBAH INI
  final int jenis; // ← TAMBAH INI
  final int checkMode;

  const HalamanKompresiGambar({
    Key? key,
    required this.idPegawai,
    required this.latitude, // ← TAMBAH INI
    required this.longitude, // ← TAMBAH INI
    required this.nama, // ← TAMBAH INI
    required this.nip, // ← TAMBAH INI
    required this.idUnitKerja, // ← TAMBAH INI
    required this.lokasi, // ← TAMBAH INI
    required this.jenis, // ← TAMBAH INI
    required this.checkMode,
  }) : super(key: key);

  @override
  _HalamanKompresiGambarState createState() => _HalamanKompresiGambarState();
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

class _HalamanKompresiGambarState extends State<HalamanKompresiGambar> {
  final ImagePicker _picker = ImagePicker();
  File? _gambarAsli;
  String? _dataKompresi;
  List<int>? _bentuk;
  bool _sedangMemproses = false;
  Map<String, dynamic>? _responsServer;
  Position? _currentPosition;
  String alamat = '';
  Duration? _captureTime;
  Duration? _decompressionTime; 
  int? _originalSize;
  int? _compressedSize;
  int? _decodedSize;

  String _formatTime(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else {
      double seconds = milliseconds / 1000;
      return '${seconds.toStringAsFixed(3)}s';
    }
  }

  // ✅ TAMBAH VARIABLES YANG DIPERLUKAN UNTUK NAVIGATION
  String _status = 'Tekan tombol kamera untuk mengambil foto';
  bool _isProcessing = false;
  int? _kompresiId;
  String? _lastCapturedImagePath;
  Uint8List? _lastCapturedImageData;

  // ✅ OPTIONAL: RLE timing variables
  int? _rleCompressionTime;
  int? _totalTime;
  String? _processingStats;

  // URL server Django (ganti dengan URL server Anda)
  final String _urlServer = 'http://192.168.1.88:8000/sipreti/rle_decode_image';

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

  setState(() {
    _sedangMemproses = true;
    _isProcessing = true;
    _status = 'Memproses RLE compression...';
    
    _captureTime = null;
    _decompressionTime = null;
    _originalSize = null;
    _compressedSize = null;
    _decodedSize = null;
    _processingStats = null;
  });

  final Stopwatch totalTimer = Stopwatch()..start();

  try {
    // Hitung ukuran file asli
    _originalSize = await _gambarAsli!.length();
    
    // Timer untuk RLE compression  
    final Stopwatch rleTimer = Stopwatch()..start();

    final hasil = await PemrosesGambarRLE.encodeGambar(
        _gambarAsli!, _urlServer, widget.idPegawai);

    rleTimer.stop();
    _rleCompressionTime = rleTimer.elapsed.inMilliseconds;
    
    // Hitung ukuran compressed
    _compressedSize = hasil['compressed_data'].length;

    setState(() {
      _dataKompresi = hasil['compressed_data'];
      _bentuk = List<int>.from(hasil['shape']);
      _responsServer = hasil['respons_server'];
      _lastCapturedImagePath = _gambarAsli!.path;
      _status = 'RLE compression selesai';
    });

    // Convert file to uint8list
    _lastCapturedImageData = await _gambarAsli!.readAsBytes();

    // Parse response server
    Map<String, dynamic> responseData = {};
    if (_responsServer != null) {
      try {
        responseData = Map<String, dynamic>.from(_responsServer!);

        // Ambil decompression time dari server
        if (responseData.containsKey('decompression_time_seconds')) {
          final seconds = responseData['decompression_time_seconds'];
          if (seconds is num) {
            _decompressionTime = Duration(milliseconds: (seconds * 1000).round());
          }
        }

        // Ambil decoded size dari server
        if (responseData.containsKey('decoded_size')) {
          _decodedSize = responseData['decoded_size'];
        }

        // Extract kompresi_id dari response
        if (responseData['face_recognition'] != null &&
            responseData['face_recognition']['kompresi_id'] != null) {
          _kompresiId = responseData['face_recognition']['kompresi_id'];
        }
      } catch (e) {
        print('Error parsing response: $e');
        responseData = {};
      }
    }

    // Stop total timer dan generate stats
    totalTimer.stop();
    _totalTime = totalTimer.elapsed.inMilliseconds;
    
    _generateRLEProcessingStats();

    // Cek apakah face recognition berhasil
    bool isVerificationSuccess = false;
    if (responseData['face_recognition'] != null) {
      isVerificationSuccess =
          responseData['face_recognition']['success'] == true &&
              responseData['face_recognition']['auto_verification'] == true;
    }

    // Tampilkan dialog yang sesuai
    if (isVerificationSuccess) {
      _showRLESuccessDialogWithStats();
    } else {
      _showRLEStatisticsOnlyDialog();
    }
    
  } catch (e) {
    totalTimer.stop();
    _totalTime = totalTimer.elapsed.inMilliseconds;
    
    setState(() {
      _status = 'Error: $e';
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error: $e'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 10),
    ));
  } finally {
    setState(() {
      _sedangMemproses = false;
      _isProcessing = false;
    });
  }
}

void _generateRLEProcessingStats() {
  final StringBuffer stats = StringBuffer();

  stats.writeln('=== STATISTIK RLE PROCESSING ===');

  if (_rleCompressionTime != null) {
    stats.writeln('⏱️ Waktu Kompresi RLE: ${(_rleCompressionTime! / 1000).toStringAsFixed(3)}s');
  }

  if (_originalSize != null) {
    stats.writeln('📦 Ukuran Asli: ${_formatBytes(_originalSize!)} (${_originalSize!} bytes)');
  }
  if (_compressedSize != null) {
    stats.writeln('📦 Ukuran Kompresi: ${_formatBytes(_compressedSize!)} (${_compressedSize!} bytes)');
  }
  if (_decodedSize != null) {
    stats.writeln('🔄 Ukuran Hasil Decode: ${_formatBytes(_decodedSize!)} (${_decodedSize!} bytes)');
  }

  if (_originalSize != null && _compressedSize != null) {
    stats.writeln('\n📊 PARAMETER EVALUASI KOMPRESI:');
    
    final rc = _originalSize! / _compressedSize!;
    stats.writeln('• Ratio of Compression (RC): ${rc.toStringAsFixed(2)}');
    
    final cr = (1 - (_compressedSize! / _originalSize!)) * 100;
    stats.writeln('• Compression Ratio (CR): ${cr.toStringAsFixed(2)}%');
    
    final rd = ((_originalSize! - _compressedSize!) / _originalSize!) * 100;
    stats.writeln('• Redundancy (RD): ${rd.toStringAsFixed(2)}%');
  }

  stats.writeln('\n⏰ WAKTU PEMROSESAN:');
  if (_rleCompressionTime != null) {
    stats.writeln('• Waktu Kompresi RLE: ${(_rleCompressionTime! / 1000).toStringAsFixed(3)}s');
  }
  
  if (_decompressionTime != null) {
    stats.writeln('• Waktu Dekompresi: ${(_decompressionTime!.inMilliseconds / 1000).toStringAsFixed(3)}s');
  }
  
  if (_totalTime != null) {
    stats.writeln('• Total Waktu Keseluruhan: ${(_totalTime! / 1000).toStringAsFixed(3)}s');
  }

  _processingStats = stats.toString();
}

void _navigateToCheckOut() {
  if (!mounted) return;

  try {
    // Pastikan data image sudah tersedia sebelum navigasi
    if (_gambarAsli != null) {
      // Set data yang diperlukan
      _lastCapturedImagePath = _gambarAsli!.path;

      // Jika _lastCapturedImageData belum ada, baca dari file
      if (_lastCapturedImageData == null) {
        _gambarAsli!.readAsBytes().then((bytes) {
          _lastCapturedImageData = bytes;
          _performActualNavigation();
        }).catchError((error) {
          print('Error reading image bytes: $error');
          _showNavigationError('Error reading image data');
        });
      } else {
        _performActualNavigation();
      }
    } else {
      _showNavigationError('No image data available');
    }
  } catch (e) {
    print('Error preparing navigation: $e');
    _showNavigationError('Error preparing navigation: $e');
  }
}

  void _performActualNavigation() {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CheckOutPage(
            idPegawai: widget.idPegawai,
            imagePath: _lastCapturedImagePath ?? '',
            imageData: _lastCapturedImageData ?? Uint8List(0),
            jenis: widget.jenis,
            checkMode: widget.checkMode,
            lokasi: widget.lokasi,
            nama: widget.nama,
            nip: widget.nip,
            idUnitKerja: widget.idUnitKerja,
            latitude: widget.latitude,
            longitude: widget.longitude,
            kompresiId: _kompresiId,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to checkout: $e');
      _showNavigationError('Error navigating to checkout: $e');
    }
  }

  void _showNavigationError(String message) {
    setState(() {
      _status = 'Tekan tombol kamera untuk mengambil foto';
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showRLESuccessDialogWithStats() {
  if (!mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green[600], size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'RLE Compression Berhasil!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎉 RLE compression berhasil dan wajah terverifikasi!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 16),

                      // ✅ TAMPILKAN STATISTIK LENGKAP
                      if (_processingStats != null) ...[
                        Text(
                          'Statistik Pemrosesan:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            _processingStats!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Tutup',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToCheckOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Lanjut ke Checkout'),
              ),
            ],
          ),
        ],
      );
    },
  );
}

// ✅ DIALOG UNTUK STATISTIK SAJA (TIDAK ADA FACE RECOGNITION)
  void _showRLEStatisticsOnlyDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.analytics, color: Colors.blue[600], size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Statistik RLE Compression',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 RLE compression berhasil dijalankan!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 16),

                      if (_processingStats != null) ...[
                        Text(
                          'Statistik Pemrosesan:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            _processingStats!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
  // Helper function untuk format bytes
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Kamera Run Length Encoding',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Simple pop - yang paling aman
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Camera Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.compress,
                  size: 60,
                  color: Colors.indigo[600],
                ),
              ),

              SizedBox(height: 40),

              // Status Text
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  _gambarAsli == null
                      ? 'Pilih gambar untuk diproses dengan RLE Coding'
                      : _sedangMemproses
                          ? 'Memproses gambar...'
                          : 'Siap memproses gambar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 50),

              // Image display (if selected)
              if (_gambarAsli != null) ...[
                Container(
                  height: 150,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_gambarAsli!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 30),
              ],

              // Action Buttons
              if (_gambarAsli == null) ...[
                // Camera Button only
                Container(
                  width: 200,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _sedangMemproses
                        ? null
                        : () => _ambilGambar(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: Colors.indigo.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Ambil Foto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Process Button (when image selected)
                Container(
                  width: 200,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _sedangMemproses ? null : _prosesGambar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: Colors.green.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _sedangMemproses
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Memproses...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Proses RLE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 20),

                // Camera again button
                Container(
                  width: 160,
                  child: OutlinedButton.icon(
                    onPressed: _sedangMemproses
                        ? null
                        : () => _ambilGambar(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, color: Colors.indigo[600]),
                    label: Text(
                      'Foto Ulang',
                      style: TextStyle(color: Colors.indigo[600]),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.indigo[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 30),

              // Results/Error display
              if (_responsServer != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '✅ RLE Processing Berhasil!',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_responsServer!['filename'] != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'File: ${_responsServer!['filename']}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
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
