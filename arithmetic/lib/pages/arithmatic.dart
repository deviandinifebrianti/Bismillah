import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:absensi/pages/checkout.dart';
import 'package:geolocator/geolocator.dart';

class ArithmeticCoder {
  final int precision = 32;
  late final int maxVal;
  late final int quarter;
  late final int half;
  late final int threeQuarter;

  ArithmeticCoder() {
    maxVal = (1 << precision) - 1;
    quarter = 1 << (precision - 2);
    half = 2 * quarter;
    threeQuarter = 3 * quarter;
  }

  Map<int, int> buildFrequencyModel(List<int> data) {
    Map<int, int> counter = {};

    for (int value in data) {
      counter[value] = (counter[value] ?? 0) + 1;
    }

    for (int symbol = 0; symbol < 256; symbol++) {
      if (!counter.containsKey(symbol)) {
        counter[symbol] = 1;
      }
    }

    return counter;
  }

  Map<String, dynamic> buildCumulativeFreq(Map<int, int> freqModel) {
    List<int> symbols = freqModel.keys.toList()..sort();
    Map<int, int> cumulative = {};
    int total = 0;

    for (int symbol in symbols) {
      cumulative[symbol] = total;
      total += freqModel[symbol]!;
    }

    return {'cumulative': cumulative, 'total': total};
  }

  Map<String, dynamic> encode(List<int> data) {
    if (data.isEmpty) {
      return {'encoded_bytes': Uint8List(0), 'freq_model': <int, int>{}};
    }

    Map<int, int> freqModel = buildFrequencyModel(data);
    Map<String, dynamic> cumData = buildCumulativeFreq(freqModel);
    Map<int, int> cumulative = cumData['cumulative'];
    int totalFreq = cumData['total'];

    int low = 0;
    int high = maxVal;
    int pendingBits = 0;
    List<int> outputBits = [];

    for (int symbol in data) {
      int rangeSize = high - low + 1;
      int symbolFreq = freqModel[symbol]!;
      int symbolCum = cumulative[symbol]!;

      high = low + ((rangeSize * (symbolCum + symbolFreq)) ~/ totalFreq) - 1;
      low = low + ((rangeSize * symbolCum) ~/ totalFreq);

      while (true) {
        if (high < half) {
          outputBits.add(0);
          for (int i = 0; i < pendingBits; i++) {
            outputBits.add(1);
          }
          pendingBits = 0;
        } else if (low >= half) {
          outputBits.add(1);
          for (int i = 0; i < pendingBits; i++) {
            outputBits.add(0);
          }
          pendingBits = 0;
          low -= half;
          high -= half;
        } else if (low >= quarter && high < threeQuarter) {
          pendingBits += 1;
          low -= quarter;
          high -= quarter;
        } else {
          break;
        }

        low = (low << 1) & maxVal;
        high = ((high << 1) | 1) & maxVal;
      }
    }

    pendingBits += 1;
    if (low < quarter) {
      outputBits.add(0);
      for (int i = 0; i < pendingBits; i++) {
        outputBits.add(1);
      }
    } else {
      outputBits.add(1);
      for (int i = 0; i < pendingBits; i++) {
        outputBits.add(0);
      }
    }

    while (outputBits.length % 8 != 0) {
      outputBits.add(0);
    }

    List<int> outputBytes = [];
    for (int i = 0; i < outputBits.length; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        if (i + j < outputBits.length) {
          byte = (byte << 1) | outputBits[i + j];
        } else {
          byte = byte << 1;
        }
      }
      outputBytes.add(byte);
    }

    return {
      'encoded_bytes': Uint8List.fromList(outputBytes),
      'freq_model': freqModel,
    };
  }
}

class FlutterImageEncoder extends StatefulWidget {
  final String? idPegawai;
  final double? latitude;
  final double? longitude;
  final String? nama;
  final String? nip;
  final String? idUnitKerja;
  final String? lokasi;
  final int? jenis;
  final int? checkMode;

  const FlutterImageEncoder({
    Key? key,
    this.idPegawai,
    this.latitude,
    this.longitude,
    this.nama,
    this.nip,
    this.idUnitKerja,
    this.lokasi,
    this.jenis,
    this.checkMode,
  }) : super(key: key);

  @override
  _FlutterImageEncoderState createState() => _FlutterImageEncoderState();
}

class _FlutterImageEncoderState extends State<FlutterImageEncoder> {
  final ArithmeticCoder _coder = ArithmeticCoder();
  final String djangoUrl =
      'http://192.168.1.88:8000/sipreti/decode_image/'; // URL Django server
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isProcessing = false;
  Map<String, dynamic>? _result;

  String? _lastCapturedImagePath;
  Uint8List? _lastCapturedImageData;
  int? _kompresiId;
  String? _selectedCamera;
  Position? _currentPosition;
  String alamat = '';

  Duration? _captureTime;
  Duration? _arithmeticCompressionTime;
  Duration? _sendingTime;
  Duration? _totalTime;
  int? _originalSize;
  int? _compressedSize;
  int? _decodedSize;
  double? _euclideanDistance;
  double? _faceThreshold;
  String? _processingStats;
  Duration? _decompressionTime; // Waktu dekompresi dari server

  Widget _buildCheckoutSection() {
  // Cek apakah encoding berhasil
  bool encodingSuccess = _result != null && 
                        _result!['encoding'] != null && 
                        _result!['encoding']['status'] == 'success';
  
  // Cek apakah decoding berhasil (opsional, bisa juga hanya encoding)
  bool decodingSuccess = _result != null && 
                        _result!['decoding'] != null && 
                        _result!['decoding']['status'] == 'success';

  if (!encodingSuccess) {
    return SizedBox.shrink(); // Tidak tampilkan jika encoding gagal
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Divider(thickness: 1, color: Colors.grey.shade300),
      SizedBox(height: 12),
      
      // Header
      Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          SizedBox(width: 8),
          Text(
            'Ready for Checkout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
      
      SizedBox(height: 12),
      
      // Info summary
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Image successfully encoded',
              style: TextStyle(color: Colors.green.shade700),
            ),
            if (decodingSuccess)
              Text(
                '✅ Image successfully decoded on server',
                style: TextStyle(color: Colors.green.shade700),
              ),
            if (_originalSize != null && _compressedSize != null)
              Text(
                '📦 Compression: ${_formatBytes(_originalSize!)} → ${_formatBytes(_compressedSize!)}',
                style: TextStyle(color: Colors.green.shade700),
              ),
          ],
        ),
      ),
      
      SizedBox(height: 16),
      
      // Checkout Button
      ElevatedButton.icon(
        onPressed: _handleCheckout,
        icon: Icon(Icons.shopping_cart),
        label: Text(
          'Proceed to Checkout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      SizedBox(height: 8),
      
      // Info text
      Text(
        'Tap to continue with attendance checkout process',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
    ],
  );
}

  Widget _buildResultsContent() {
    if (_result == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ TAMBAHKAN: Statistics Card
        if (_captureTime != null ||
            _arithmeticCompressionTime != null ||
            _sendingTime != null) ...[
          _buildSectionHeader('📊 Processing Statistics', Colors.purple),
          SizedBox(height: 8),
          _buildStatisticsCard(),
          SizedBox(height: 16),
        ],
      ],
    );
  }
        

  // STEP 3: Complete workflow
  Future<Map<String, dynamic>> processImage(File imageFile) async {
    print('🚀 Starting image processing...');

    // Reset timing variables
    _captureTime = null;
    _arithmeticCompressionTime = null;
    _sendingTime = null;
    _totalTime = null;
    _decompressionTime = null; 
    _originalSize = null;
    _compressedSize = null;
    _decodedSize = null; 

    final totalStartTime = DateTime.now();
    // Encode di Flutter
    print('📱 Encoding image in Flutter...');
    final encodingStartTime = DateTime.now();

    Map<String, dynamic> encodingResult = await encodeImage(imageFile);
    final encodingEndTime = DateTime.now();
    _arithmeticCompressionTime = encodingEndTime.difference(encodingStartTime);

    if (encodingResult['status'] != 'success') {
      return {'encoding': encodingResult, 'decoding': null};
    }

    // Store sizes
    _originalSize = encodingResult['original_size'];
    _compressedSize = encodingResult['encoded_size'];

    print(
        '✅ Encoding success! Size: ${encodingResult['original_size']} -> ${encodingResult['encoded_size']}');
    print('⏱️ Encoding time: ${_arithmeticCompressionTime!.inMilliseconds}ms');

    // Kirim ke Django untuk decode
    print('🐍 Sending to Django for decoding...');
    final sendingStartTime = DateTime.now();

    Map<String, dynamic> decodingResult = await sendToDjangoDecoder(
      encodedData: encodingResult['encoded_data'],
      model: Map<int, int>.from(encodingResult['model']),
      shape: List<int>.from(encodingResult['shape']),
      mode: encodingResult['mode'],
    );

    final sendingEndTime = DateTime.now();
    _sendingTime = sendingEndTime.difference(sendingStartTime);

    if (decodingResult['status'] == 'success') {
      // Ambil decoded_size dari server jika ada
      if (decodingResult['decoded_size'] != null) {
        _decodedSize = decodingResult['decoded_size'];
      }
      
      // Ambil decompression_time dari server jika ada
      if (decodingResult['decompression_time_seconds'] != null) {
        final seconds = decodingResult['decompression_time_seconds'];
        if (seconds is num) {
          _decompressionTime = Duration(milliseconds: (seconds * 1000).round());
        }
      }
    }

    final totalEndTime = DateTime.now();
    _totalTime = totalEndTime.difference(totalStartTime);

    if (decodingResult['status'] == 'success') {
      print(
          '✅ Django decoding success! Image URL: ${decodingResult['image_url']}');
    } else {
      print('❌ Django decoding failed: ${decodingResult['error']}');
    }

    print('⏱️ Network time: ${_sendingTime!.inMilliseconds}ms');
    print('⏱️ Total time: ${_totalTime!.inMilliseconds}ms');

    // Generate processing stats
    _generateProcessingStats();

    return {
      'encoding': encodingResult,
      'decoding': decodingResult,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arithmetic Image Encoder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.image,
                      size: 64,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    if (_selectedImage != null) ...[
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isProcessing ? null : _pickImageFromGallery,
                            icon: Icon(Icons.photo_library),
                            label: Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isProcessing ? null : _pickImageFromCamera,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Process Button
            ElevatedButton(
              onPressed: (_selectedImage != null && !_isProcessing)
                  ? _processSelectedImage
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
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
                        SizedBox(width: 12),
                        Text('Processing...'),
                      ],
                    )
                  : Text(
                      'Process Image',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),

            // ✅ PERBAIKI: Stats Button dengan kondisi yang benar
            if (_result != null && _processingStats != null) ...[
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showProcessingStats,
                icon: Icon(Icons.analytics),
                label: Text('View Detailed Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            SizedBox(height: 16),

            // Results Section
            if (_result != null) ...[
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Processing Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildResultsContent(),
                          
                          // ✅ TAMBAHKAN: Checkout Button Section
                          SizedBox(height: 20),
                          _buildCheckoutSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        border: Border.all(color: Colors.purple.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'Statistik Arithmetic Coding',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // ✅ TAMBAH: Parameter Evaluasi Kompresi
          if (_originalSize != null && _compressedSize != null) ...[
            Text(
              'Parameter Evaluasi Kompresi:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
              ),
            ),
            SizedBox(height: 8),
            
            // RC (Ratio of Compression)
            _buildStatRow('RC (Ratio of Compression)', 
                '${(_originalSize! / _compressedSize!).toStringAsFixed(2)}'),
            
            // CR (Compression Ratio)
            _buildStatRow('CR (Compression Ratio)', 
                '${((1 - (_compressedSize! / _originalSize!)) * 100).toStringAsFixed(2)}%'),
            
            // RD (Redundancy)
            _buildStatRow('RD (Redundancy)', 
                '${(((_originalSize! - _compressedSize!) / _originalSize!) * 100).toStringAsFixed(2)}%'),
            
            SizedBox(height: 12),
          ],

          // Ukuran data
          if (_originalSize != null)
            _buildStatRow('Ukuran Asli', '${_formatBytes(_originalSize!)} (${_originalSize!} bytes)'),
          if (_compressedSize != null)
            _buildStatRow('Ukuran Kompresi', '${_formatBytes(_compressedSize!)} (${_compressedSize!} bytes)'),
          if (_decodedSize != null)
            _buildStatRow('Ukuran Decode', '${_formatBytes(_decodedSize!)} (${_decodedSize!} bytes)'),

          // Timing Information dengan format yang sama
          if (_arithmeticCompressionTime != null)
            _buildStatRow('Waktu Kompresi',
                '${(_arithmeticCompressionTime!.inMilliseconds / 1000).toStringAsFixed(3)}s'),
          if (_decompressionTime != null)
            _buildStatRow('Waktu Dekompresi',
                '${(_decompressionTime!.inMilliseconds / 1000).toStringAsFixed(3)}s'),
          if (_sendingTime != null)
            _buildStatRow('Waktu Network',
                '${(_sendingTime!.inMilliseconds / 1000).toStringAsFixed(3)}s'),
          if (_totalTime != null)
            _buildStatRow('Total Waktu',
                '${(_totalTime!.inMilliseconds / 1000).toStringAsFixed(3)}s'),
        ],
      ),
    );
  }
  
// ✅ TAMBAHKAN: _buildStatRow method yang diperlukan
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    if (data['status'] == 'error') {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              data['error'] ?? 'Unknown error',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Success',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...data.entries
              .where((e) => e.key != 'status' && e.key != 'model')
              .map((e) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${e.key}:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value.toString(),
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = null; // Clear previous results
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image from gallery: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = null; // Clear previous results
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _processSelectedImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      Map<String, dynamic> result = await processImage(_selectedImage!);
      setState(() {
        _result = result;
      });

      _showSuccessSnackBar('Image processing completed!');
    } catch (e) {
      _showErrorSnackBar('Processing failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _generateProcessingStats() {
    final StringBuffer stats = StringBuffer();

    stats.writeln('=== STATISTIK ARITHMETIC CODING ===');

    // ✅ TAMBAH: Ukuran data yang lebih detail
    if (_originalSize != null) {
      stats.writeln('📦 Ukuran Asli: ${_formatBytes(_originalSize!)} (${_originalSize!} bytes)');
    }
    if (_compressedSize != null) {
      stats.writeln('📦 Ukuran Kompresi: ${_formatBytes(_compressedSize!)} (${_compressedSize!} bytes)');
    }
    if (_decodedSize != null) {
      stats.writeln('🔄 Ukuran Hasil Decode: ${_formatBytes(_decodedSize!)} (${_decodedSize!} bytes)');
    }

    // ✅ TAMBAH: Parameter evaluasi kompresi yang sama dengan RLE/Huffman
    if (_originalSize != null && _compressedSize != null) {
      stats.writeln('\n📊 PARAMETER EVALUASI KOMPRESI:');
      
      final rc = _originalSize! / _compressedSize!;
      stats.writeln('• Ratio of Compression (RC): ${rc.toStringAsFixed(2)}');
      
      final cr = (1 - (_compressedSize! / _originalSize!)) * 100;
      stats.writeln('• Compression Ratio (CR): ${cr.toStringAsFixed(2)}%');
      
      final rd = ((_originalSize! - _compressedSize!) / _originalSize!) * 100;
      stats.writeln('• Redundancy (RD): ${rd.toStringAsFixed(2)}%');
    }

    // ✅ UPDATE: Waktu pemrosesan dengan format yang sama
    stats.writeln('\n⏰ WAKTU PEMROSESAN:');
    if (_arithmeticCompressionTime != null) {
      stats.writeln('• Waktu Kompresi Arithmetic: ${(_arithmeticCompressionTime!.inMilliseconds / 1000).toStringAsFixed(3)}s');
    }
    
    if (_decompressionTime != null) {
      stats.writeln('• Waktu Dekompresi: ${(_decompressionTime!.inMilliseconds / 1000).toStringAsFixed(3)}s');
    }
    
    if (_sendingTime != null) {
      stats.writeln('• Waktu Kirim ke Server: ${(_sendingTime!.inMilliseconds / 1000).toStringAsFixed(3)}s');
    }
    
    if (_totalTime != null) {
      stats.writeln('• Total Waktu Keseluruhan: ${(_totalTime!.inMilliseconds / 1000).toStringAsFixed(3)}s');
    }

    _processingStats = stats.toString();
  }


  // ✅ TAMBAH FUNCTION INI JUGA
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // ✅ TAMBAH FUNCTION SHOW STATS
  void _showProcessingStats() {
    if (_processingStats == null) {
      _showErrorSnackBar('No processing statistics available');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text('Processing Statistics'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                _processingStats!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Handle checkout action
  void _handleCheckout() {
    if (_result == null || 
      _result!['encoding'] == null || 
      _result!['encoding']['status'] != 'success') {
    _showErrorSnackBar('No successful encoding result found');
    return;
  }

    Map<String, dynamic> checkoutData = {
    'pegawai_info': {
      'id_pegawai': widget.idPegawai,
      'nama': widget.nama,
      'nip': widget.nip,
      'id_unit_kerja': widget.idUnitKerja,
      'lokasi': widget.lokasi,
    },
    'location': {
      'latitude': widget.latitude,
      'longitude': widget.longitude,
    },
    'image_processing': {
      'encoding_status': _result!['encoding']['status'],
      'original_size': _result!['encoding']['original_size'],
      'compressed_size': _result!['encoding']['encoded_size'],
      'compression_ratio': _result!['encoding']['compression_ratio'],
      'shape': _result!['encoding']['shape'],
      'processing_timestamp': DateTime.now().toIso8601String(),
    },
    'timing': {
      'capture_time_ms': _captureTime?.inMilliseconds,
      'compression_time_ms': _arithmeticCompressionTime?.inMilliseconds,
      'sending_time_ms': _sendingTime?.inMilliseconds,
      'total_time_ms': _totalTime?.inMilliseconds,
    }
  };

  // Tambahkan data decoding jika ada
  if (_result!['decoding'] != null && _result!['decoding']['status'] == 'success') {
    checkoutData['image_processing']['decoding_status'] = _result!['decoding']['status'];
    checkoutData['image_processing']['decoded_image_url'] = _result!['decoding']['image_url'];
    checkoutData['image_processing']['filename'] = _result!['decoding']['filename'];
  }

  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.purple),
            SizedBox(width: 8),
            Text('Confirm Checkout'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to proceed with checkout?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 Employee: ${widget.nama ?? "N/A"}'),
                  Text('🏢 Unit: ${widget.idUnitKerja ?? "N/A"}'),
                  Text('📍 Location: ${widget.lokasi ?? "N/A"}'),
                  Text('🖼️ Image: Successfully processed'),
                  if (_originalSize != null && _compressedSize != null)
                    Text('📦 Size: ${_formatBytes(_originalSize!)} → ${_formatBytes(_compressedSize!)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToCheckout(checkoutData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text('Proceed'),
          ),
        ],
      );
    },
  );
}

  void _proceedToCheckout(Map<String, dynamic> checkoutData) {
  print('🛒 Proceeding to checkout with data:');
  
  try {
    // Extract data dari checkoutData dengan benar
    Map<String, dynamic> pegawaiInfo = checkoutData['pegawai_info'] ?? {};
    Map<String, dynamic> location = checkoutData['location'] ?? {};
    
    // Navigate ke CheckOutPage yang sudah ada dengan data yang sesuai
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckOutPage(
          imagePath: _selectedImage?.path ?? '',
          imageData: _selectedImage != null ? File(_selectedImage!.path).readAsBytesSync() : Uint8List(0),
          idPegawai: pegawaiInfo['id_pegawai']?.toString() ?? widget.idPegawai ?? '',
          lokasi: pegawaiInfo['lokasi']?.toString() ?? widget.lokasi ?? '',
          jenis: widget.jenis ?? 0,
          checkMode: widget.checkMode ?? 1, // 1 untuk checkout
          nama: pegawaiInfo['nama']?.toString() ?? widget.nama ?? '',
          nip: pegawaiInfo['nip']?.toString() ?? widget.nip ?? '',
          idUnitKerja: pegawaiInfo['id_unit_kerja']?.toString() ?? widget.idUnitKerja ?? '',
          latitude: location['latitude']?.toString() ?? widget.latitude?.toString() ?? '0',
          longitude: location['longitude']?.toString() ?? widget.longitude?.toString() ?? '0',
          kompresiId: null,
        ),
      ),
    ).then((result) {
      // Reset setelah kembali
      setState(() {
        _selectedImage = null;
        _result = null;
      });
    });
    
  } catch (e) {
    print('❌ Error navigating to checkout: $e');
    _showErrorSnackBar('Failed to open checkout page: $e');
  }
}

  // STEP 1: Encode gambar di Flutter
  Future<Map<String, dynamic>> encodeImage(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      int originalWidth = image.width;
      int originalHeight = image.height;

      // 🔥 KODE RESIZE DILETAKKAN DI SINI! 👇
      int targetMaxSize = 512;

      if (image.width > targetMaxSize || image.height > targetMaxSize) {
        print('📏 Original size: ${image.width}x${image.height}');

        double aspectRatio = image.width / image.height;
        int newWidth, newHeight;

        if (image.width > image.height) {
          newWidth = targetMaxSize;
          newHeight = (targetMaxSize / aspectRatio).round();
        } else {
          newHeight = targetMaxSize;
          newWidth = (targetMaxSize * aspectRatio).round();
        }

        image = img.copyResize(image, width: newWidth, height: newHeight);
        print('✅ Resized to: ${image.width}x${image.height}');
      }
      // ☝️ SAMPAI SINI

      int width = image.width;
      int height = image.height;

      List<int> pixels = [];
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int pixel = image.getPixelSafe(x, y);

          // ✅ BENAR: Pakai built-in functions
          int r = img.getRed(pixel);
          int g = img.getGreen(pixel);
          int b = img.getBlue(pixel);

          pixels.add(r);
          pixels.add(g);
          pixels.add(b);
        }
      }

      // Encode pake arithmetic coding
      Map<String, dynamic> result = _coder.encode(pixels);
      Uint8List encodedBytes = result['encoded_bytes'];
      Map<int, int> freqModel = result['freq_model'];

      String encodedData = base64Encode(encodedBytes);

      return {
        "status": "success",
        "encoded_data": encodedData,
        "model": freqModel,
        "shape": [height, width, 3],
        "mode": "RGB",
        "original_size": pixels.length,
        "encoded_size": encodedBytes.length,
        "compression_ratio": encodedBytes.length > 0
            ? "${(pixels.length / encodedBytes.length).toStringAsFixed(2)}:1"
            : "inf:1"
      };
    } catch (e) {
      return {"status": "error", "error": e.toString()};
    }
  }

  // STEP 2: Kirim ke Django decode_image
  Future<Map<String, dynamic>> sendToDjangoDecoder({
    required String encodedData,
    required Map<int, int> model,
    required List<int> shape,
    String mode = 'RGB',
  }) async {
    try {
      // Convert int keys ke string untuk JSON
      Map<String, int> stringModel = {};
      model.forEach((key, value) {
        stringModel[key.toString()] = value;
      });

      Map<String, dynamic> requestData = {
        'encoded_data': encodedData,
        'model': stringModel,
        'shape': shape,
        'mode': mode,
        // Tambahkan data pegawai
        'id_pegawai': widget.idPegawai,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'nama': widget.nama,
        'nip': widget.nip,
        'id_unit_kerja': widget.idUnitKerja,
        'lokasi': widget.lokasi,
      };

      http.Response response = await http.post(
        Uri.parse(djangoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'error': 'Server error ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'status': 'error', 'error': 'Network error: ${e.toString()}'};
    }
  }
}
