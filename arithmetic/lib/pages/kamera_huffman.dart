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
import 'dart:collection'; // untuk PriorityQueue
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

const String baseUrl = "http://192.168.1.14:8000";

// Kelas Node untuk membuat pohon Huffman
class HuffmanNode implements Comparable<HuffmanNode> {
  int? value; // Nilai pixel (0-255) atau null untuk node internal
  int frequency; // Frekuensi kemunculan
  HuffmanNode? left;
  HuffmanNode? right;

  HuffmanNode({this.value, required this.frequency, this.left, this.right});

  // Fungsi untuk membandingkan node (untuk priority queue)
  @override
  int compareTo(HuffmanNode other) {
    return frequency - other.frequency;
  }
}

Map<int, int> countFrequencies(List<int> pixels) {
  final freq = <int, int>{};
  for (final pixel in pixels) {
    freq[pixel] = (freq[pixel] ?? 0) + 1;
  }
  return freq;
}

class HuffmanEncoder {
  // Fungsi untuk mengompresi data menggunakan Huffman coding
  Map<String, dynamic> encode(List<int> pixels, int width, int height) {
    debugPrint("▶️ Mulai kompresi Huffman. Jumlah pixel: ${pixels.length}");

    // Tambahkan pengukuran waktu
    final Stopwatch stopwatch = Stopwatch()..start();

    // Hitung frekuensi kemunculan setiap nilai pixel
    Map<int, int> frequencies = countFrequencies(pixels);
    debugPrint("📊 Jumlah nilai unik: ${frequencies.length}");

    // Buat pohon Huffman
    HuffmanNode? root = _buildHuffmanTree(frequencies);

    // Buat tabel kode Huffman
    Map<int, List<int>> codeTable = {};
    _buildCodeTable(root!, [], codeTable);

    debugPrint(
        "📝 Tabel kode berhasil dibuat. Jumlah entry: ${codeTable.length}");

    // Enkode data menggunakan tabel kode
    List<int> encodedBits = [];
    for (int pixel in pixels) {
      encodedBits.addAll(codeTable[pixel]!);
    }

    // Konversi bitstream ke bytestream
    List<int> compressedData = _bitsToBytes(encodedBits);

    // Hitung ukuran sebelum dan sesudah kompresi (dalam byte)
    int originalSize = pixels.length;
    int compressedSize = compressedData.length;

    // Hitung compression ratio
    double compressionRatio = originalSize / compressedSize;

    // Hitung waktu kompresi
    stopwatch.stop();
    int compressionTimeMillis = stopwatch.elapsedMilliseconds;

    // // Konversi tabel kode untuk disimpan (key string, value array bits)
    Map<String, List<int>> serializedCodeTable = {};
    codeTable.forEach((key, value) {
      serializedCodeTable[key.toString()] = value;
    });

    Map<String, int> serializedFrequencies = {};
    frequencies.forEach((key, value) {
      serializedFrequencies[key.toString()] = value;
    });

    // Tampilkan info validasi untuk debugging
    int paddingBits = compressedData.isEmpty ? 0 : compressedData.last;
    debugPrint("Validasi data kompresi berhasil, padding=$paddingBits");

    // Return hasil kompresi dan informasi yang diperlukan
    return {
      'compressedData': compressedData,
      'codeTable': serializedCodeTable,
      'frequencies': serializedFrequencies,
      'width': width,
      'height': height,
      'originalLength': pixels.length,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'compressionTimeMillis': compressionTimeMillis,
    };
  }

  // Fungsi untuk membuat pohon Huffman dari tabel frekuensi
  HuffmanNode? _buildHuffmanTree(Map<int, int> frequencies) {
    // Gunakan List sebagai Priority Queue sederhana
    List<HuffmanNode> nodes = [];

    // Tambahkan semua nilai ke nodes sebagai leaf node
    frequencies.forEach((value, frequency) {
      nodes.add(HuffmanNode(value: value, frequency: frequency));
    });

    // Proses nodes sampai hanya tersisa satu node (root)
    while (nodes.length > 1) {
      // Urutkan berdasarkan frekuensi
      nodes.sort((a, b) => a.frequency.compareTo(b.frequency));

      // Ambil dua node dengan frekuensi terendah
      HuffmanNode left = nodes.removeAt(0);
      HuffmanNode right = nodes.removeAt(0);

      // Buat node baru dengan children dari dua node tadi
      HuffmanNode parent = HuffmanNode(
        value: null, // Node internal tidak punya nilai
        frequency: left.frequency + right.frequency,
        left: left,
        right: right,
      );

      // Tambahkan node baru ke nodes
      nodes.add(parent);
    }

    // Return root dari pohon Huffman
    return nodes.isEmpty ? null : nodes[0];
  }

  // Fungsi rekursif untuk membuat tabel kode dari pohon Huffman
  void _buildCodeTable(
      HuffmanNode node, List<int> currentCode, Map<int, List<int>> codeTable) {
    // Jika node adalah leaf (memiliki nilai), tambahkan ke tabel kode
    if (node.value != null) {
      codeTable[node.value!] = List<int>.from(currentCode);
      return;
    }

    // Traverse left (tambahkan 0)
    if (node.left != null) {
      currentCode.add(0);
      _buildCodeTable(node.left!, currentCode, codeTable);
      currentCode.removeLast();
    }

    // Traverse right (tambahkan 1)
    if (node.right != null) {
      currentCode.add(1);
      _buildCodeTable(node.right!, currentCode, codeTable);
      currentCode.removeLast();
    }
  }

  // Konversi bitstream ke bytestream
  List<int> _bitsToBytes(List<int> bits) {
    List<int> bytes = [];
    int currentByte = 0;
    int bitPos = 7;

    for (int bit in bits) {
      if (bit == 1) {
        currentByte |= (1 << bitPos);
      }

      bitPos--;
      if (bitPos < 0) {
        bytes.add(currentByte);
        currentByte = 0;
        bitPos = 7;
      }
    }

    // Tambahkan byte terakhir jika ada bit yang belum diproses
    if (bitPos != 7) {
      bytes.add(currentByte);
    }

    // Hitung jumlah padding bit
    int paddingBits = (bitPos + 1) % 8;

    // Tambahkan jumlah padding bit sebagai byte terakhir
    bytes.add(paddingBits);

    return bytes;
  }
}

// Fungsi untuk mengompres gambar dengan flutter_image_compress
Future<Uint8List> compressImageWithLibrary(Uint8List imageBytes) async {
  try {
    final result = await FlutterImageCompress.compressWithList(
      imageBytes,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    debugPrint(
        "🖼️ Kompresi gambar: ${imageBytes.length} -> ${result.length} bytes");
    return result;
  } catch (e) {
    debugPrint("⚠️ Gagal mengompres gambar dengan library: $e");
    return imageBytes; // Kembalikan gambar asli jika gagal
  }
}

// Fungsi untuk memproses gambar menjadi array grayscale
Future<Map<String, dynamic>> processImageToGrayscale(
    Uint8List imageBytes) async {
  try {
    // Pertama kompresi dengan flutter_image_compress
    final compressedImage = await compressImageWithLibrary(imageBytes);

    // Kemudian lakukan proses grayscale dalam isolate terpisah
    return compute(_processGrayscaleInIsolate, compressedImage);
  } catch (e) {
    debugPrint("❌ Gagal dalam pre-processing: $e");
    // Jika kompresi gagal, gunakan gambar asli
    return compute(_processGrayscaleInIsolate, imageBytes);
  }
}

// Fungsi untuk dijalankan di isolate terpisah
Map<String, dynamic> _processGrayscaleInIsolate(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception('Gagal mendekode gambar');
  }

  final grayscale = img.grayscale(image);

  // Dapatkan semua piksel dalam format grayscale
  final pixels =
      List<int>.from(grayscale.getBytes(format: img.Format.luminance));

  // Pastikan jumlah piksel sesuai dengan dimensi
  if (pixels.length != grayscale.width * grayscale.height) {
    debugPrint(
        "⚠️ Peringatan: Jumlah piksel (${pixels.length}) tidak sesuai dengan dimensi (${grayscale.width}x${grayscale.height} = ${grayscale.width * grayscale.height})");

    // Sesuaikan piksel
    if (pixels.length < grayscale.width * grayscale.height) {
      // Tambahkan piksel hitam (0)
      pixels.addAll(List<int>.filled(
          grayscale.width * grayscale.height - pixels.length, 0));
    } else {
      // Potong kelebihan piksel
      return {
        'pixels': pixels.sublist(0, grayscale.width * grayscale.height),
        'width': grayscale.width,
        'height': grayscale.height,
      };
    }
  }

  return {
    'pixels': pixels,
    'width': grayscale.width,
    'height': grayscale.height,
  };
}

// Fungsi untuk memperkecil gambar jika terlalu besar
Future<Uint8List> resizeImageIfNeeded(Uint8List imageBytes,
    {required int maxWidth, required int maxHeight}) async {
  return compute(_resizeImageInIsolate,
      {'imageBytes': imageBytes, 'maxWidth': maxWidth, 'maxHeight': maxHeight});
}

// Fungsi resize yang dijalankan di isolate terpisah
Uint8List _resizeImageInIsolate(Map<String, dynamic> params) {
  final imageBytes = params['imageBytes'] as Uint8List;
  final maxWidth = params['maxWidth'] as int;
  final maxHeight = params['maxHeight'] as int;

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

  // Resize gambar
  final resized = img.copyResize(image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.average);

  // Konversi kembali ke bytes
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

bool validateCompressionData(Map<int, int> frequencies,
    Map<int, List<int>> codeTable, List<int> compressedData) {
  // Cek frequencies: semua key int, value > 0
  for (var entry in frequencies.entries) {
    if (entry.value < 1) {
      print("Frequency untuk key ${entry.key} harus > 0");
      return false;
    }
  }

  // Cek codeTable: key int, value list dengan elemen 0 atau 1
  for (var entry in codeTable.entries) {
    if (!entry.value.every((bit) => bit == 0 || bit == 1)) {
      print("CodeTable untuk key ${entry.key} harus berupa list 0 dan 1 saja");
      return false;
    }
  }

  // Cek compressedData minimal ada 1 byte (padding)
  if (compressedData.isEmpty) {
    print("CompressedData kosong");
    return false;
  }

  // Cek padding: byte terakhir harus antara 0 dan 7
  int padding = compressedData.last;
  if (padding < 0 || padding > 7) {
    print("Padding tidak valid: $padding");
    return false;
  }

  print("Validasi data kompresi berhasil, padding=$padding");
  return true;
}

// Fungsi untuk mengirim data kompresi ke server Django
Future<dynamic> kirimKompresiKeDjango(
    String idPegawai, Map<String, dynamic> compressionResult) async {
  debugPrint(
      'frequencies type before compute: ${compressionResult['frequencies'].runtimeType}');
  debugPrint(
      'codeTable type before compute: ${compressionResult['codeTable'].runtimeType}');
  // bool isValid = validateCompressionData(
  //   compressionResult['frequencies'] as Map<int, int>,
  //   compressionResult['codeTable'] as Map<int, List<int>>,
  //   compressionResult['compressedData'] as List<int>,
  // );

  // if (!isValid) {
  //   debugPrint("❌ Data kompresi tidak valid. Pengiriman dibatalkan.");
  //   return null; // Atau bisa lempar exception sesuai kebutuhan
  // }

  // Gunakan compute untuk memindahkan pekerjaan ke isolate terpisah
  return compute(_kirimKompresiDiBackground, {
    'idPegawai': idPegawai,
    'compressionResult': compressionResult,
    'baseUrl': baseUrl,
  });
}

Future<int?> _kirimKompresiDiBackground(Map<String, dynamic> params) async {
  final idPegawai = params['idPegawai'] as String;
  final compressionResult = params['compressionResult'] as Map<String, dynamic>;
  final baseUrl = params['baseUrl'] as String;
  final uri = Uri.parse('${baseUrl}/sipreti/kompresi/');

  try {
    // Konversi frequencies ke format string key untuk pengiriman
    // final frequencyModelStrKey =
    //     (compressionResult['frequencies'] as Map<int, int>)
    //         .map((key, value) => MapEntry(key.toString(), value));
    final frequencies = compressionResult['frequencies'];

    // // PERUBAHAN DI SINI - Konversi codeTable ke format yang bisa di-JSON
    // final Map<String, List<dynamic>> serializedCodeTable = {};

    // // Handle berbagai kemungkinan tipe data codeTable
    // if (compressionResult['codeTable'] is Map<int, List<int>>) {
    //   (compressionResult['codeTable'] as Map<int, List<int>>).forEach((key, value) {
    //     serializedCodeTable[key.toString()] = value.map((bit) => bit as dynamic).toList();
    //   });
    // } else if (compressionResult['codeTable'] is Map<dynamic, dynamic>) {
    //   (compressionResult['codeTable'] as Map<dynamic, dynamic>).forEach((key, value) {
    //     if (value is List) {
    //       serializedCodeTable[key.toString()] = List<dynamic>.from(value);
    //     } else {
    //       // Jika bukan List, konversi ke string (fallback)
    //       serializedCodeTable[key.toString()] = [value.toString()];
    //     }
    //   });
    // } else {
    //   // Fallback untuk tipe data lain
    //   debugPrint('⚠️ tipe codeTable tidak dikenal: ${compressionResult['codeTable'].runtimeType}');
    //   serializedCodeTable['error'] = ['unknown_type'];
    // }

    // // Log untuk debugging
    // debugPrint('📝 Preparing to encode code table with ${serializedCodeTable.length} entries');

    // // Konversi ke JSON, dengan penanganan error
    // String codeTableJson;
    // try {
    //   codeTableJson = jsonEncode(serializedCodeTable);
    //   debugPrint('✅ Code table successfully encoded to JSON');
    // } catch (e) {
    //   debugPrint('❌ Failed to encode code table: $e');
    //   // Fallback sederhana jika encoding gagal
    //   codeTableJson = '{}';
    // }

    debugPrint('Mempersiapkan data untuk pengiriman...');

    // Debugging untuk melihat tipe data yang sebenarnya
    debugPrint(
        'frequencies type: ${compressionResult['frequencies'].runtimeType}');
    debugPrint('codeTable type: ${compressionResult['codeTable'].runtimeType}');

    // Encode ke JSON tanpa casting
    final String frequencyModelJson =
        jsonEncode(compressionResult['frequencies']);
    final String codeTableJson = jsonEncode(compressionResult['codeTable']);

    debugPrint('Data berhasil di-encode ke JSON');

    final request = http.MultipartRequest('POST', uri)
      ..fields['id_pegawai'] = idPegawai
      ..fields['width'] = compressionResult['width'].toString()
      ..fields['height'] = compressionResult['height'].toString()
      ..fields['frequency_model'] = frequencyModelJson
      ..fields['code_table'] = codeTableJson
      ..fields['compression_type'] = 'optimized_huffman'
      ..fields['original_length'] =
          compressionResult['originalLength'].toString()
      ..fields['original_size'] = compressionResult['originalSize'].toString()
      ..fields['compressed_size'] =
          compressionResult['compressedSize'].toString()
      ..fields['compression_ratio'] =
          compressionResult['compressionRatio'].toString()
      ..fields['compression_time_ms'] =
          compressionResult['compressionTimeMillis'].toString();

    // Tambahkan file compressed_data
    request.files.add(
      http.MultipartFile.fromBytes(
        'compressed_file',
        compressionResult['compressedData'],
        filename: 'compressed.bin',
        contentType: MediaType('application', 'octet-stream'),
      ),
    );

    debugPrint('📤 Sending request to server...');
    final streamedResponse =
        await request.send().timeout(Duration(seconds: 20), onTimeout: () {
      throw TimeoutException('Request timed out after 20 seconds');
    });

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      debugPrint('✅ Bitstream berhasil dikirim');
      final responseData = jsonDecode(response.body);
      return responseData['kompresi_id'];
    } else {
      debugPrint(
          '❌ Gagal kirim bitstream: ${response.statusCode} - ${response.body}');
      if (response.body.length < 1000) {
        debugPrint('Response body: ${response.body}');
      }
      return null;
    }
  } catch (e) {
    debugPrint('❌ Exception saat mengirim data: $e');
    return null;
  }
}

// Konversi frequencies ke format string key untuk pengiriman
//   final frequencyModelStrKey =
//       (compressionResult['frequencies'] as Map<int, int>)
//           .map((key, value) => MapEntry(key.toString(), value));

//   final codeTable = compressionResult['codeTable'];
//   final codeTableJson = jsonEncode(codeTable);

//   try {
//     final request = http.MultipartRequest('POST', uri)
//       ..fields['id_pegawai'] = idPegawai
//       ..fields['width'] = compressionResult['width'].toString()
//       ..fields['height'] = compressionResult['height'].toString()
//       ..fields['frequency_model'] = jsonEncode(frequencyModelStrKey)
//       ..fields['code_table'] = codeTableJson
//       ..fields['compression_type'] = 'optimized_huffman'
//       ..fields['original_length'] =
//           compressionResult['originalLength'].toString()
//       ..fields['original_size'] = compressionResult['originalSize'].toString()
//       ..fields['compressed_size'] =
//           compressionResult['compressedSize'].toString()
//       ..fields['compression_ratio'] =
//           compressionResult['compressionRatio'].toString()
//       ..fields['compression_time_ms'] =
//           compressionResult['compressionTimeMillis'].toString()
//       // Mengirim data kompresi sebagai file dalam bentuk byte
//       ..files.add(
//         http.MultipartFile.fromBytes(
//           'compressed_file',
//           compressionResult['compressedData'],
//           filename: 'compressed.bin',
//           contentType: MediaType('application', 'octet-stream'),
//         ),
//       );

//     final streamedResponse =
//         await request.send().timeout(Duration(seconds: 20), onTimeout: () {
//       throw TimeoutException('Request timed out after 20 seconds');
//     });

//     final response = await http.Response.fromStream(streamedResponse);

//     if (response.statusCode == 200) {
//       debugPrint('✅ Bitstream berhasil dikirim');
//       final responseData = jsonDecode(response.body);
//       return responseData['kompresi_id'];
//     } else {
//       debugPrint(
//           '❌ Gagal kirim bitstream: ${response.statusCode} - ${response.body}');
//       return null;
//     }
//   } catch (e) {
//     debugPrint('❌ Exception saat mengirim data: $e');
//     return null;
//   }
// }

class KameraPage2 extends StatefulWidget {
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

  const KameraPage2({
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

const int FACE_DETECTION_DELAY_MS = 1500;

class KameraPageState extends State<KameraPage2> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _progressMessage = 'Memproses...';
  bool _dialogShown = false;
  bool _isCapturingImage = false;

  // Face detection variables
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15, // Face must take up at least 15% of screen
    ),
  );
  bool _isFaceDetectionActive = false;
  bool _isFaceDetected = false;
  bool _isDetectingFace = false;
  Size? _cameraSize;

  // Timer for periodic face detection
  Timer? _faceDetectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        CameraDescription frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(
          // _cameras![1], // Kamera depan
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          // imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });

        // Mulai deteksi wajah dengan delay
        _startFaceDetectionWithDelay();
      } else {
        debugPrint("Tidak ada kamera tersedia.");
      }
    } catch (e) {
      debugPrint("Gagal inisialisasi kamera: $e");
    }
  }

  Future<void> _detectFaceOnce() async {
    // Hindari multiple deteksi bersamaan atau pengambilan gambar bersamaan
    if (_isDetectingFace ||
        !_isFaceDetectionActive ||
        _isProcessing ||
        _isCapturingImage) return;

    _isDetectingFace = true;
    _isCapturingImage =
        true; // Tandai bahwa proses pengambilan gambar sedang berjalan

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _isDetectingFace = false;
        _isCapturingImage = false;
        return;
      }

      // Tambahkan delay kecil untuk memastikan kamera siap
      await Future.delayed(Duration(milliseconds: 100));

      // Tangkap gambar dengan await
      final XFile imageFile = await _cameraController!.takePicture();

      // Deteksi wajah dari file
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      // Hapus file sementara
      await File(imageFile.path).delete();

      if (!mounted) {
        _isDetectingFace = false;
        _isCapturingImage = false;
        return;
      }

      setState(() {
        _isFaceDetected = faces.isNotEmpty;
      });
    } catch (e) {
      debugPrint("Error saat deteksi wajah: $e");
    } finally {
      // Pastikan flag diatur false di finally untuk menghindari deadlock
      _isDetectingFace = false;
      _isCapturingImage = false; // Penting untuk mereset flag ini
    }
  }

// Juga perlu mengubah _startFaceDetectionWithDelay() untuk memberikan waktu yang cukup:
  void _startFaceDetectionWithDelay() {
    _isFaceDetectionActive = true;

    // Jangan langsung mulai deteksi, beri jeda sedikit
    Future.delayed(Duration(milliseconds: 500), () {
      // Deteksi pertama kali setelah delay
      _detectFaceOnce();
    });

    // Atur timer untuk deteksi berikutnya dengan interval lebih panjang (2 detik)
    _faceDetectionTimer = Timer.periodic(Duration(milliseconds: 2000), (_) {
      if (_isFaceDetectionActive &&
          !_isProcessing &&
          !_isDetectingFace &&
          !_isCapturingImage) {
        _detectFaceOnce();
      }
    });
  }

  // Fungsi untuk menampilkan indikator progres dengan pesan
  void showProgressDialog(String message) {
    setState(() {
      _progressMessage = message;
    });

    if (!_dialogShown && mounted) {
      _dialogShown = true;
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
                      _progressMessage,
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
  }

  // Fungsi untuk memperbarui pesan progres
  void updateProgress(String message) {
    setState(() {
      _progressMessage = message;
    });
  }

  // Fungsi untuk menyembunyikan dialog progres
  void hideProgressDialog() {
    if (_dialogShown && mounted) {
      _dialogShown = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      if (_isProcessing || _isCapturingImage)
        return; // Cek apakah pengambilan gambar sedang berjalan

      // Check if a face is detected before capturing
      if (!_isFaceDetected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Tidak ada wajah terdeteksi. Posisikan wajah Anda di tengah kamera.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
        _isCapturingImage = true; // Tambahkan flag
      });

      try {
        _faceDetectionTimer?.cancel();
        _isFaceDetectionActive = false;

        showProgressDialog('Mengambil gambar...');

        final image = await _cameraController!.takePicture();
        final imageFile = File(image.path);
        final imageBytes = await imageFile.readAsBytes();

        updateProgress('Memperkecil ukuran gambar...');
        Uint8List resizedImage;
        try {
          resizedImage = await resizeImageIfNeeded(imageBytes,
              maxWidth: 720, maxHeight: 1280);
        } catch (e) {
          debugPrint("⚠️ Gagal memperkecil gambar: $e");
          resizedImage = imageBytes;
        }

        // Step 1: Kompresi dengan flutter_image_compress dan konversi ke grayscale
        updateProgress('Memproses gambar...');
        final grayscaleResult = await processImageToGrayscale(resizedImage);
        final pixels = grayscaleResult['pixels'] as List<int>;
        final width = grayscaleResult['width'] as int;
        final height = grayscaleResult['height'] as int;

        // Step 2: Kompresi Huffman
        updateProgress('Mengompresi dengan Huffman...');
        final encoder = HuffmanEncoder();
        final compressionResult = encoder.encode(pixels, width, height);

        // Step 3: Kirim ke server
        updateProgress('Mengirim ke server...');
        int retryCount = 0;
        int maxRetries = 3;
        int? kompresiId;

        while (retryCount < maxRetries && kompresiId == null) {
          try {
            retryCount++;
            updateProgress(
                'Mengirim ke server (percobaan ${retryCount}/${maxRetries})...');
            kompresiId = await kirimKompresiKeDjango(
                widget.idPegawai, compressionResult);

            if (kompresiId == null && retryCount < maxRetries) {
              debugPrint("🔄 Coba kirim lagi (${retryCount}/${maxRetries})");
              await Future.delayed(Duration(seconds: 1 * retryCount));
            }
          } catch (e) {
            debugPrint("⚠️ Error saat pengiriman #${retryCount}: $e");
            if (retryCount >= maxRetries) rethrow;
            await Future.delayed(Duration(seconds: 1 * retryCount));
          }
        }

        if (kompresiId == null) {
          throw Exception(
              'Gagal mengirim data setelah ${maxRetries}x percobaan');
        }

        // Tunggu sebentar untuk memastikan data tersimpan di server
        await Future.delayed(Duration(milliseconds: 300));

        hideProgressDialog();

        if (!mounted) return;

        // Navigate ke CheckOutPage
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckOutPage(
              kompresiId: kompresiId,
              idPegawai: widget.idPegawai,
              imagePath: image.path,
              imageData: imageBytes, // Kirim gambar asli untuk ditampilkan
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
        if (mounted) {
          _startFaceDetectionWithDelay();
        }
      } catch (e, stackTrace) {
        hideProgressDialog();

        setState(() {
          _isProcessing = false;
        });

        print("ERROR: $e");
        print("Stack Trace: $stackTrace");

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Gagal memproses gambar: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) {
          _startFaceDetectionWithDelay();
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Out', style: TextStyle(color: Colors.white)),
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
    _faceDetectionTimer?.cancel();
    _faceDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }
}

// Face overlay painter for visual guidance
class FaceOverlayPainter extends CustomPainter {
  final bool isFaceDetected;

  FaceOverlayPainter({required this.isFaceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = isFaceDetected
          ? Colors.green.withOpacity(0.3)
          : Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw oval for face positioning guide
    final double ovalWidth = size.width * 0.65;
    final double ovalHeight = size.height * 0.4;

    final Rect ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.4),
      width: ovalWidth,
      height: ovalHeight,
    );

    canvas.drawOval(ovalRect, paint);

    // Draw dashed lines inside if face is not detected
    if (!isFaceDetected) {
      final Paint dashPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      const double dashWidth = 10.0;
      const double dashSpace = 5.0;

      // Vertical line
      double startY = ovalRect.top + 10;
      final double endY = ovalRect.bottom - 10;
      final double x = ovalRect.center.dx;

      while (startY < endY) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + dashWidth),
          dashPaint,
        );
        startY += dashWidth + dashSpace;
      }

      // Horizontal line
      double startX = ovalRect.left + 10;
      final double endX = ovalRect.right - 10;
      final double y = ovalRect.center.dy;

      while (startX < endX) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.isFaceDetected != isFaceDetected;
  }
}



// import 'dart:io';
// import 'package:image/image.dart' as img;
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'dart:typed_data';
// import 'package:absensi/pages/checkout.dart'; // Halaman tujuan setelah foto
// import 'package:http_parser/http_parser.dart'; // untuk MediaType
// import 'dart:collection'; // untuk PriorityQueue
// import 'package:collection/collection.dart';
// import 'dart:async';
// import 'package:flutter_image_compress/flutter_image_compress.dart';

// const String baseUrl = "http://192.168.1.58:8000";
// // Kelas Node untuk membuat pohon Huffman
// class HuffmanNode implements Comparable<HuffmanNode> {
//   int? value; // Nilai pixel (0-255) atau null untuk node internal
//   int frequency; // Frekuensi kemunculan
//   HuffmanNode? left;
//   HuffmanNode? right;

//   HuffmanNode({this.value, required this.frequency, this.left, this.right});

//   // Fungsi untuk membandingkan node (untuk priority queue)
//   @override
//   int compareTo(HuffmanNode other) {
//     return frequency - other.frequency;
//   }
// }

// Map<int, int> countFrequencies(List<int> pixels) {
//   final freq = <int, int>{};
//   for (final pixel in pixels) {
//     freq[pixel] = (freq[pixel] ?? 0) + 1;
//   }
//   return freq;
// }

// class HuffmanEncoder {
//   // Fungsi untuk mengompresi data menggunakan Huffman coding
//   Map<String, dynamic> encode(List<int> pixels, int width, int height) {
//     debugPrint("▶️ Mulai kompresi Huffman. Jumlah pixel: ${pixels.length}");

//     // Tambahkan pengukuran waktu
//     final Stopwatch stopwatch = Stopwatch()..start();

//     // Hitung frekuensi kemunculan setiap nilai pixel
//     Map<int, int> frequencies = countFrequencies(pixels);
//     debugPrint("📊 Jumlah nilai unik: ${frequencies.length}");

//     // Buat pohon Huffman
//     HuffmanNode? root = _buildHuffmanTree(frequencies);

//     // Buat tabel kode Huffman
//     Map<int, List<int>> codeTable = {};
//     _buildCodeTable(root!, [], codeTable);

//     debugPrint("📝 Tabel kode berhasil dibuat. Jumlah entry: ${codeTable.length}");

//     // Enkode data menggunakan tabel kode
//     List<int> encodedBits = [];
//     for (int pixel in pixels) {
//       encodedBits.addAll(codeTable[pixel]!);
//     }

//     // Konversi bitstream ke bytestream
//     List<int> compressedData = _bitsToBytes(encodedBits);

//     // Hitung ukuran sebelum dan sesudah kompresi (dalam byte)
//     int originalSize = pixels.length;
//     int compressedSize = compressedData.length;

//     // Hitung compression ratio
//     double compressionRatio = originalSize / compressedSize;

//     // Hitung waktu kompresi
//     stopwatch.stop();
//     int compressionTimeMillis = stopwatch.elapsedMilliseconds;

//     // Konversi tabel kode untuk disimpan (key string, value array bits)
//     Map<String, List<int>> serializedCodeTable = {};
//     codeTable.forEach((key, value) {
//       serializedCodeTable[key.toString()] = value;
//     });

//     // Return hasil kompresi dan informasi yang diperlukan
//     return {
//       'compressedData': compressedData,
//       'codeTable': serializedCodeTable,
//       'frequencies': frequencies,
//       'width': width,
//       'height': height,
//       'originalLength': pixels.length,
//       'originalSize': originalSize,
//       'compressedSize': compressedSize,
//       'compressionRatio': compressionRatio,
//       'compressionTimeMillis': compressionTimeMillis,
//     };
//   }

//   // Fungsi untuk membuat pohon Huffman dari tabel frekuensi
//   HuffmanNode? _buildHuffmanTree(Map<int, int> frequencies) {
//     // Gunakan List sebagai Priority Queue sederhana
//     List<HuffmanNode> nodes = [];

//     // Tambahkan semua nilai ke nodes sebagai leaf node
//     frequencies.forEach((value, frequency) {
//       nodes.add(HuffmanNode(value: value, frequency: frequency));
//     });

//     // Proses nodes sampai hanya tersisa satu node (root)
//     while (nodes.length > 1) {
//       // Urutkan berdasarkan frekuensi
//       nodes.sort((a, b) => a.frequency.compareTo(b.frequency));

//       // Ambil dua node dengan frekuensi terendah
//       HuffmanNode left = nodes.removeAt(0);
//       HuffmanNode right = nodes.removeAt(0);

//       // Buat node baru dengan children dari dua node tadi
//       HuffmanNode parent = HuffmanNode(
//         value: null, // Node internal tidak punya nilai
//         frequency: left.frequency + right.frequency,
//         left: left,
//         right: right,
//       );

//       // Tambahkan node baru ke nodes
//       nodes.add(parent);
//     }

//     // Return root dari pohon Huffman
//     return nodes.isEmpty ? null : nodes[0];
//   }

//   // Fungsi rekursif untuk membuat tabel kode dari pohon Huffman
//   void _buildCodeTable(
//       HuffmanNode node, List<int> currentCode, Map<int, List<int>> codeTable) {
//     // Jika node adalah leaf (memiliki nilai), tambahkan ke tabel kode
//     if (node.value != null) {
//       codeTable[node.value!] = List<int>.from(currentCode);
//       return;
//     }

//     // Traverse left (tambahkan 0)
//     if (node.left != null) {
//       currentCode.add(0);
//       _buildCodeTable(node.left!, currentCode, codeTable);
//       currentCode.removeLast();
//     }

//     // Traverse right (tambahkan 1)
//     if (node.right != null) {
//       currentCode.add(1);
//       _buildCodeTable(node.right!, currentCode, codeTable);
//       currentCode.removeLast();
//     }
//   }

//   // Konversi bitstream ke bytestream
//   List<int> _bitsToBytes(List<int> bits) {
//     List<int> bytes = [];
//     int currentByte = 0;
//     int bitPos = 7;

//     for (int bit in bits) {
//       if (bit == 1) {
//         currentByte |= (1 << bitPos);
//       }

//       bitPos--;
//       if (bitPos < 0) {
//         bytes.add(currentByte);
//         currentByte = 0;
//         bitPos = 7;
//       }
//     }

//     // Tambahkan byte terakhir jika ada bit yang belum diproses
//     if (bitPos != 7) {
//       bytes.add(currentByte);
//     }

//     // Hitung jumlah padding bit
//     int paddingBits = (bitPos + 1) % 8;
    
//     // Tambahkan jumlah padding bit sebagai byte terakhir
//     bytes.add(paddingBits);

//     return bytes;
//   }
// }

// // Fungsi untuk memproses gambar menjadi array grayscale
// Map<String, dynamic> processOriginalImage(Uint8List imageBytes) {
//   final image = img.decodeImage(imageBytes);
//   if (image == null) {
//     throw Exception('Gagal mendekode gambar');
//   }

//   final grayscale = img.grayscale(image);
  
//   // Dapatkan semua piksel dalam format grayscale
//   final pixels = List<int>.from(grayscale.getBytes(format: img.Format.luminance));

//   // Pastikan jumlah piksel sesuai dengan dimensi
//   if (pixels.length != grayscale.width * grayscale.height) {
//     debugPrint("⚠️ Peringatan: Jumlah piksel (${pixels.length}) tidak sesuai dengan dimensi (${grayscale.width}x${grayscale.height} = ${grayscale.width * grayscale.height})");

//     // Sesuaikan piksel
//     if (pixels.length < grayscale.width * grayscale.height) {
//       // Tambahkan piksel hitam (0)
//       pixels.addAll(List<int>.filled(grayscale.width * grayscale.height - pixels.length, 0));
//     } else {
//       // Potong kelebihan piksel
//       return {
//         'pixels': pixels.sublist(0, grayscale.width * grayscale.height),
//         'width': grayscale.width,
//         'height': grayscale.height,
//       };
//     }
//   }

//   return {
//     'pixels': pixels,
//     'width': grayscale.width, 
//     'height': grayscale.height,
//   };
// }

// // Fungsi untuk mengirim data kompresi ke server Django
// Future<dynamic> kirimKompresiKeDjango(
//     String idPegawai, Map<String, dynamic> compressionResult) async {
//   final uri = Uri.parse('http://192.168.1.58:8000/sipreti/kompresi/');

//   // Konversi frequencies ke format string key untuk pengiriman
//   final frequencyModelStrKey =
//       (compressionResult['frequencies'] as Map<int, int>)
//           .map((key, value) => MapEntry(key.toString(), value));

//   // Konversi codeTable ke JSON (sudah dalam format string key)
//   final codeTableJson = jsonEncode(compressionResult['codeTable']);

//   try {
//     final request = http.MultipartRequest('POST', uri)
//       ..fields['id_pegawai'] = idPegawai
//       ..fields['width'] = compressionResult['width'].toString()
//       ..fields['height'] = compressionResult['height'].toString()
//       ..fields['frequency_model'] = jsonEncode(frequencyModelStrKey)
//       ..fields['code_table'] = codeTableJson
//       ..fields['compression_type'] = 'huffman'
//       ..fields['original_length'] = compressionResult['originalLength'].toString()
//       ..fields['original_size'] = compressionResult['originalSize'].toString()
//       ..fields['compressed_size'] = compressionResult['compressedSize'].toString()
//       ..fields['compression_ratio'] = compressionResult['compressionRatio'].toString()
//       ..fields['compression_time_ms'] = compressionResult['compressionTimeMillis'].toString()
//       // Mengirim data kompresi sebagai file dalam bentuk byte
//       ..files.add(
//         http.MultipartFile.fromBytes(
//           'compressed_file',
//           compressionResult['compressedData'],
//           filename: 'compressed.bin',
//         ),
//       );

//     final streamedResponse = await request.send();
//     final response = await http.Response.fromStream(streamedResponse);

//     if (response.statusCode == 200) {
//       debugPrint('✅ Bitstream berhasil dikirim');
//       final responseData = jsonDecode(response.body);
//       return responseData['kompresi_id'];
//     } else {
//       debugPrint('❌ Gagal kirim bitstream: ${response.statusCode} - ${response.body}');
//       return null;
//     }
//   } catch (e) {
//     debugPrint('❌ Exception saat mengirim data: $e');
//     return null;
//   }
// }

// class KameraPage2 extends StatefulWidget {
//   final String idPegawai;
//   final int jenis;
//   final String lokasi;
//   final int checkMode;
//   final String nama;
//   final String nip;
//   final String idUnitKerja;
//   final String latitude;
//   final String longitude;
//   final int? kompresiId;

//   const KameraPage2({
//     super.key,
//     required this.idPegawai,
//     required this.jenis,
//     required this.lokasi,
//     required this.checkMode,
//     required this.nama,
//     required this.nip,
//     required this.idUnitKerja,
//     required this.latitude,
//     required this.longitude,
//     this.kompresiId,
//   });

//   @override
//   KameraPageState createState() => KameraPageState();
// }

// class KameraPageState extends State<KameraPage2> {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isCameraInitialized = false;
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   Future<void> _initializeCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras != null && _cameras!.isNotEmpty) {
//         _cameraController = CameraController(
//           _cameras![1],
//           ResolutionPreset.high,
//         );

//         await _cameraController!.initialize();
//         if (!mounted) return;
//         setState(() {
//           _isCameraInitialized = true;
//         });
//       } else {
//         debugPrint("Tidak ada kamera tersedia.");
//       }
//     } catch (e) {
//       debugPrint("Gagal inisialisasi kamera: $e");
//     }
//   }

//   Future<void> _captureImage() async {
//     if (_cameraController != null && _cameraController!.value.isInitialized) {
//       if (_isProcessing) return; // Prevent multiple captures

//       setState(() {
//         _isProcessing = true;
//       });

//       try {
//         showProcessingIndicator();

//         final image = await _cameraController!.takePicture();
//         final imageFile = File(image.path);
//         final imageBytes = await imageFile.readAsBytes();

//         final resizedImage =
//             _resizeImageIfNeeded(imageBytes, maxWidth: 720, maxHeight: 1280);

//         final result = processOriginalImage(resizedImage);
//         final originalPixels = result['pixels'] as List<int>;
//         final width = result['width'] as int;
//         final height = result['height'] as int;

//         // Gunakan HuffmanEncoder
//         final encoder = HuffmanEncoder();
//         final compressionResult = encoder.encode(originalPixels, width, height);
// // Kirim ke Django dengan retry
//         int retryCount = 0;
//         int maxRetries = 3;
//         int? kompresiId;

//         while (retryCount < maxRetries && kompresiId == null) {
//           try {
//             retryCount++;
//             kompresiId = await kirimKompresiKeDjango(
//                 widget.idPegawai, compressionResult);

//             if (kompresiId == null && retryCount < maxRetries) {
//               debugPrint("🔄 Coba kirim lagi (${retryCount}/${maxRetries})");
//               await Future.delayed(
//                   Duration(seconds: 2 * retryCount)); // Exponential backoff
//             }
//           } catch (e) {
//             debugPrint("⚠️ Error saat pengiriman #${retryCount}: $e");
//             if (retryCount >= maxRetries) rethrow;
//             await Future.delayed(Duration(seconds: 2 * retryCount));
//           }
//         }

//         if (kompresiId == null) {
//           throw Exception(
//               'Gagal mengirim data setelah ${maxRetries}x percobaan');
//         }

//         // Tunggu sebentar untuk memastikan data tersimpan di server
//         await Future.delayed(Duration(milliseconds: 500));

//         if (!mounted) return;

//         // Navigate ke CheckOutPage
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CheckOutPage(
//               kompresiId: kompresiId,
//               idPegawai: widget.idPegawai,
//               imagePath: image.path,
//               imageData: imageBytes,
//               jenis: widget.jenis,
//               lokasi: widget.lokasi,
//               checkMode: widget.checkMode,
//               nama: widget.nama,
//               nip: widget.nip,
//               idUnitKerja: widget.idUnitKerja,
//               latitude: widget.latitude,
//               longitude: widget.longitude,
//             ),
//           ),
//         );
//       } catch (e, stackTrace) {
//         setState(() {
//           _isProcessing = false;
//         });

//         print("ERROR: $e");
//         print("Stack Trace: $stackTrace");

//         if (!mounted) return;

//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Error'),
//             content: Text('Failed to process image: $e'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isProcessing = false;
//           });
//         }
//       }
//     }
//   }

// // Fungsi untuk memperkecil gambar jika terlalu besar
//   Uint8List _resizeImageIfNeeded(Uint8List imageBytes,
//       {required int maxWidth, required int maxHeight}) {
//     final image = img.decodeImage(imageBytes);
//     if (image == null) {
//       throw Exception('Gagal mendekode gambar');
//     }

//     // Jika gambar sudah cukup kecil, kembalikan apa adanya
//     if (image.width <= maxWidth && image.height <= maxHeight) {
//       return imageBytes;
//     }

//     // Hitung rasio untuk menjaga aspek ratio
//     double widthRatio = maxWidth / image.width;
//     double heightRatio = maxHeight / image.height;
//     double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

//     // Hitung dimensi baru
//     int newWidth = (image.width * ratio).round();
//     int newHeight = (image.height * ratio).round();

//     // Resize gambar
//     final resized = img.copyResize(image,
//         width: newWidth,
//         height: newHeight,
//         interpolation: img.Interpolation.average);

//     // Konversi kembali ke bytes
//     return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
//   }

//   void showProcessingIndicator() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async => false,
//           child: Dialog(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             child: Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.black87,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(
//                     width: 70,
//                     height: 70,
//                     child: CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       strokeWidth: 5,
//                     ),
//                   ),
//                   SizedBox(height: 24),
//                   Text(
//                     'Memproses...',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Mohon tunggu sebentar',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Check Out', style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color.fromARGB(255, 33, 137, 235),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       backgroundColor: const Color(0xFF2A363B),
//       body: Stack(
//         children: [
//           if (_cameraController != null &&
//               _cameraController!.value.isInitialized)
//             Positioned.fill(
//               child: RotatedBox(
//                 quarterTurns: 1,
//                 child: Transform(
//                   alignment: Alignment.center,
//                   transform: Matrix4.rotationY(3.14),
//                   child: CameraPreview(_cameraController!),
//                 ),
//               ),
//             )
//           else
//             const Center(child: CircularProgressIndicator()),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 55.0),
//               child: SizedBox(
//                 width: 80,
//                 height: 80,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     shape: const CircleBorder(),
//                     elevation: 10,
//                   ),
//                   onPressed: _isProcessing ? null : _captureImage,
//                   child: const Icon(
//                     Icons.camera_alt,
//                     color: Colors.black,
//                     size: 36,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }
// }