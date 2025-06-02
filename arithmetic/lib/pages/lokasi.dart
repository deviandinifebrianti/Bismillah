import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_feature_geolocator/flutter_feature_geolocator.dart';
import 'package:absensi/pages/kamera.dart';
import 'package:absensi/pages/arithmatic.dart';
import 'package:absensi/pages/kamera_huffman.dart';
import 'package:absensi/pages/kamera_rle.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:absensi/services/lokasi_service.dart';
import 'package:absensi/pages/huffman.dart';
import 'package:absensi/pages/rle.dart';
import 'package:absensi/pages/profile.dart';

const String baseUrl = "http://192.168.1.14:8000"; // Ganti dengan IP kamu

class LokasiPage extends StatefulWidget {
  final String idPegawai;
  final int jenis;
  final int checkMode;
  final String nama;
  final String nip;
  final String idUnitKerja;
  final String lokasi;
  final String latitude;
  final String longitude;
  final int? kompresiId;

  const LokasiPage({
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
    this.kompresiId,
  }) : super(key: key);

  @override
  State<LokasiPage> createState() => _LokasiPageState();
}

class _LokasiPageState extends State<LokasiPage> {
  // LatLng? _currentPosition;
  double? _radiusMeter;
  LatLng? _unitKerjaPosition;
  Position? _currentPosition;

  // final LokasiService _lokasiService = LokasiService(baseUrl);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUnitKerjaData(); // Ini penting diselesaikan dulu
    await _getCurrentLocation(); // Baru ambil lokasi setelah ada radius & posisi unit kerja
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Mendapatkan lokasi saat ini
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        // _currentPosition = LatLng(position.latitude, position.longitude);
        _currentPosition = position;
      });
      print('Lokasi sekarang: $_currentPosition');
      print('_unitKerjaPosition: $_unitKerjaPosition');
      print('_radiusMeter: $_radiusMeter');
    } else {
      print('Akses lokasi ditolak');
    }
  }

  Future<void> _getUnitKerjaData() async {
    final response = await http.get(Uri.parse('$baseUrl/sipreti/unit_kerja/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Response unit_kerja: ${response.body}');

      final selectedUnit = data.firstWhere(
        (unit) =>
            unit['id_unit_kerja'].toString() == widget.idUnitKerja.toString(),
        orElse: () => null,
      );
      print("ID Unit Kerja sebelum ke LokasiPage: ${widget.idUnitKerja}");
      print('Mengirim idUnitKerja: $widget.idUnitKerja');
      print('widget.idUnitKerja: ${widget.idUnitKerja}');
      print(
          'widget.idUnitKerja runtimeType: ${widget.idUnitKerja.runtimeType}');
      print('selectedUnit: $selectedUnit');

      if (selectedUnit != null) {
        print('Latitude: ${selectedUnit['latitude']}');
        print('Longitude: ${selectedUnit['longitude']}');
        print('Radius: ${selectedUnit['radius']}');

        setState(() {
          _unitKerjaPosition = LatLng(
            double.tryParse(selectedUnit['latitude'].toString()) ?? 0.0,
            double.tryParse(selectedUnit['longitude'].toString()) ?? 0.0,
          );
          _radiusMeter =
              (double.tryParse(selectedUnit['radius'].toString()) ?? 0.0) *
                  1000;
        });

        print('Position set to: $_unitKerjaPosition');
        print('Radius set to: $_radiusMeter');
      } else {
        print("Unit kerja tidak ditemukan");
      }
    }
  }

  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        return '${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}';
      } else {
        return 'Alamat tidak ditemukan';
      }
    } catch (e) {
      return 'Error mendapatkan alamat';
    }
  }

  Future<void> _handleAbsen() async {
    print('_currentPosition: $_currentPosition');
    print('_unitKerjaPosition: $_unitKerjaPosition');
    print('_radiusMeter: $_radiusMeter');

    if (_currentPosition == null ||
        _unitKerjaPosition == null ||
        _radiusMeter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tunggu lokasi dimuat terlebih dahulu")),
      );
      return;
    }

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _unitKerjaPosition!.latitude,
      _unitKerjaPosition!.longitude,
    );

    double toleransi = 20.0;
    double totalDistance = distance + _currentPosition!.accuracy;
    double totalRadius = _radiusMeter! + toleransi;

    print('📏 Jarak ke lokasi unit kerja: $distance');
    print('📡 Akurasi GPS: ${_currentPosition!.accuracy}');
    print('📦 Total radius: $totalRadius');
    print('🧮 Total distance (jarak + akurasi): $totalDistance');

    String alamat = '';

    if (distance <= totalRadius) {
      // String alamat = await getAddressFromLatLng(_currentPosition!);
      String alamat = await getAddressFromLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => KameraPage(
      //       idPegawai: widget.idPegawai,
      //       latitude: _currentPosition!.latitude.toString(),
      //       longitude: _currentPosition!.longitude.toString(),
      //       checkMode: widget.checkMode,
      //       jenis: widget.jenis,
      //       nama: widget.nama,
      //       nip: widget.nip,
      //       idUnitKerja: widget.idUnitKerja,
      //       lokasi: alamat,
      //     ),
      //   ),
      // );

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => KameraPage2(
      //       idPegawai: widget.idPegawai,
      //       latitude: _currentPosition!.latitude.toString(),
      //       longitude: _currentPosition!.longitude.toString(),
      //       checkMode: widget.checkMode,
      //       jenis: widget.jenis,
      //       nama: widget.nama,
      //       nip: widget.nip,
      //       idUnitKerja: widget.idUnitKerja,
      //       lokasi: alamat,
      //       kompresiId: null,
      //     ),
      //   ),
      // );

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => KameraPage3(
      //       idPegawai: widget.idPegawai,
      //       latitude: _currentPosition!.latitude.toString(),
      //       longitude: _currentPosition!.longitude.toString(),
      //       checkMode: widget.checkMode,
      //       jenis: widget.jenis,
      //       nama: widget.nama,
      //       nip: widget.nip,
      //       idUnitKerja: widget.idUnitKerja,
      //       lokasi: alamat,
      //     ),
      //   ),
      // );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HuffmanCameraScreen(
            idPegawai: widget.idPegawai,
            latitude: _currentPosition!.latitude.toString(),
            longitude: _currentPosition!.longitude.toString(),
            checkMode: widget.checkMode,
            jenis: widget.jenis,
            nama: widget.nama,
            nip: widget.nip,
            idUnitKerja: widget.idUnitKerja,
            lokasi: alamat,
          ),
        ),
      );

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => RLE(
      //       idPegawai: widget.idPegawai,
      //       latitude: _currentPosition!.latitude.toString(),
      //       longitude: _currentPosition!.longitude.toString(),
      //       // checkMode: widget.checkMode,
      //       // jenis: widget.jenis,
      //       nama: widget.nama,
      //       nip: widget.nip,
      //       idUnitKerja: widget.idUnitKerja,
      //       lokasi: alamat,
      //     ),
      //   ),
      // );

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ArithmeticEncoding(
      //       idPegawai: widget.idPegawai,
      //       latitude: _currentPosition!.latitude.toString(),
      //       longitude: _currentPosition!.longitude.toString(),
      //       // checkMode: widget.checkMode,
      //       // jenis: widget.jenis,
      //       nama: widget.nama,
      //       nip: widget.nip,
      //       idUnitKerja: widget.idUnitKerja,
      //       lokasi: alamat,
      //     ),
      //   ),
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Diluar radius lokasi unit kerja. Jarak: ${distance.toStringAsFixed(2)} meter")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Location',
          style: TextStyle(
              color: Colors.white), // Mengubah warna teks menjadi putih
        ),
        backgroundColor: const Color.fromARGB(255, 33, 137, 235),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white, // Mengubah warna ikon menjadi putih
          ),
          onPressed: () {
            Navigator.pop(context); // Aksi untuk kembali ke halaman sebelumnya
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset(
              'assets/pemkot_mlg.png', // Ganti dengan path logo Anda
              height: 40,
            ),
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
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      // initialCenter: _currentPosition!,
                      initialCenter: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        maxZoom: 19,
                      ),
                      CurrentLocationLayer(), // Layer untuk lokasi saat ini

                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 60.0,
                            height: 60.0,
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            child: const Icon(Icons.my_location,
                                color: Colors.blue),
                          ),
                          if (_unitKerjaPosition != null)
                            Marker(
                              width: 60.0,
                              height: 60.0,
                              point: _unitKerjaPosition!,
                              child:
                                  const Icon(Icons.business, color: Colors.red),
                            ),
                        ],
                      ),
                      if (_unitKerjaPosition != null && _radiusMeter != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _unitKerjaPosition!,
                              radius: _radiusMeter!,
                              color: Colors.blue
                                  .withAlpha(77), // Alpha 0.3 = 77 dari 255
                              borderStrokeWidth: 2,
                              borderColor: Colors.blue,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_currentPosition != null &&
                          _unitKerjaPosition != null &&
                          _radiusMeter != null)
                        Text(
                          'Jarak ke unit kerja: ${Geolocator.distanceBetween(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            _unitKerjaPosition!.latitude,
                            _unitKerjaPosition!.longitude,
                          ).toStringAsFixed(1)} meter',
                          style: TextStyle(fontSize: 16),
                        )
                      else
                        Text(
                          'Memuat data lokasi...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _handleAbsen,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text('Pilih Lokasi',
                            style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
