import 'package:absensi/pages/kamera_huffman.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:absensi/pages/kamera2.dart';
import 'package:absensi/pages/arithmatic.dart';
import 'package:absensi/pages/lokasi.dart';
import 'package:absensi/pages/dashboard.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:absensi/utils/device_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:absensi/pages/huffman.dart';
import 'package:absensi/pages/profile.dart';

const String baseUrl = "http://192.168.1.88:8000";

class CheckOutPage extends StatefulWidget {
  final String imagePath;
  final Uint8List imageData;
  final String idPegawai;
  final String lokasi;
  final int jenis;
  final int checkMode;
  final String nama;
  final String nip;
  final String idUnitKerja;
  final String latitude;
  final String longitude;
  final int? kompresiId;

  const CheckOutPage({
    Key? key,
    required this.imagePath,
    required this.imageData,
    required this.idPegawai,
    required this.lokasi,
    required this.jenis,
    required this.checkMode,
    required this.nama,
    required this.nip,
    required this.idUnitKerja,
    required this.latitude,
    required this.longitude,
    this.kompresiId,
  }) : super(key: key);

  @override
  _CheckOutPageState createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> {
  bool _showOriginal = true;
  bool _isSending = false;

  String _getMonthName(int month) {
    const List<String> monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return monthNames[month - 1];
  }

  Future<dynamic> kirimAbsensiKeDjango() async {
    if (_isSending) {
      print('Sudah ada proses pengiriman yang sedang berjalan');
      return false;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Mendapatkan posisi GPS
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('Error mendapatkan posisi GPS: $e');
        // Gunakan posisi yang sudah ada jika gagal mendapatkan yang baru
        position = Position(
          latitude: double.parse(widget.latitude),
          longitude: double.parse(widget.longitude),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // Kompres gambar sebagai string base64 agar tidak terlalu besar
      String base64Image = "";
      try {
        if (widget.imageData.length > 500000) {
          // Jika ukuran > 500KB
          // Gunakan kompresiId daripada mengirim gambar langsung
          if (widget.kompresiId != null) {
            base64Image = "kompresi:${widget.kompresiId}";
          } else {
            // Jika tidak ada kompresiId, gunakan ukuran gambar yang lebih kecil
            final Uint8List compressedImage =
                await _compressImage(widget.imageData);
            base64Image = base64Encode(compressedImage);
          }
        } else {
          base64Image = base64Encode(widget.imageData);
        }
      } catch (e) {
        print('Error saat mengkompresi gambar: $e');
        // Fallback ke penggunaan kompresiId jika ada
        if (widget.kompresiId != null) {
          base64Image = "kompresi:${widget.kompresiId}";
        } else {
          base64Image = "error:${e.toString()}";
        }
      }

      final Map<String, dynamic> absensiData = {
        'id_pegawai': widget.idPegawai,
        'jenis': 0,
        'check_mode': widget.checkMode.toString(),
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'nama_lokasi': widget.lokasi,
        'nama_kamera': 'Kamera Depan',
        // 'image': base64Encode(widget.imageData),
        'waktu': DateTime.now().toIso8601String(),
      };

      // Tambahkan data kompresi jika ada
      if (widget.kompresiId != null) {
        absensiData['kompresi_id'] = widget.kompresiId.toString();
      } else {
        // Jika tidak ada kompresiId, kirim gambar sebagai base64
        absensiData['url_foto_presensi'] = base64Image;
      }

      print("Mengirim data absensi ke: $baseUrl/sipreti/log_absensi/");
      print(
          "Data yang dikirim: ${absensiData.toString().substring(0, min(100, absensiData.toString().length))}...");

      final response = await http
          .post(
            Uri.parse(
                '$baseUrl/sipreti/log_absensi/'), // ganti dengan IP backend Django kamu
            headers: {'Content-Type': 'application/json'},
            body: json.encode(absensiData),
          )
          .timeout(Duration(seconds: 30));

      print('Status response: ${response.statusCode}');
      print(
          'Response body: ${response.body.substring(0, min(100, response.body.length))}...');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Data berhasil dikirim ke Django');
        print('Response body: ${response.body}');

        DateTime waktuSekarang = DateTime.now();
        String waktuFormatted = waktuSekarang.toIso8601String();

        Map<String, dynamic> responseData = {};
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          print('Error parsing response JSON: $e');
          responseData = {}; // Fallback kosong jika parsing gagal
        }

        return {
          'success': true,
          'message': 'Absensi berhasil disimpan',
          'waktu': responseData['waktu_absensi'] ?? waktuFormatted,
          'checkMode': widget.checkMode
        };
      } else {
        print('❌ Gagal mengirim data ke Django: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Gagal mengirim data ke Django: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error saat mengirim data absensi: $e');
      print('Stack trace: $stackTrace');
      throw e; // Rethrow exception agar dapat ditangkap di onPressed
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // Fungsi untuk mengkompresi gambar
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // Gunakan library flutter_image_compress untuk kompresi
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 50, // Kualitas lebih rendah
        format: CompressFormat.jpeg,
      );
      print(
          "Kompresi gambar: ${imageBytes.length} bytes -> ${result.length} bytes");
      return result;
    } catch (e) {
      print("Error saat kompresi gambar: $e");
      return imageBytes; // Return gambar asli jika gagal kompresi
    }
  }

  // Helper function untuk min
  int min(int a, int b) {
    return a < b ? a : b;
  }

  @override
  @override
  Widget build(BuildContext context) {
    debugPrint('Image Path: ${widget.imagePath}');
    // debugPrint('Image Data: ${widget.imageData}');
    debugPrint('Kompresi ID: ${widget.kompresiId}'); // Debug kompresiId

    final DateTime now = DateTime.now();
    final String formattedDate =
        "${now.day} ${_getMonthName(now.month)} ${now.year}";
    final String formattedTime =
        "${now.hour}:${now.minute.toString().padLeft(2, '0')} WIB";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check Out',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 137, 235),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset('assets/pemkot_mlg.png', height: 40),
          ),
          ProfileAvatar(
            idPegawai: widget.idPegawai,
            nama: widget.nama,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Halo ${widget.nama}!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PERBAIKAN: SELALU TAMPILKAN KONTEN, TIDAK TERGANTUNG kompresiId
            Column(
              children: [
                // Tampilkan gambar jika ada imagePath yang valid
                if (widget.imagePath.isNotEmpty &&
                    File(widget.imagePath).existsSync())
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(widget.imagePath)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else if (widget.imageData.isNotEmpty)
                  // Fallback: tampilkan dari imageData jika imagePath tidak valid
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          widget.imageData,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else
                  // Placeholder jika tidak ada gambar
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                const Text(
                  'Absensi Reguler',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.lokasi,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Icon(Icons.emoji_emotions, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Data Valid',
                      style: TextStyle(fontSize: 20, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _isSending
                      ? null
                      : () async {
                          try {
                            // Tampilkan indikator loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text(
                                          'Mengirim data absensi...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                            // Dapatkan hasil dari kirimAbsensiKeDjango()
                            Map<String, dynamic> result =
                                await kirimAbsensiKeDjango();

                            // Dapatkan waktu sekarang atau dari hasil API
                            DateTime waktuSekarang;
                            if (result['success'] == true &&
                                result['waktu'] != null) {
                              // Gunakan waktu dari API jika tersedia
                              try {
                                waktuSekarang = DateTime.parse(result['waktu']);
                              } catch (e) {
                                waktuSekarang = DateTime.now();
                              }
                            } else {
                              waktuSekarang = DateTime.now();
                            }

                            // Tutup dialog loading
                            Navigator.of(context, rootNavigator: true).pop();

                            // Tampilkan notifikasi sukses
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Absensi berhasil disimpan ke database'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DashboardPage(
                                  idPegawai: widget.idPegawai,
                                  nama: widget.nama,
                                  nip: widget.nip,
                                  jenis: widget.jenis,
                                  checkMode: widget.checkMode,
                                  waktuAbsensi: waktuSekarang,
                                  checkInTime: widget.checkMode == 0
                                      ? waktuSekarang
                                      : null,
                                  checkOutTime: widget.checkMode == 1
                                      ? waktuSekarang
                                      : null,
                                  idUnitKerja: widget.idUnitKerja,
                                  lokasi: widget.lokasi,
                                  latitude: widget.latitude,
                                  longitude: widget.longitude,
                                  shouldRefreshAttendance: true,
                                ),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            // Tangani error
                            print("Error saat menyimpan absensi: $e");
                            // Tutup dialog loading jika ada error
                            Navigator.of(context, rootNavigator: true).pop();
                            // Tampilkan pesan error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menyimpan absensi: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: _isSending
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SELESAI',
                          style: TextStyle(fontSize: 18),
                        ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  child: const Text(
                    'BATAL',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color.fromARGB(255, 146, 25, 16),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
