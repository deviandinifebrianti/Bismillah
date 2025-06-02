import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'package:absensi/pages/checkout.dart'; // Halaman tujuan setelah foto
import 'package:http_parser/http_parser.dart'; // untuk MediaType
import 'dart:async' show Future, TimeoutException;

const String baseUrl = "http://192.168.1.14:8000";

Map<String, dynamic> processOriginalImage(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception('Gagal mendekode gambar');
  }

  final grayscale = img.grayscale(image);

  // Periksa apakah jumlah piksel sesuai dengan dimensi
  final pixels = grayscale.getBytes(format: img.Format.luminance);

  if (pixels.length != grayscale.width * grayscale.height) {
    debugPrint(
        "⚠️ Peringatan: Jumlah piksel (${pixels.length}) tidak sesuai dengan dimensi (${grayscale.width}x${grayscale.height} = ${grayscale.width * grayscale.height})");

    // Sesuaikan piksel agar sesuai dengan dimensi
    List<int> adjustedPixels;

    if (pixels.length < grayscale.width * grayscale.height) {
      // Jika piksel kurang, tambahkan piksel hitam (0)
      adjustedPixels = List<int>.from(pixels);
      final missing = (grayscale.width * grayscale.height) - pixels.length;
      adjustedPixels.addAll(List<int>.filled(missing, 0));
      debugPrint("➕ Menambahkan $missing piksel hitam");
    } else {
      // Jika piksel lebih, potong kelebihan
      adjustedPixels = pixels.sublist(0, grayscale.width * grayscale.height);
      debugPrint(
          "✂️ Memotong ${pixels.length - (grayscale.width * grayscale.height)} piksel berlebih");
    }

    return {
      'pixels': adjustedPixels,
      'width': image.width,
      'height': image.height,
    };
  }

  return {
    'pixels': pixels,
    'width': image.width,
    'height': image.height,
  };
}

class RLEEncoder {
  // Fungsi untuk mengompresi data menggunakan Run-Length Encoding
  Map<String, dynamic> encode(List<int> pixels, int width, int height) {
    debugPrint("▶️ Mulai kompresi RLE. Jumlah pixel: ${pixels.length}");

    // Tambahkan pengukuran waktu
    final Stopwatch stopwatch = Stopwatch()..start();

    List<int> compressedData = [];
    Map<int, int> frequencies = {};

    int i = 0;
    while (i < pixels.length) {
      int currentValue = pixels[i];
      int runStart = i;

      // Hitung frekuensi untuk setiap nilai piksel
      frequencies[currentValue] = (frequencies[currentValue] ?? 0) + 1;

      // Cari panjang run (piksel berurutan yang sama)
      while (i + 1 < pixels.length &&
          pixels[i + 1] == currentValue &&
          (i + 1 - runStart) < 255) {
        i++;
        frequencies[currentValue] = (frequencies[currentValue] ?? 0) + 1;
      }

      int runLength = i - runStart + 1;

      // Optimalkan: hanya gunakan format run jika run cukup panjang
      if (runLength >= 3) {
        compressedData.add(runLength);
        compressedData.add(currentValue);
      } else {
        // Untuk run yang pendek, simpan sebagai nilai individual
        for (int j = 0; j < runLength; j++) {
          compressedData.add(1);
          compressedData.add(currentValue);
        }
      }

      i++;
    }
    int originalSize = pixels.length;
    int compressedSize = compressedData.length;

    // Hitung compression ratio
    double compressionRatio = originalSize / compressedSize;

    // Hitung waktu kompresi
    stopwatch.stop();
    int compressionTimeMillis = stopwatch.elapsedMilliseconds;

    debugPrint("✅ Kompresi selesai. Ukuran sebelum: ${originalSize}, "
        "ukuran setelah: ${compressedSize}");
    debugPrint("📊 Rasio kompresi: ${compressionRatio.toStringAsFixed(2)}x");
    debugPrint("⏱️ Waktu kompresi: ${compressionTimeMillis} ms");

    // Return hasil kompresi dan informasi yang diperlukan
    return {
      'compressedData': compressedData,
      'width': width,
      'height': height,
      'originalLength': pixels.length,
      // Tambahkan metrik kompresi
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'compressionTimeMillis': compressionTimeMillis,
      'originalPixels': pixels,
      'frequencies': frequencies,
    };
  }

  // Fungsi untuk mendekode data RLE (untuk keperluan debugging)
  List<int> decode(List<int> compressedData) {
    List<int> decodedPixels = [];

    int i = 0;
    while (i < compressedData.length) {
      int count = compressedData[i];
      int value = compressedData[i + 1];

      for (int j = 0; j < count; j++) {
        decodedPixels.add(value);
      }

      i += 2;
    }
    return decodedPixels;
  }
}

Future<int?> kirimKompresiKeDjango(
    String idPegawai, Map<String, dynamic> compressionResult) async {
  final uri = Uri.parse('$baseUrl/sipreti/kompresi/');

  final maxPacketSize = 1024 * 1024; // 1MB
  final compressedData = compressionResult['compressedData'] as List<int>;

  debugPrint("📏 Ukuran data kompresi: ${compressedData.length} bytes");

  // Jika data lebih besar dari batas, potong
  if (compressedData.length > maxPacketSize) {
    debugPrint("⚠️ Data terlalu besar, memperkecil ukuran data");
    compressionResult['compressedData'] =
        compressedData.sublist(0, maxPacketSize);
    debugPrint(
        "✂️ Dipotong menjadi ${compressionResult['compressedData'].length} bytes");
  }
  Map<String, int> frequencyModel = {};

  // Gunakan frequencies dari kompresi jika ada
  if (compressionResult.containsKey('frequencies')) {
    final frequencies = compressionResult['frequencies'] as Map<int, int>;
    // Konversi key dari int ke string untuk JSON
    frequencies.forEach((key, value) {
      frequencyModel[key.toString()] = value;
    });
  } else if (compressionResult.containsKey('originalPixels')) {
    // Buat dari originalPixels jika tidak ada frequencies
    final pixels = compressionResult['originalPixels'] as List<int>;
    for (final pixel in pixels) {
      final key = pixel.toString();
      frequencyModel[key] = (frequencyModel[key] ?? 0) + 1;
    }
  } else {
    // Fallback jika tidak ada data: buat frequency model dummy
    // (umumnya tidak diperlukan untuk RLE tapi server mungkin membutuhkannya)
    for (int i = 0; i < 256; i++) {
      frequencyModel[i.toString()] = 1;
    }
  }
  // Buat client dengan timeout yang lebih panjang
  final client = http.Client();
  try {
    final request = http.MultipartRequest('POST', uri)
      ..fields['id_pegawai'] = idPegawai
      ..fields['width'] = compressionResult['width'].toString()
      ..fields['height'] = compressionResult['height'].toString()
      ..fields['original_length'] =
          compressionResult['originalLength'].toString()
      ..fields['compression_type'] = 'rle' // Tipe kompresi RLE
      ..fields['is_rgb'] = ''
      ..fields['frequency_model'] = jsonEncode(frequencyModel)
      // Tambahkan code_table kosong (tidak diperlukan untuk RLE tapi mungkin diharapkan oleh server)
      ..fields['code_table'] = jsonEncode({})
      // Tambahkan metrik kompresi
      ..fields['original_size'] = compressionResult['originalSize'].toString()
      ..fields['compressed_size'] =
          compressionResult['compressedSize'].toString()
      ..fields['compression_ratio'] =
          compressionResult['compressionRatio'].toString()
      ..fields['compression_time_ms'] =
          compressionResult['compressionTimeMillis'].toString()
      // Mengirim data kompresi sebagai file dalam bentuk byte
      ..files.add(
        http.MultipartFile.fromBytes(
          'compressed_file',
          Int8List.fromList(compressionResult['compressedData']),
          filename: 'compressed.bin',
          contentType: MediaType('application', 'octet-stream'),
        ),
      );

    // Gunakan timeout yang lebih panjang
    final streamedResponse = await request.send().timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Koneksi timeout saat mengirim data');
      },
    );

    final response = await http.Response.fromStream(streamedResponse);
    debugPrint("📤 Mengirim ke Django: ${uri.toString()}");
    debugPrint("📝 ID Pegawai: $idPegawai");
    debugPrint(
        "🧠 Panjang data terkompresi: ${(compressionResult['compressedData'] as List).length}");

    // Logging metrik kompresi
    debugPrint("📊 Ukuran asli: ${compressionResult['originalSize']} bytes");
    debugPrint(
        "📊 Ukuran kompresi: ${compressionResult['compressedSize']} bytes");
    debugPrint(
        "📊 Rasio kompresi: ${compressionResult['compressionRatio'].toStringAsFixed(2)}x");
    debugPrint(
        "⏱️ Waktu kompresi: ${compressionResult['compressionTimeMillis']} ms");

    if (response.statusCode == 200) {
      debugPrint('✅ Data RLE berhasil dikirim');
      final responseData = jsonDecode(response.body);
      return responseData['kompresi_id'];
    } else {
      debugPrint(
          '❌ Gagal kirim data RLE: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('❌ Exception saat mengirim data: $e');
    return null;
  } finally {
    client.close();
  }
}

class KameraPage3 extends StatefulWidget {
  final String idPegawai;
  final int jenis;
  final String lokasi;
  final int checkMode;
  final String nama;
  final String nip;
  final String idUnitKerja;
  final String latitude;
  final String longitude;
  final int? kompresiId;

  const KameraPage3({
    super.key,
    required this.idPegawai,
    required this.jenis,
    required this.lokasi,
    required this.checkMode,
    required this.nama,
    required this.nip,
    required this.idUnitKerja,
    required this.latitude,
    required this.longitude,
    this.kompresiId,
  });

  @override
  KameraPageState createState() => KameraPageState();
}

class KameraPageState extends State<KameraPage3> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![1],
          ResolutionPreset.medium,
        );

        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        debugPrint("Tidak ada kamera tersedia.");
      }
    } catch (e) {
      debugPrint("Gagal inisialisasi kamera: $e");
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      if (_isProcessing) return; // Prevent multiple captures

      setState(() {
        _isProcessing = true;
      });

      try {
        showProcessingIndicator();

        final image = await _cameraController!.takePicture();
        final imageFile = File(image.path);
        final imageBytes = await imageFile.readAsBytes();

        final resizedImage =
            _resizeImageIfNeeded(imageBytes, maxWidth: 480, maxHeight: 640);

        final result = processOriginalImage(resizedImage);
        final originalPixels = result['pixels'] as List<int>;
        final width = result['width'] as int;
        final height = result['height'] as int;

        // Gunakan RLEEncoder
        final encoder = RLEEncoder();
        final compressionResult = encoder.encode(originalPixels, width, height);

        // Kirim ke Django dengan retry
        int retryCount = 0;
        int maxRetries = 3;
        int? kompresiId;

        while (retryCount < maxRetries && kompresiId == null) {
          try {
            retryCount++;
            kompresiId = await kirimKompresiKeDjango(
                widget.idPegawai, compressionResult);

            if (kompresiId == null && retryCount < maxRetries) {
              debugPrint("🔄 Coba kirim lagi (${retryCount}/${maxRetries})");
              await Future.delayed(
                  Duration(seconds: 2 * retryCount)); // Exponential backoff
            }
          } catch (e) {
            debugPrint("⚠️ Error saat pengiriman #${retryCount}: $e");
            if (retryCount >= maxRetries) rethrow;
            await Future.delayed(Duration(seconds: 2 * retryCount));
          }
        }

        if (kompresiId == null) {
          throw Exception(
              'Gagal mengirim data setelah ${maxRetries}x percobaan');
        }

        // Tunggu sebentar untuk memastikan data tersimpan di server
        await Future.delayed(Duration(milliseconds: 500));

        if (!mounted) return;

        // Navigate ke CheckOutPage
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckOutPage(
              kompresiId: kompresiId,
              idPegawai: widget.idPegawai,
              imagePath: image.path,
              imageData: imageBytes,
              jenis: widget.jenis,
              lokasi: widget.lokasi,
              checkMode: widget.checkMode,
              nama: widget.nama,
              nip: widget.nip,
              idUnitKerja: widget.idUnitKerja,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
          ),
        );
      } catch (e, stackTrace) {
        setState(() {
          _isProcessing = false;
        });

        print("ERROR: $e");
        print("Stack Trace: $stackTrace");

        if (!mounted) return;
        final errorMsg = e.toString().toLowerCase();
        final isConnectionError = errorMsg.contains('socket') ||
            errorMsg.contains('koneksi') ||
            errorMsg.contains('connection') ||
            errorMsg.contains('network') ||
            errorMsg.contains('jaringan') ||
            errorMsg.contains('host') ||
            errorMsg.contains('server');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isConnectionError
                    ? 'Tidak dapat terhubung ke server. Silakan periksa:'
                    : 'Gagal memproses gambar:'),
                if (isConnectionError) ...[
                  SizedBox(height: 12),
                  Text('• Koneksi WiFi/internet perangkat'),
                  Text('• Alamat server (${baseUrl})'),
                  Text('• Server berjalan dan dapat diakses'),
                ] else
                  Text(e.toString()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  // Fungsi untuk memperkecil gambar jika terlalu besar
  Uint8List _resizeImageIfNeeded(Uint8List imageBytes,
      {required int maxWidth, required int maxHeight}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Gagal mendekode gambar');
    }

    // Jika gambar sudah cukup kecil, kembalikan apa adanya
    if (image.width <= maxWidth && image.height <= maxHeight) {
      return imageBytes;
    }

    // Hitung rasio untuk menjaga aspek ratio
    double widthRatio = maxWidth / image.width;
    double heightRatio = maxHeight / image.height;
    double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

    // Hitung dimensi baru
    int newWidth = (image.width * ratio).round();
    int newHeight = (image.height * ratio).round();
    debugPrint(
        "🖼️ Mengubah ukuran gambar dari ${image.width}x${image.height} menjadi ${newWidth}x${newHeight}");

    // Resize gambar
    final resized = img.copyResize(image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average);

    // Konversi kembali ke bytes
    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }

  void showProcessingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 5,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Memproses...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mohon tunggu sebentar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RLE', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 33, 137, 235),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color(0xFF2A363B),
      body: Stack(
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: RotatedBox(
                quarterTurns: 1,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14),
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 55.0),
              child: SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 10,
                  ),
                  onPressed: _isProcessing ? null : _captureImage,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
