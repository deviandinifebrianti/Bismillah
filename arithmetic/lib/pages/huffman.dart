import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:absensi/pages/checkout.dart';

class HuffmanCameraScreen extends StatefulWidget {
  final String idPegawai;
  final int jenis;
  final int checkMode;
  final String nama;
  final String nip;
  final String idUnitKerja;
  final String lokasi;
  final String latitude;
  final String longitude;
  final Duration? huffmanProcessingTime;
  final Duration? totalProcessingTime;
  final String? compressionStats;

  const HuffmanCameraScreen({
    Key? key,
    required this.idPegawai,
    required this.jenis,
    required this.checkMode,
    required this.nama,
    required this.nip,
    required this.idUnitKerja,
    required this.lokasi,
    required this.latitude,
    required this.longitude,
    this.huffmanProcessingTime, // ✅ TAMBAH INI
    this.totalProcessingTime, // ✅ TAMBAH INI
    this.compressionStats,
  }) : super(key: key);

  @override
  _HuffmanCameraScreenState createState() => _HuffmanCameraScreenState();
}

class _HuffmanCameraScreenState extends State<HuffmanCameraScreen> {
  bool _isProcessing = false;
  String _status = 'Tekan tombol kamera untuk mengambil foto';
  final ImagePicker _picker = ImagePicker();

  String? _lastCapturedImagePath;
  Uint8List? _lastCapturedImageData;
  int? _kompresiId;

  Duration? _captureTime;
  Duration? _huffmanCompressionTime;
  Duration? _sendingTime;
  Duration? _totalTime;
  int? _originalSize;
  int? _compressedSize;
  int? _decodedSize;
  double? _euclideanDistance;
  double? _faceThreshold;
  String? _processingStats;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    var cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      setState(() {
        _status = 'Izin kamera diperlukan untuk fitur ini';
      });
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Membuka kamera...';

      _captureTime = null;
      _huffmanCompressionTime = null;
      _sendingTime = null;
      _totalTime = null;
      _originalSize = null;
      _compressedSize = null;
      _decodedSize = null;
      _euclideanDistance = null;
      _faceThreshold = null;
      _processingStats = null;
    });

    final Stopwatch totalTimer = Stopwatch()..start();

    try {
      // ✅ TIMER UNTUK CAPTURE
      final Stopwatch captureTimer = Stopwatch()..start();

      // Ambil foto langsung dari kamera
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front, // Atau CameraDevice.rear
      );

      captureTimer.stop();
      _captureTime = captureTimer.elapsed;

      if (photo != null) {
        setState(() {
          _status = 'Foto berhasil diambil (${_captureTime!.inMilliseconds}ms)';
        });

        // Proses encoding di background
        final imageFile = File(photo.path);
        _lastCapturedImagePath = photo.path;
        _lastCapturedImageData = await imageFile.readAsBytes();
        _originalSize = _lastCapturedImageData!.length;

        await _processImageInBackground(imageFile, totalTimer);
      } else {
        totalTimer.stop();
        setState(() {
          _status = 'Pengambilan foto dibatalkan';
          _isProcessing = false;
        });
      }
    } catch (e) {
      totalTimer.stop();
      print('Error in _captureAndProcess: $e');
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
      _showErrorDialog('Terjadi kesalahan saat mengambil foto: $e');
    }
  }

  Future<void> _processImageInBackground(
      File imageFile, Stopwatch totalTimer) async {
    try {
      setState(() {
        _status = 'Memulai  kompresi gambar...';
      });
      final Stopwatch huffmanTimer = Stopwatch()..start();
      // Proses encoding Huffman
      final result = await encodeImageHuffman(imageFile);
      huffmanTimer.stop();
      _huffmanCompressionTime = huffmanTimer.elapsed;

      if (result.isEmpty) {
        throw Exception('Hasil encoding kosong');
      }
      _compressedSize = _calculateCompressedSize(result);

      setState(() {
        _status =
            'Huffman selesai (${_huffmanCompressionTime!.inMilliseconds}ms). Mengirim ke server...';
      });

      print('🔧 DEBUG: About to call sendCompressedDataToServer');
      final Stopwatch sendingTimer = Stopwatch()..start();

      // Kirim ke server dengan try-catch yang lebih spesifik
      Map<String, dynamic>? serverResponse;
      try {
        serverResponse = await sendCompressedDataToServer(result);
        print('🔧 DEBUG: sendCompressedDataToServer returned successfully');
      } catch (e) {
        print('🔧 DEBUG: sendCompressedDataToServer threw exception: $e');
        rethrow;
      } finally {
        sendingTimer.stop();
        _sendingTime = sendingTimer.elapsed;
      }

      totalTimer.stop();
      _totalTime = totalTimer.elapsed;

      // Validasi response tidak null
      if (serverResponse == null) {
        throw Exception('Server response is null');
      }

      if (serverResponse.containsKey('decoded_size')) {
        _decodedSize = serverResponse['decoded_size'];
      }

      if (serverResponse.containsKey('euclidean_distance')) {
        _euclideanDistance = serverResponse['euclidean_distance']?.toDouble();
      }

      if (serverResponse.containsKey('threshold')) {
        _faceThreshold = serverResponse['threshold']?.toDouble();
      } else {
        _faceThreshold = 0.6; // Default threshold jika tidak ada di response
      }

      if (serverResponse.containsKey('kompresi_id')) {
        _kompresiId = serverResponse['kompresi_id'];
        print('🔍 kompresi_id: $_kompresiId');
      }

      // ✅ BUAT STATISTIK LENGKAP
      _generateProcessingStats();

      // Hitung statistik kompresi
      final compressionRatio = _originalSize != null && _compressedSize != null
          ? (1 - (_compressedSize! / _originalSize!)) * 100
          : 0.0;

      setState(() {
        _status = 'Verifikasi wajah...';
      });

      print('🔧 DEBUG: About to call _handleVerificationResult');

      try {
        _handleVerificationResult(
            serverResponse, compressionRatio, _originalSize!, _compressedSize!);
        print('🔧 DEBUG: _handleVerificationResult completed');
      } catch (e) {
        print('🔧 DEBUG: _handleVerificationResult threw exception: $e');
        rethrow;
      }
    } catch (e) {
      totalTimer.stop();
      _totalTime = totalTimer.elapsed;

      print('❌ Error in _processImageInBackground: $e');
      setState(() {
        _status = 'Error saat memproses: $e';
        _isProcessing = false;
      });
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  void _generateProcessingStats() {
    final StringBuffer stats = StringBuffer();

    stats.writeln('=== STATISTIK PEMROSESAN ===');

    // Timing Information
    stats.writeln('\n📏 WAKTU PEMROSESAN:');
    if (_captureTime != null) {
      stats.writeln('• Capture foto: ${_captureTime!.inMilliseconds}ms');
    }
    if (_huffmanCompressionTime != null) {
      stats.writeln(
          '• Kompresi Huffman: ${_huffmanCompressionTime!.inMilliseconds}ms');
    }
    if (_sendingTime != null) {
      stats.writeln('• Kirim ke server: ${_sendingTime!.inMilliseconds}ms');
    }
    if (_totalTime != null) {
      stats.writeln('• Total waktu: ${_totalTime!.inMilliseconds}ms');
    }

    // Size Information
    stats.writeln('\n📦 UKURAN DATA:');
    if (_originalSize != null) {
      stats.writeln('• Ukuran asli: ${_formatBytes(_originalSize!)}');
    }
    if (_compressedSize != null) {
      stats.writeln('• Ukuran terkompresi: ${_formatBytes(_compressedSize!)}');
    }
    if (_decodedSize != null) {
      stats.writeln('• Ukuran hasil decode: ${_formatBytes(_decodedSize!)}');
    }

    // Compression Ratio
    if (_originalSize != null && _compressedSize != null) {
      final ratio = (1 - (_compressedSize! / _originalSize!)) * 100;
      stats.writeln('• Rasio kompresi: ${ratio.toStringAsFixed(2)}%');
    }

    // Quality Information
    stats.writeln('\n🎯 KUALITAS & FACE RECOGNITION:');
    if (_euclideanDistance != null) {
      stats.writeln(
          '• Euclidean Distance: ${_euclideanDistance!.toStringAsFixed(4)}');
    }
    if (_faceThreshold != null) {
      stats
          .writeln('• Threshold Django: ${_faceThreshold!.toStringAsFixed(2)}');
    }
    if (_euclideanDistance != null && _faceThreshold != null) {
      final isPassingThreshold = _euclideanDistance! <= _faceThreshold!;
      stats.writeln(
          '• Status Threshold: ${isPassingThreshold ? "✅ LULUS" : "❌ TIDAK LULUS"}');
    }
    stats.writeln(
        '• Kualitas gambar: ${_getQualityLevel(_euclideanDistance ?? 999)}');

    if (_kompresiId != null) {
      stats.writeln('• Kompresi ID: $_kompresiId');
    }

    _processingStats = stats.toString();
  }

  String _getQualityLevel(double distance) {
    if (distance < 0.01) return 'Sangat Tinggi (Lossless)';
    if (distance < 0.1) return 'Tinggi';
    if (distance < 1.0) return 'Sedang';
    if (distance < 10.0) return 'Rendah';
    return 'Sangat Rendah';
  }

  // ✅ HELPER: Format bytes ke string yang readable
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  void _handleVerificationResult(
    Map<String, dynamic> serverResponse,
    double compressionRatio,
    int originalSize,
    int compressedSize,
  ) {
    print('🔧 DEBUG: _handleVerificationResult called');

    try {
      print('🔍 ===== PROCESSING VERIFICATION RESULT =====');

      // Validate that serverResponse is actually a Map
      if (serverResponse == null || serverResponse is! Map<String, dynamic>) {
        print('❌ Server response is invalid');
        setState(() {
          _status = 'Format response server tidak valid';
          _isProcessing = false;
        });
        _showErrorDialog('Format response server tidak valid');
        return;
      }

      print('🔍 Response keys: ${serverResponse.keys.toList()}');

      // Cek untuk response format yang baru (hanya upload berhasil)
      if (serverResponse.containsKey('status') &&
          serverResponse['status'] == 'success' &&
          serverResponse.containsKey('filename')) {
        print(
            '🔍 📋 DETECTED: Upload success response (not verification response)');

        setState(() {
          _status =
              'Server hanya mengupload gambar, tidak melakukan verifikasi wajah';
          _isProcessing = false;
        });

        _showUploadOnlyDialog(serverResponse);
        return;
      }

      // Cek apakah ada auto_verification key (response format yang benar)
      if (serverResponse.containsKey('auto_verification')) {
        print('🔧 DEBUG: auto_verification key EXISTS!');

        final autoVerification = serverResponse['auto_verification'];
        print('🔍 ✅ Found auto_verification: $autoVerification');

        // Pastikan konversi ke boolean
        bool isVerified = false;
        if (autoVerification is bool) {
          isVerified = autoVerification;
        } else if (autoVerification is String) {
          isVerified = autoVerification.toLowerCase() == 'true';
        } else if (autoVerification is int) {
          isVerified = autoVerification == 1;
        }

        print('🔍 Final verification result: $isVerified');

        if (isVerified) {
          // BERHASIL: Langsung ke checkout
          print('✅ VERIFICATION SUCCESS - navigating to checkout');
          setState(() {
            _status =
                'Verifikasi berhasil! Rasio kompresi: ${compressionRatio.toStringAsFixed(2)}%';
          });
          _showSuccessDialogWithStats();
        } else {
          // GAGAL: Tampilkan pesan error
          print('❌ VERIFICATION FAILED - showing error dialog');
          String? detailMessage;

          // ✅ BUAT PESAN ERROR YANG INFORMATIF DENGAN THRESHOLD
          if (_euclideanDistance != null && _faceThreshold != null) {
            detailMessage =
                "Euclidean Distance: ${_euclideanDistance!.toStringAsFixed(4)}\n"
                "Threshold Django: ${_faceThreshold!.toStringAsFixed(2)}\n"
                "Status: ${_euclideanDistance! <= _faceThreshold! ? "Seharusnya LULUS" : "TIDAK LULUS"}\n\n";
          }

          if (serverResponse.containsKey('message')) {
            detailMessage =
                (detailMessage ?? "") + serverResponse['message'].toString();
          }

          setState(() {
            _status = 'Verifikasi wajah gagal';
            _isProcessing = false;
          });

          _showVerificationFailedDialog(detailMessage: detailMessage);
        }
      } else {
        // Fallback: cek apakah ada key 'success'
        if (serverResponse.containsKey('success')) {
          print(
              '🔍 Found "success" key as fallback: ${serverResponse['success']}');
          final success = serverResponse['success'];
          if (success is bool && success == true) {
            print('🔍 Using "success" key as verification result');
            setState(() {
              _status =
                  'Verifikasi berhasil! Rasio kompresi: ${compressionRatio.toStringAsFixed(2)}%';
            });
            _showSuccessDialogWithStats();
            return;
          }
        }

        // Jika tidak ada auto_verification dan tidak ada success
        print('❌ CRITICAL: No verification result found in response');
        setState(() {
          _status = 'Server tidak mengembalikan hasil verifikasi wajah';
          _isProcessing = false;
        });

        _showServerErrorDialog(serverResponse);
      }
    } catch (e) {
      print('❌ Exception in _handleVerificationResult: $e');
      setState(() {
        _status = 'Error saat memproses hasil verifikasi: $e';
        _isProcessing = false;
      });
      _showErrorDialog('Error processing verification result: $e');
    }
  }

  // ✅ DIALOG SUKSES DENGAN STATISTIK LENGKAP
  void _showSuccessDialogWithStats() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verifikasi Berhasil!',
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
              mainAxisSize: MainAxisSize.min,
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
                        '🎉 Wajah berhasil diverifikasi dengan database!',
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
    );
  }

  void _navigateToCheckOut() {
    if (!mounted) return;
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
            // ✅ PASS TIMING DATA KE CHECKOUT
            // huffmanProcessingTime: _huffmanCompressionTime,
            // totalProcessingTime: _totalTime,
            // compressionStats: _processingStats,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to checkout: $e');
      setState(() {
        _status = 'Tekan tombol kamera untuk mengambil foto';
        _isProcessing = false;
      });
    }
  }

  void _showUploadOnlyDialog(Map<String, dynamic> serverResponse) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.cloud_upload, color: Colors.orange[600], size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Upload Berhasil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gambar berhasil diupload ke server, tetapi verifikasi wajah belum dilakukan.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Detail Upload:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    if (serverResponse.containsKey('filename'))
                      Text('• File: ${serverResponse['filename']}'),
                    if (serverResponse.containsKey('message'))
                      Text('• Status: ${serverResponse['message']}'),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kemungkinan penyebab:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Server hanya melakukan decode gambar\n• Face verification tidak dijalankan\n• Database wajah belum tersedia\n• Konfigurasi server belum lengkap',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Reset state untuk foto ulang
              setState(() {
                _status = 'Tekan tombol kamera untuk mengambil foto';
                _isProcessing = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Coba Lagi'),
          ),
          // Tambahan: tombol untuk lanjut tanpa verifikasi (opsional)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Lanjut ke checkout tanpa verifikasi (untuk testing)
              setState(() {
                _status = 'Lanjut tanpa verifikasi wajah';
              });
              _showSuccessToastAndNavigate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Lanjut (Test)'),
          ),
        ],
      ),
    );
  }

// Method untuk menampilkan dialog ketika server tidak mengembalikan auto_verification
  void _showServerErrorDialog(Map<String, dynamic> serverResponse) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber,
                  color: Colors.orange[600], size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Masalah Server',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server tidak mengembalikan hasil verifikasi wajah.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Foto berhasil diupload tetapi verifikasi belum selesai.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (serverResponse.containsKey('filename')) ...[
                      SizedBox(height: 8),
                      Text(
                        'File tersimpan: ${serverResponse['filename']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (serverResponse.containsKey('message')) ...[
                      SizedBox(height: 8),
                      Text(
                        'Pesan server: ${serverResponse['message']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Reset state untuk foto ulang
              setState(() {
                _status = 'Tekan tombol kamera untuk mengambil foto';
                _isProcessing = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showSuccessToastAndNavigate() {
    if (!mounted) return;

    // Tampilkan toast notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Verifikasi berhasil! Menuju checkout...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate ke checkout setelah delay singkat
    Future.delayed(Duration(seconds: 1), () {
      _navigateToCheckOut();
    });
  }

  // Method untuk menampilkan dialog ketika verifikasi wajah gagal
  void _showVerificationFailedDialog({String? detailMessage}) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.face_retouching_off,
                  color: Colors.red[600], size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verifikasi Wajah Gagal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wajah Anda tidak dapat diverifikasi dengan database.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[800],
                      ),
                    ),

                    // Tampilkan detail jika ada
                    if (detailMessage != null && detailMessage.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          detailMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 16),
                    Text(
                      'Tips untuk foto yang baik:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    ...([
                      '• Pastikan pencahayaan cukup terang',
                      '• Posisikan wajah tegak lurus ke kamera',
                      '• Jaga jarak optimal dengan kamera (30-50 cm)',
                      '• Hindari menggunakan masker atau kacamata',
                      '• Pastikan wajah terlihat jelas tanpa bayangan',
                      '• Gunakan ekspresi wajah yang natural'
                    ]
                        .map((tip) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ))
                        .toList()),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Reset state untuk foto ulang
              setState(() {
                _status = 'Tekan tombol kamera untuk mengambil foto';
                _isProcessing = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.error_outline, color: Colors.red[600], size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[800],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _status = 'Tekan tombol kamera untuk mengambil foto';
                _isProcessing = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(double compressionRatio, int originalSize,
      int compressedSize, Map<String, dynamic> serverResponse) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto berhasil diproses dan dikirim!'),
            SizedBox(height: 10),
            Text('Statistik Kompresi:'),
            Text('• Rasio: ${compressionRatio.toStringAsFixed(2)}%'),
            Text(
                '• Ukuran asli: ${(originalSize / 1024).toStringAsFixed(2)} KB'),
            Text(
                '• Ukuran terkompresi: ${(compressedSize / 1024).toStringAsFixed(2)} KB'),
            if (serverResponse.containsKey('filename')) ...[
              SizedBox(height: 10),
              Text('File tersimpan: ${serverResponse['filename']}'),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _navigateToCheckOut(); // Lanjut ke checkout
            },
            child: Text('Lanjut Checkout'),
          ),
        ],
      ),
    );
  }

  int _calculateCompressedSize(Map<String, dynamic> result) {
    try {
      if (result['is_rgb'] == true) {
        final redSize = result['red_encoded'] != null
            ? base64Decode(result['red_encoded']).length
            : 0;
        final greenSize = result['green_encoded'] != null
            ? base64Decode(result['green_encoded']).length
            : 0;
        final blueSize = result['blue_encoded'] != null
            ? base64Decode(result['blue_encoded']).length
            : 0;
        return redSize + greenSize + blueSize;
      } else {
        return result['encoded_data'] != null
            ? base64Decode(result['encoded_data']).length
            : 0;
      }
    } catch (e) {
      print('Error calculating compressed size: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> sendCompressedDataToServer(
      Map<String, dynamic> result) async {
    final serverUrl =
        'http://192.168.1.14:8000/sipreti/upload_encoded_huffman/';

    try {
      if (result.isEmpty) {
        throw Exception("Result is null or empty");
      }

      print('🚀 ===== SENDING TO SERVER =====');

      http.Response? response;

      // Jika gambar RGB
      if (result.containsKey('is_rgb') && result['is_rgb'] == true) {
        // Validasi data RGB
        if (result['shape'] == null || (result['shape'] as List).length < 2) {
          throw Exception("Invalid shape data");
        }

        for (String key in [
          'red_encoded',
          'green_encoded',
          'blue_encoded',
          'red_root',
          'green_root',
          'blue_root'
        ]) {
          if (result[key] == null || result[key].toString().isEmpty) {
            throw Exception("Missing or empty required data: $key");
          }
        }

        final List<dynamic> shapeList = result['shape'] as List;
        final List<int> shape = [
          shapeList[1] as int, // height
          shapeList[0] as int, // width
        ];

        final Map<String, dynamic> requestBody = {
          'shape': shape,
          'id_pegawai': widget.idPegawai,
          'is_rgb': true,
          'red_encoded': result['red_encoded'],
          'green_encoded': result['green_encoded'],
          'blue_encoded': result['blue_encoded'],
          'red_root': result['red_root'],
          'green_root': result['green_root'],
          'blue_root': result['blue_root'],
          'capture_time': _captureTime?.inMilliseconds,
          'huffman_time': _huffmanCompressionTime?.inMilliseconds,
          'sending_time': _sendingTime?.inMilliseconds,
          'total_mobile_time': _totalTime?.inMilliseconds,
        };

        print('🚀 Sending RGB request to server...');
        response = await http
            .post(
              Uri.parse(serverUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(Duration(minutes: 2));
      } else {
        // Jika gambar grayscale
        if (result['encoded_data'] == null || result['root'] == null) {
          throw Exception("Missing encoded_data or root for grayscale image");
        }

        final String encodedData = result['encoded_data'];
        final List<dynamic> shapeList = result['shape'] as List;
        final List<int> shape = [
          shapeList[1] as int, // height
          shapeList[0] as int, // width
        ];

        final String rootJson = result['root'];
        final List<int> rootBytes = utf8.encode(rootJson);
        final String rootBase64 = base64Encode(rootBytes);

        final Map<String, dynamic> requestBody = {
          'encoded_data': encodedData,
          'shape': shape,
          'root': rootBase64,
          'id_pegawai': widget.idPegawai,
          'is_rgb': false,
          'capture_time': _captureTime?.inMilliseconds,
          'huffman_time': _huffmanCompressionTime?.inMilliseconds,
          'sending_time': _sendingTime?.inMilliseconds,
          'total_mobile_time': _totalTime?.inMilliseconds,
        };

        print('🚀 Sending grayscale request to server...');
        response = await http
            .post(
              Uri.parse(serverUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(Duration(seconds: 30));
      }

      // Process response - common for both RGB and grayscale
      print('📡 Server response status: ${response.statusCode}');
      print('📡 Raw response body: "${response.body}"');
      print('📡 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final dynamic parsedJson = jsonDecode(response.body.trim());
        final Map<String, dynamic> responseData =
            Map<String, dynamic>.from(parsedJson);

        // ✅ CEK APAKAH ADA TIMING DATA DARI SERVER
        if (responseData.containsKey('timing')) {
          print(
              '📊 Received timing data from server: ${responseData['timing']}');
        }

        // Coba parse JSON dengan debugging
        try {
          print('🔧 DEBUG: Attempting to parse JSON...');

          // Cek apakah response body adalah JSON yang valid
          final trimmedBody = response.body.trim();
          print('🔧 DEBUG: Trimmed body: "$trimmedBody"');

          if (!trimmedBody.startsWith('{') && !trimmedBody.startsWith('[')) {
            throw Exception(
                'Response does not appear to be JSON: $trimmedBody');
          }

          final dynamic parsedJson = jsonDecode(trimmedBody);
          print('🔧 DEBUG: JSON parsed successfully');
          print('🔧 DEBUG: Parsed JSON type: ${parsedJson.runtimeType}');
          print('🔧 DEBUG: Parsed JSON: $parsedJson');

          // Pastikan hasilnya adalah Map
          if (parsedJson is! Map) {
            throw Exception(
                'Parsed JSON is not a Map: ${parsedJson.runtimeType}');
          }

          // Convert ke Map<String, dynamic>
          final Map<String, dynamic> responseData =
              Map<String, dynamic>.from(parsedJson);
          print('📨 Final response data: $responseData');
          print('📨 Response data type: ${responseData.runtimeType}');
          print('📨 Response keys: ${responseData.keys.toList()}');

          // Validasi struktur response
          if (responseData.isEmpty) {
            throw Exception('Parsed response data is empty');
          }

          return responseData;
        } catch (e) {
          print('❌ Error parsing JSON response: $e');
          print('❌ Raw response was: "${response.body}"');
          print('❌ Response length: ${response.body.length}');
          print('❌ Response bytes: ${response.bodyBytes}');
          throw Exception('Failed to parse server response as JSON: $e');
        }
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending data to server: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Failed to send data to server: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTimingHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.1.14:8000/sipreti/timing/?id_pegawai=${widget.idPegawai}&limit=5'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['timing_data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting timing history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTimingStats() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.1.14:8000/sipreti/stats/?id_pegawai=${widget.idPegawai}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'];
      }
      return null;
    } catch (e) {
      print('Error getting timing stats: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Kamera Huffman',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics, color: Colors.white),
            onPressed: () => _showTimingHistoryDialog(),
          ),
        ],
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
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 60,
                  color: Colors.blue[600],
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
                  _status,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 50),

              // Camera Button
              Container(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _captureAndProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.blue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Memproses...'),
                          ],
                        )
                      : Row(
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
              // SizedBox(height: 30),

              // // ✅ TAMBAHKAN BUTTON UNTUK LIHAT TIMING HISTORY
              // Container(
              //   width: 200,
              //   child: OutlinedButton.icon(
              //     onPressed: () => _showTimingHistoryDialog(),
              //     icon: Icon(Icons.history, color: Colors.blue[600]),
              //     label: Text(
              //       'Lihat Riwayat Kecepatan',
              //       style: TextStyle(color: Colors.blue[600]),
              //     ),
              //     style: OutlinedButton.styleFrom(
              //       side: BorderSide(color: Colors.blue[600]!),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(30),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

// ✅ 4. TAMBAHKAN FUNCTION untuk show dialog timing history
  void _showTimingHistoryDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Riwayat Kecepatan'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([getTimingHistory(), getTimingStats()]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final timingData =
                  snapshot.data?[0] as List<Map<String, dynamic>>? ?? [];
              final stats = snapshot.data?[1] as Map<String, dynamic>?;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats section
                  if (stats != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📊 Statistik:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(
                              'Rata-rata Total: ${stats['avg_total_time_ms']}ms'),
                          Text(
                              'Rata-rata Mobile: ${stats['avg_mobile_time_ms']}ms'),
                          Text(
                              'Rata-rata Server: ${stats['avg_server_time_ms']}ms'),
                          Text('Success Rate: ${stats['success_rate']}%'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('📝 Riwayat 5 Terakhir:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                  ],

                  // History list
                  Expanded(
                    child: timingData.isEmpty
                        ? Center(child: Text('Belum ada data timing'))
                        : ListView.builder(
                            itemCount: timingData.length,
                            itemBuilder: (context, index) {
                              final item = timingData[index];
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    item['verification_success'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: item['verification_success'] == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  title: Text(
                                      'Total: ${item['grand_total_ms']}ms'),
                                  subtitle: Text(
                                    'Mobile: ${item['mobile_total_ms']}ms\n'
                                    'Server: ${item['server_total_ms']}ms',
                                  ),
                                  trailing: Text(
                                    item['created_at']?.substring(11, 19) ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

// Class HuffmanNode
class HuffmanNode {
  int? value;
  HuffmanNode? left;
  HuffmanNode? right;
  int frequency;

  HuffmanNode({this.value, this.frequency = 0, this.left, this.right});
}

// Fungsi encode
Future<Map<String, dynamic>> encodeImageHuffman(File imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception("Gambar tidak valid");
    }

    final img.Image resizedImage;
    if (image.width > 1000 || image.height > 1000) {
      resizedImage = img.copyResize(
        image,
        width: (image.width > image.height)
            ? 1000
            : (1000 * image.width ~/ image.height),
        height: (image.height > image.width)
            ? 1000
            : (1000 * image.height ~/ image.width),
      );
    } else {
      resizedImage = image;
    }

    final redChannel = Uint8List(resizedImage.width * resizedImage.height);
    final greenChannel = Uint8List(resizedImage.width * resizedImage.height);
    final blueChannel = Uint8List(resizedImage.width * resizedImage.height);

    int index = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        final pixel = resizedImage.getPixel(x, y);
        redChannel[index] = img.getRed(pixel);
        greenChannel[index] = img.getGreen(pixel);
        blueChannel[index] = img.getBlue(pixel);
        index++;
      }
    }

    final redResult = await compute(huffmanEncodeCompute, redChannel);
    final greenResult = await compute(huffmanEncodeCompute, greenChannel);
    final blueResult = await compute(huffmanEncodeCompute, blueChannel);

    if (redResult == null || greenResult == null || blueResult == null) {
      throw Exception("Gagal mengkompresi salah satu channel warna");
    }

    if (redResult["encoded_data"] == null ||
        greenResult["encoded_data"] == null ||
        blueResult["encoded_data"] == null) {
      throw Exception("Encoded data null pada salah satu channel");
    }

    if (redResult["root"] == null ||
        greenResult["root"] == null ||
        blueResult["root"] == null) {
      throw Exception("Root null pada salah satu channel");
    }

    final redEncodedString = base64Encode(redResult["encoded_data"]);
    final greenEncodedString = base64Encode(greenResult["encoded_data"]);
    final blueEncodedString = base64Encode(blueResult["encoded_data"]);

    final redRootBytes = utf8.encode(redResult["root"] ?? "{}");
    final greenRootBytes = utf8.encode(greenResult["root"] ?? "{}");
    final blueRootBytes = utf8.encode(blueResult["root"] ?? "{}");

    final redRootBase64 = base64Encode(redRootBytes);
    final greenRootBase64 = base64Encode(greenRootBytes);
    final blueRootBase64 = base64Encode(blueRootBytes);

    final Map<String, dynamic> encodedData = {
      "shape": [resizedImage.width, resizedImage.height],
      "width": resizedImage.width,
      "height": resizedImage.height,
      "is_rgb": true,
      "red_encoded": redEncodedString,
      "green_encoded": greenEncodedString,
      "blue_encoded": blueEncodedString,
      "red_root": redRootBase64,
      "green_root": greenRootBase64,
      "blue_root": blueRootBase64
    };

    return encodedData;
  } catch (e) {
    throw Exception("Error encoding image: $e");
  }
}

Map<String, dynamic> huffmanEncodeCompute(Uint8List pixels) {
  final Uint32List frequencies = Uint32List(256);
  for (int pixel in pixels) {
    frequencies[pixel]++;
  }

  final List<HuffmanNode> nodes = [];
  for (int i = 0; i < frequencies.length; i++) {
    if (frequencies[i] > 0) {
      nodes.add(HuffmanNode(value: i, frequency: frequencies[i]));
    }
  }

  nodes.sort((a, b) => a.frequency.compareTo(b.frequency));

  while (nodes.length > 1) {
    final left = nodes.removeAt(0);
    final right = nodes.removeAt(0);

    final parent = HuffmanNode(
      frequency: left.frequency + right.frequency,
      left: left,
      right: right,
    );

    int low = 0;
    int high = nodes.length - 1;
    int insertPos = nodes.length;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (nodes[mid].frequency < parent.frequency) {
        low = mid + 1;
      } else {
        insertPos = mid;
        high = mid - 1;
      }
    }

    nodes.insert(insertPos, parent);
  }

  final root = nodes.isEmpty ? HuffmanNode() : nodes[0];

  final List<String?> codes = List<String?>.filled(256, null);
  _buildCodesWithList(root, "", codes);

  final StringBuffer bitBuffer = StringBuffer();
  bitBuffer.writeAll(pixels.map((pixel) => codes[pixel]!));
  final String bitString = bitBuffer.toString();

  final int paddingLength = 8 - (bitString.length % 8);
  if (paddingLength < 8) {
    bitBuffer.write("0" * paddingLength);
  }

  final String paddedBitString = bitBuffer.toString();

  final int byteCount = (paddedBitString.length / 8).ceil();
  final Uint8List encodedData = Uint8List(byteCount);

  for (int i = 0; i < byteCount; i++) {
    int startIndex = i * 8;
    int endIndex = (i + 1) * 8;
    if (endIndex > paddedBitString.length) {
      endIndex = paddedBitString.length;
    }

    String byte = paddedBitString.substring(startIndex, endIndex);
    while (byte.length < 8) {
      byte += "0";
    }

    int byteValue = int.parse(byte, radix: 2);
    encodedData[i] = byteValue;
  }

  final paddedEncodedData = Uint8List(encodedData.length + 1);
  paddedEncodedData.setRange(0, encodedData.length, encodedData);
  paddedEncodedData[encodedData.length] = paddingLength.toInt();

  final String rootSerialized = _serializeHuffmanTreeOptimized(root);

  return {
    "encoded_data": paddedEncodedData,
    "root": rootSerialized,
    "shape": [pixels.length],
  };
}

String _serializeHuffmanTreeOptimized(HuffmanNode root) {
  Map<String, dynamic> treeMap = _nodeToMapSimplified(root);
  return jsonEncode(treeMap);
}

Map<String, dynamic> _nodeToMapSimplified(HuffmanNode node) {
  Map<String, dynamic> nodeMap = {};

  if (node.left == null && node.right == null && node.value != null) {
    nodeMap["type"] = "leaf";
    nodeMap["value"] = node.value;
    nodeMap["frequency"] = node.frequency;
    return nodeMap;
  }

  nodeMap["type"] = "internal";
  nodeMap["frequency"] = node.frequency;

  if (node.left != null) {
    nodeMap["left"] = _nodeToMapSimplified(node.left!);
  } else {
    nodeMap["left"] = null;
  }

  if (node.right != null) {
    nodeMap["right"] = _nodeToMapSimplified(node.right!);
  } else {
    nodeMap["right"] = null;
  }

  return nodeMap;
}

void _buildCodesWithList(HuffmanNode node, String code, List<String?> codes) {
  if (node.left == null && node.right == null && node.value != null) {
    codes[node.value!] = code.isEmpty ? "0" : code;
    return;
  }

  if (node.left != null) {
    _buildCodesWithList(node.left!, code + "0", codes);
  }

  if (node.right != null) {
    _buildCodesWithList(node.right!, code + "1", codes);
  }
}
