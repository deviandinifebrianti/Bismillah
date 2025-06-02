// Flutter Mobile - RGB Arithmetic Encode to Django
// EXACT SAME ALGORITHM sebagai Django tanpa perubahan apapun
// Simplified UI dengan RGB default mode

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// EXACT SAME CLASS dari Django - TrueArithmeticCoder
class TrueArithmeticCoder {
  /// RLE - mempertahankan urutan dengan run lengths
  /// EXACT SAME sebagai Django
  static List<List<int>> runLengthEncode(List<int> data) {
    if (data.isEmpty) return [];

    List<List<int>> encoded = [];
    int currentValue = data[0];
    int count = 1;

    for (int i = 1; i < data.length; i++) {
      if (data[i] == currentValue) {
        count++;
      } else {
        encoded.add([currentValue, count]);
        currentValue = data[i];
        count = 1;
      }
    }

    encoded.add([currentValue, count]);
    return encoded;
  }

  /// Simple Arithmetic: Probabilitas berdasarkan frekuensi + RLE
  /// EXACT SAME sebagai Django
  static Map<String, dynamic> simpleArithmeticEncode(
      List<int> data, Function(String) log) {
    if (data.isEmpty) {
      return {
        'method': 'simple_arithmetic',
        'runs': <List<int>>[],
        'frequency_table': <String, int>{},
        'original_length': 0
      };
    }

    log('🔄 Simple Arithmetic encoding ${data.length} symbols...');

    // Step 1: RLE untuk mempertahankan urutan
    Stopwatch stopwatch = Stopwatch()..start();
    List<List<int>> runs = runLengthEncode(data);
    stopwatch.stop();
    double rleTime = stopwatch.elapsedMilliseconds / 1000.0;

    log('   📦 RLE: ${data.length} -> ${runs.length} runs (${rleTime.toStringAsFixed(3)}s)');

    // Step 2: Frequency analysis untuk metadata
    stopwatch.reset();
    stopwatch.start();
    Map<int, int> freq = <int, int>{};
    for (int value in data) {
      freq[value] = (freq[value] ?? 0) + 1;
    }
    stopwatch.stop();
    double freqTime = stopwatch.elapsedMilliseconds / 1000.0;

    log('   📊 Frequency: ${freq.length} unique values (${freqTime.toStringAsFixed(3)}s)');

    // Step 3: Create final encoded result
    // Convert Map<int, int> to Map<String, int> untuk JSON compatibility
    Map<String, int> frequencyTable = <String, int>{};
    freq.forEach((key, value) {
      frequencyTable[key.toString()] = value;
    });

    Map<String, dynamic> result = {
      'method': 'simple_arithmetic',
      'runs': runs, // [[value, count], [value, count], ...]
      'frequency_table': frequencyTable, // {value: total_count}
      'original_length': data.length,
      'unique_symbols': freq.length,
      'compression_ratio': (runs.length * 2) / data.length
    };

    log('   ✅ Compression ratio: ${result['compression_ratio'].toStringAsFixed(4)}');

    return result;
  }
}

// EXACT SAME CLASS dari Django - PureRLECoder
class PureRLECoder {
  /// Pure RLE encoding
  /// EXACT SAME sebagai Django
  static Map<String, dynamic> encode(List<int> data, Function(String) log) {
    if (data.isEmpty) {
      return {
        'method': 'pure_rle',
        'runs': <List<int>>[],
        'original_length': 0
      };
    }

    log('🔄 Pure RLE encoding ${data.length} symbols...');

    Stopwatch stopwatch = Stopwatch()..start();

    List<List<int>> encoded = [];
    int currentValue = data[0];
    int count = 1;

    for (int i = 1; i < data.length; i++) {
      if (data[i] == currentValue) {
        count++;
      } else {
        encoded.add([currentValue, count]);
        currentValue = data[i];
        count = 1;
      }
    }

    // Add last run
    encoded.add([currentValue, count]);

    stopwatch.stop();
    double encodeTime = stopwatch.elapsedMilliseconds / 1000.0;

    Map<String, dynamic> result = {
      'method': 'pure_rle',
      'runs': encoded,
      'original_length': data.length,
      'compression_ratio': (encoded.length * 2) / data.length
    };

    log('   📦 ${data.length} -> ${encoded.length} runs (${encodeTime.toStringAsFixed(3)}s)');
    log('   ✅ Compression ratio: ${result['compression_ratio'].toStringAsFixed(4)}');

    return result;
  }
}

// Mobile Image Processor - EXACT SAME logic sebagai Django
class MobileArithmeticEncoder {
  /// Extract pixels dari image - RGB Mode (Default)
  /// EXACT SAME processing sebagai Django
  static List<int> extractPixelsFromImage(img.Image image, Function(String) log,
      {bool useRGB = true}) {
    log('🔍 Extracting pixels from ${image.width}x${image.height} image...');
    log('🌈 Mode: RGB MURNI (3 channels only) - No Alpha');

    List<int> pixels = [];

    try {
      // Debug: Test format pixel dulu
      if (image.width > 0 && image.height > 0) {
        int testPixel = image.getPixelSafe(0, 0);
        log('🔍 Testing pixel format...');
        log('🔍 First pixel raw: 0x${testPixel.toRadixString(16).padLeft(8, '0')}');

        // Test ekstraksi RGB (SKIP Alpha)
        int test_r = (testPixel >> 16) & 0xFF;
        int test_g = (testPixel >> 8) & 0xFF;
        int test_b = testPixel & 0xFF;
        log('🔍 RGB extraction: R=$test_r, G=$test_g, B=$test_b');
      }

      // Ekstraksi RGB MURNI - SKIP Alpha channel
      log('🔄 Extracting RGB channels only...');

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          int pixel = image.getPixelSafe(x, y);

          // Ekstraksi RGB saja - SKIP Alpha
          // Format pixel biasanya: 0xAARRGGBB atau 0xRRGGBBAA
          // Kita ambil 3 byte terakhir untuk RGB
          int r = (pixel >> 16) & 0xFF; // Red channel
          int g = (pixel >> 8) & 0xFF; // Green channel
          int b = pixel & 0xFF; // Blue channel

          // Clamp ke range 0-255 (safety)
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          // Tambahkan HANYA RGB - TIDAK ada Alpha
          pixels.add(r);
          pixels.add(g);
          pixels.add(b);

          // Debug pixel pertama
          if (x == 0 && y == 0) {
            log('🔍 First pixel RGB: R=$r, G=$g, B=$b');
          }
        }
      }

      // Validasi: Pastikan jumlah pixel benar
      int expectedPixels = image.width * image.height * 3; // 3 channels RGB
      if (pixels.length != expectedPixels) {
        log('⚠️ Pixel count mismatch: got ${pixels.length}, expected $expectedPixels');
      }

      log('✅ RGB extraction completed: ${pixels.length} values');
      log('   📊 Pixels: ${image.width}x${image.height} = ${image.width * image.height} pixels');
      log('   📊 RGB values: ${pixels.length} (${pixels.length ~/ 3} pixels x 3 channels)');

      // Debug: Tampilkan sample nilai RGB
      if (pixels.length >= 9) {
        log('🔍 First 3 pixels RGB:');
        log('   Pixel 1: [${pixels[0]}, ${pixels[1]}, ${pixels[2]}]');
        log('   Pixel 2: [${pixels[3]}, ${pixels[4]}, ${pixels[5]}]');
        log('   Pixel 3: [${pixels[6]}, ${pixels[7]}, ${pixels[8]}]');

        // Check variasi warna
        Set<int> uniqueReds =
            Set.from(pixels.where((i) => pixels.indexOf(i) % 3 == 0).take(10));
        Set<int> uniqueGreens =
            Set.from(pixels.where((i) => pixels.indexOf(i) % 3 == 1).take(10));
        Set<int> uniqueBlues =
            Set.from(pixels.where((i) => pixels.indexOf(i) % 3 == 2).take(10));

        log('🔍 Color variation in first 10 pixels:');
        log('   Red values: ${uniqueReds.length} unique (${uniqueReds.toList()})');
        log('   Green values: ${uniqueGreens.length} unique (${uniqueGreens.toList()})');
        log('   Blue values: ${uniqueBlues.length} unique (${uniqueBlues.toList()})');

        // Warning jika ada channel yang dominan
        if (uniqueBlues.length > uniqueReds.length * 2) {
          log('⚠️ WARNING: Blue channel seems dominant - possible channel swap!');
          log('   Consider trying alternative extraction method');
        }
      }
    } catch (e) {
      log('❌ RGB extraction failed: $e');
      throw Exception('Cannot extract RGB pixels: $e');
    }

    return pixels;
  }

  /// Alternative method jika hasil masih biru/salah
  static List<int> extractPixelsAlternative(
      img.Image image, Function(String) log) {
    log('🔄 ALTERNATIVE RGB extraction - trying channel swap...');

    List<int> pixels = [];

    try {
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          int pixel = image.getPixelSafe(x, y);

          // COBA SWAP CHANNEL - jika format adalah ABGR
          int b = (pixel >> 16) & 0xFF; // Blue dari posisi Red
          int g = (pixel >> 8) & 0xFF; // Green tetap
          int r = pixel & 0xFF; // Red dari posisi Blue

          // Clamp values
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          // Tambahkan RGB (urutan tetap R,G,B)
          pixels.add(r);
          pixels.add(g);
          pixels.add(b);

          // Debug pixel pertama
          if (x == 0 && y == 0) {
            log('🔍 First pixel RGB (swapped): R=$r, G=$g, B=$b');
          }
        }
      }

      log('✅ Alternative RGB extraction completed: ${pixels.length} values');

      // Debug sample
      if (pixels.length >= 9) {
        log('🔍 Alternative first 3 pixels RGB:');
        log('   Pixel 1: [${pixels[0]}, ${pixels[1]}, ${pixels[2]}]');
        log('   Pixel 2: [${pixels[3]}, ${pixels[4]}, ${pixels[5]}]');
        log('   Pixel 3: [${pixels[6]}, ${pixels[7]}, ${pixels[8]}]');
      }
    } catch (e) {
      log('❌ Alternative RGB extraction failed: $e');
      throw Exception('Cannot extract RGB pixels with alternative method: $e');
    }

    return pixels;
  }

  /// EXACT SAME encode logic sebagai Django arithmetic_decode_image
  static Future<Map<String, dynamic>> encodeImageToDjango(
      File imageFile, String djangoUrl, Function(String) log,
      {Map<String, String>? additionalData}) async {
    try {
      log('🎯 RGB ARITHMETIC CODING - ENCODE');
      log('=' * 50);

      // Membaca file gambar dari file
      final fileBytes = await imageFile.readAsBytes();
      String fileName = imageFile.path.split('/').last;

      log('✅ File loaded: $fileName');
      log('📦 File size: ${fileBytes.length} bytes');

      // Decode gambar
      img.Image? image = img.decodeImage(fileBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      log('📏 Image size: ${image.width}x${image.height}');
      log('🌈 Color mode: RGB (3 channels)');
      log('🔢 Total pixels: ${image.width * image.height}');
      log('🔢 Total values: ${image.width * image.height * 3} (RGB)');

      // Auto resize jika terlalu besar
      if (image.width * image.height > 10000) {
        // Lebih kecil untuk RGB karena 3x data
        log('⚡ Resizing for RGB performance...');
        double scale = sqrt(10000 / (image.width * image.height));
        int newWidth = (image.width * scale).round();
        int newHeight = (image.height * scale).round();
        image = img.copyResize(image, width: newWidth, height: newHeight);
        log('✅ New size: ${image.width}x${image.height}');
      }

      // Flatten image ke RGB values
      List<int> flatImg = extractPixelsFromImage(image, log, useRGB: true);

      // Pilih method (default True Arithmetic)
      String method = 'simple_arithmetic';

      Map<String, dynamic> encodedResult;

      if (method == 'pure_rle') {
        log('📊 Using Pure RLE Coder...');
        encodedResult = PureRLECoder.encode(flatImg, log);
      } else {
        log('📊 Using True Arithmetic Coder...');
        encodedResult =
            TrueArithmeticCoder.simpleArithmeticEncode(flatImg, log);
      }

      // Tambahkan metadata RGB
      encodedResult['image_shape'] = [
        image.height,
        image.width,
        3
      ]; // Height, Width, Channels
      encodedResult['color_mode'] = 'RGB';
      encodedResult['channels'] = 3;
      encodedResult['original_filename'] = fileName;

      // Kompresi dengan GZIP + Base64
      String jsonString = jsonEncode(encodedResult);
      List<int> jsonBytes = utf8.encode(jsonString);
      List<int> compressed = GZipEncoder().encode(jsonBytes)!;
      String compressedB64 = base64.encode(compressed);

      log('✅ RGB Encoding completed successfully!');
      log('📦 Original data: ${jsonBytes.length} bytes');
      log('📦 Compressed: ${compressed.length} bytes');
      log('📦 Base64: ${compressedB64.length} characters');

      // Send to Django
      Map<String, dynamic> djangoResponse = await _sendToDjangoEncode(
          compressedB64, djangoUrl, log,
          additionalData: additionalData);

      return {
        'success': true,
        'encoded_result': encodedResult,
        'compressed_data': compressedB64,
        'django_response': djangoResponse,
        'local_processing': {
          'method': encodedResult['method'],
          'compression_ratio': encodedResult['compression_ratio'],
          'original_length': encodedResult['original_length'],
          'unique_symbols': encodedResult['unique_symbols'] ?? 0,
          'runs_count': (encodedResult['runs'] as List).length,
          'color_mode': 'RGB',
          'channels': 3,
        }
      };
    } catch (e) {
      log('❌ Error in encode: $e');
      throw Exception('Error encoding image: $e');
    }
  }

  /// Send ke Django endpoint dengan JSON body
  static Future<Map<String, dynamic>> _sendToDjangoEncode(
      String compressedB64, String djangoUrl, Function(String) log,
      {Map<String, String>? additionalData}) async {
    try {
      log('📤 Sending RGB data to Django: $djangoUrl');

      // Siapkan JSON payload
      Map<String, dynamic> payload = {
        'compressed_data': compressedB64,
      };

      // Tambahkan data pegawai jika ada
      if (additionalData != null) {
        payload.addAll(additionalData);
        log('📤 Added additional data: ${additionalData.keys.join(', ')}');
      }

      // Create JSON request
      var request = http.Request('POST', Uri.parse(djangoUrl));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      request.body = jsonEncode(payload);

      log('📤 Sending RGB JSON request...');

      // Send request dengan timeout
      var streamedResponse =
          await request.send().timeout(Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      log('📥 Django response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result = jsonDecode(response.body);
          log('✅ Django RGB processing successful!');

          if (result['success'] == true) {
            log('   🌈 Django processed RGB data successfully');
            log('   📊 Django method: ${result['method'] ?? 'unknown'}');
            log('   💾 Django filename: ${result['filename'] ?? 'no filename'}');
          }

          return result;
        } catch (jsonError) {
          log('❌ Error parsing JSON response: $jsonError');
          throw Exception('Invalid JSON response from Django: $jsonError');
        }
      } else {
        log('❌ Django error: ${response.statusCode}');
        throw Exception(
            'Django returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('❌ Error sending RGB data to Django: $e');
      throw Exception('Error sending to Django: $e');
    }
  }
}

// Simplified Flutter UI Page
class ArithmeticEncoding extends StatefulWidget {
  final String idPegawai;
  final String latitude;
  final String longitude;
  final String nama;
  final String nip;
  final String idUnitKerja;
  final String lokasi;

  const ArithmeticEncoding({
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
  _ArithmeticEncodingState createState() => _ArithmeticEncodingState();
}

class _ArithmeticEncodingState extends State<ArithmeticEncoding> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;
  Map<String, dynamic>? _results;
  String? _errorMessage;
  List<String> _logMessages = [];

  // Django server URL
  final String _djangoUrl =
      'http://192.168.1.14:8000/sipreti/arithmetic_decode_image';

  void _addLog(String message) {
    setState(() {
      _logMessages.add(message);
    });
    print(message);
  }

  @override
  void initState() {
    super.initState();
    _addLog('🌈 RGB Arithmetic Encoding - Ready');
    _addLog('🎯 Default: RGB Color Mode (3 channels)');
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _results = null;
          _errorMessage = null;
        });
        _addLog('✅ Image selected: ${pickedFile.name}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _encodeAndSendToDjango() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Data pegawai untuk Django
      Map<String, String> additionalData = {
        'id_pegawai': widget.idPegawai,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'nama': widget.nama,
        'nip': widget.nip,
        'id_unit_kerja': widget.idUnitKerja,
        'lokasi': widget.lokasi,
      };

      Map<String, dynamic> results =
          await MobileArithmeticEncoder.encodeImageToDjango(
              _imageFile!, _djangoUrl, _addLog,
              additionalData: additionalData);

      setState(() {
        _results = results;
      });

      _addLog('\n🎉 RGB PROCESS COMPLETED!');
    } catch (e) {
      _addLog('❌ Process failed: $e');
      setState(() {
        _errorMessage = 'Process failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🌈 RGB Arithmetic Encoder'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                children: [
                  Text('🌈 RGB Color Mode Active',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('Mengirim gambar berwarna (Red + Green + Blue channels)',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Image selection
            if (_imageFile == null) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text('Pilih Gambar untuk Diproses',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey[600])),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo_library),
                      label: Text('Pilih Gambar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Selected image display
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_imageFile!, fit: BoxFit.contain),
                ),
              ),

              SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.refresh),
                      label: Text('Ganti Gambar'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _encodeAndSendToDjango,
                      icon: _isProcessing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.send),
                      label:
                          Text(_isProcessing ? 'Processing...' : 'Proses RGB'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Results or logs
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(_errorMessage!,
                                      style:
                                          TextStyle(color: Colors.red[700]))),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                      if (_results != null) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('✅ RGB Processing Berhasil!',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800])),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (_results!['django_response'] != null) ...[
                                Text(
                                    'Django Response: ${_results!['django_response']['message'] ?? 'Success'}'),
                                if (_results!['django_response']['filename'] !=
                                    null)
                                  Text(
                                      'File: ${_results!['django_response']['filename']}'),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                      Text('📋 Log:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _logMessages
                                .map((log) => Padding(
                                      padding: EdgeInsets.only(bottom: 2),
                                      child: Text(log,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace')),
                                    ))
                                .toList(),
                          ),
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
    );
  }
}

// Main App
class MobileArithmeticApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RGB Arithmetic Encoding',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ArithmeticEncoding(
        // Contoh data untuk testing
        idPegawai: 'PEG001',
        latitude: '-7.966620',
        longitude: '112.632632',
        nama: 'John Doe',
        nip: '198501012010011001',
        idUnitKerja: 'UNIT001',
        lokasi: 'Jl. Veteran No. 1, Malang, Jawa Timur',
      ),
    );
  }
}

// Main function
void main() {
  runApp(MobileArithmeticApp());
}
