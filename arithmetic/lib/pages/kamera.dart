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

// const String baseUrl = "http://192.168.1.37:8000";

// Map<String, dynamic> convertToGrayscale(Uint8List imageBytes) {
//   final image = img.decodeImage(imageBytes)!;
//   final grayscale = img.grayscale(image);
//   return {
//     'pixels': grayscale.getBytes(format: img.Format.luminance),
//     'width': grayscale.width,
//     'height': grayscale.height,
//   };
// }

// Map<int, int> countFrequencies(List<int> pixels) {
//   final freq = <int, int>{};
//   for (final pixel in pixels) {
//     freq[pixel] = (freq[pixel] ?? 0) + 1;
//   }
//   return freq;
// }

// class ArithmeticEncoder {
//   static const int CODE_VALUE_BITS = 32;
//   static const int TOP_VALUE = (1 << CODE_VALUE_BITS) - 1;
//   static const int FIRST_QTR = TOP_VALUE ~/ 4 + 1;
//   static const int HALF = 2 * FIRST_QTR;
//   static const int THIRD_QTR = 3 * FIRST_QTR;

//   // Fungsi untuk mengompresi data menggunakan arithmetic coding
//   Map<String, dynamic> encode(List<int> pixels, int width, int height) {
//     debugPrint("▶️ Mulai kompresi. Jumlah pixel: ${pixels.length}");
//     // Buat model frekuensi dari pixel
//     Map<int, int> frequencies = _buildFrequencyModel(pixels);
//     int totalFrequency = _calculateTotalFrequency(frequencies);

//     debugPrint("📊 Total frekuensi: $totalFrequency");
//     debugPrint(
//         "📉 Contoh model frekuensi: ${frequencies.entries.take(10).toList()}");

//     int low = 0;
//     int high = TOP_VALUE;
//     int bitsToFollow = 0;
//     List<int> outputBits = [];

//     // Fungsi untuk menambahkan bit dan bit tambahan yang mengikuti
//     void bitPlusFollow(int bit) {
//       outputBits.add(bit);
//       while (bitsToFollow > 0) {
//         outputBits.add(bit == 1 ? 0 : 1);
//         bitsToFollow--;
//       }
//     }

//     // Mulai proses encoding
//     for (int pixel in pixels) {
//       int range = high - low + 1;

//       // Hitung batas bawah kumulatif untuk simbol
//       int cumLow = 0;
//       for (int i = 0; i < pixel; i++) {
//         cumLow += frequencies[i] ?? 0;
//       }

//       // Hitung batas atas kumulatif
//       int cumHigh = cumLow + (frequencies[pixel] ?? 0);

//       // Update interval
//       high = low + ((range * cumHigh) ~/ totalFrequency) - 1;
//       low = low + ((range * cumLow) ~/ totalFrequency);

//       // E1, E2, E3 scaling untuk mencegah underflow
//       while (true) {
//         if (high < HALF) {
//           // E1: Kedua nilai di bawah setengah, output 0 dan scale up
//           bitPlusFollow(0);
//         } else if (low >= HALF) {
//           // E2: Kedua nilai di atas setengah, output 1 dan scale up, shift down
//           bitPlusFollow(1);
//           low -= HALF;
//           high -= HALF;
//         } else if (low >= FIRST_QTR && high < THIRD_QTR) {
//           // E3: Interval menuju ke tengah, expand tengah
//           bitsToFollow++;
//           low -= FIRST_QTR;
//           high -= FIRST_QTR;
//         } else {
//           // Tidak ada scaling yang bisa dilakukan
//           break;
//         }

//         // Scale up interval
//         low = low * 2;
//         high = high * 2 + 1;
//       }
//     }

//     // Flush encoding - output cukup bit untuk disambiguasi
//     bitsToFollow++;
//     if (low < FIRST_QTR) {
//       bitPlusFollow(0);
//     } else {
//       bitPlusFollow(1);
//     }

//     // Konversi bitstream ke bytestream untuk pengiriman lebih efisien
//     List<int> byteStream = _bitsToBytes(outputBits);
//     // Tambahkan float64 dummy sebagai encoded_value di awal stream

//     // Ambil nilai tengah dari low dan high sebagai encoded value
//     double encodedValue = (low + high) / 2 / TOP_VALUE; // hasil normalisasi

//     // Ubah encodedValue menjadi 8-byte Float64
//     final encodedBytes = ByteData(8)..setFloat64(0, encodedValue, Endian.big);
//     final encodedValueBytes = encodedBytes.buffer.asUint8List();

//     // Gabungkan float64 + bitstream jadi satu array final
//     List<int> fullByteStream = List<int>.from(encodedValueBytes)
//       ..addAll(byteStream);

//     debugPrint(
//         "✅ Kompresi selesai. Jumlah byte hasil kompresi (total+float): ${fullByteStream.length}");

//     // Return hasil kompresi dan model frekuensi
//     return {
//       'encodedValue': encodedValue,
//       'compressedData': fullByteStream, // ✅ penting: hasil bitstream dikirim
//       'frequencyModel': frequencies,
//       'width': width,
//       'height': height,
//       'originalLength': pixels.length,
//     };
//   }

//   // Buat model frekuensi dari pixel
//   Map<int, int> _buildFrequencyModel(List<int> pixels) {
//     Map<int, int> frequencies = {};

//     // Inisialisasi semua kemungkinan nilai (0-255) dengan frekuensi 1
//     // ini untuk menghindari frekuensi 0 yang menyebabkan masalah
//     for (int i = 0; i < 256; i++) {
//       frequencies[i] = 1;
//     }

//     // Hitung frekuensi sebenarnya
//     for (int pixel in pixels) {
//       frequencies[pixel] = (frequencies[pixel] ?? 0) + 1;
//     }

//     return frequencies;
//   }

//   // Hitung total frekuensi dari model
//   int _calculateTotalFrequency(Map<int, int> frequencies) {
//     int total = 0;
//     frequencies.forEach((key, value) {
//       total += value;
//     });
//     return total;
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

//     // Tambahkan byte terakhir jika ada
//     if (bitPos != 7) {
//       bytes.add(currentByte);
//     }

//     return bytes;
//   }
// }

// Future<void> kirimKompresiKeDjango(
//     String idPegawai, Map<String, dynamic> compressionResult) async {
//   final uri = Uri.parse('$baseUrl/sipreti/kompresi/');

//   final frequencyModelStrKey =
//       (compressionResult['frequencyModel'] as Map<int, int>)
//           .map((key, value) => MapEntry(key.toString(), value));

//   final request = http.MultipartRequest('POST', uri)
//     ..fields['id_pegawai'] = idPegawai
//     ..fields['width'] = compressionResult['width'].toString()
//     ..fields['height'] = compressionResult['height'].toString()
//     ..fields['frequency_model'] = jsonEncode(frequencyModelStrKey)
//     ..fields['original_length'] = compressionResult['originalLength'].toString()
//     ..fields['encoded_value'] = compressionResult['encodedValue'].toString()
//     // Mengirim data kompresi sebagai file dalam bentuk byte
//     ..files.add(
//       http.MultipartFile.fromBytes(
//         'compressed_file',
//         compressionResult['compressedData'],
//         filename: 'compressed.bin',
//         contentType: MediaType('application', 'octet-stream'),
//       ),
//     );

//   final streamedResponse = await request.send();
//   final response = await http.Response.fromStream(streamedResponse);
//   debugPrint("📤 Mengirim ke Django: ${uri.toString()}");
//   debugPrint("📝 ID Pegawai: $idPegawai");
//   debugPrint(
//       "🧠 Panjang bitstream: ${(compressionResult['compressedData'] as List).length}");
//   debugPrint(
//       "📦 Contoh isi data: ${(compressionResult['compressedData'] as List).take(10).toList()}");

//   final encodedData = compressionResult['compressedData'];
//   if (encodedData == null || encodedData.isEmpty) {
//     debugPrint("❌ Data kompresi kosong! Tidak akan dikirim.");
//     return;
//   }

//   if (response.statusCode == 200) {
//     debugPrint('✅ Bitstream berhasil dikirim');
//   } else {
//     debugPrint(
//         '❌ Gagal kirim bitstream: ${response.statusCode} - ${response.body}');
//   }
// }

// class KameraPage extends StatefulWidget {
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

//   const KameraPage({
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

// class KameraPageState extends State<KameraPage> {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isCameraInitialized = false;

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
//       try {
//         final image = await _cameraController!.takePicture();
//         final imageFile = File(image.path);
//         final imageBytes = await imageFile.readAsBytes();

//         final result = convertToGrayscale(imageBytes);
//         final grayscalePixels = result['pixels'] as List<int>;
//         final width = result['width'] as int;
//         final height = result['height'] as int;

//         final encoder = ArithmeticEncoder();
//         final compressionResult =
//             encoder.encode(grayscalePixels, width, height);

//         compressionResult['width'] = width;
//         compressionResult['height'] = height;

//         // Pastikan 'originalLength' ada dan bukan null
//         if (compressionResult['originalLength'] == null) {
//           compressionResult['originalLength'] = grayscalePixels.length;
//         }

// // Kirim ke Django
//         await kirimKompresiKeDjango(widget.idPegawai, compressionResult);

//         // Misalnya lanjut ke halaman CheckOut langsung
//         if (!mounted) return;
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CheckOutPage(
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
//               kompresiId: kompresiId,
//               // Tambahkan `encodedData` jika perlu ditampilkan atau dipakai
//             ),
//           ),
//         );
//       } catch (e) {
//         debugPrint("Gagal ambil atau kompres gambar: $e");
//       }
//     }
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
//                     backgroundColor:
//                         Colors.white, // Warna putih seperti tombol kamera
//                     shape: const CircleBorder(),
//                     elevation: 10,
//                   ),
//                   onPressed: _captureImage,
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
