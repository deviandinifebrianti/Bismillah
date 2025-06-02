// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// // import 'package:absensi/pages/checkout.dart';
// import 'package:absensi/pages/arithmatic.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

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
//   });

//   @override
//   KameraPageState createState() => KameraPageState();
// }

// class KameraPageState extends State<KameraPage> {
//   CameraController? _cameraController;
//   List<CameraDescription>? cameras;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   Future<void> uploadBase64Image(
//       String base64Image, String idPegawai, String name) async {
//     final url = Uri.parse(
//         'http://192.168.1.10:8000/sipreti/add_image/'); // ganti dengan URL Django kamu

//     final response = await http.post(
//       url,
//       body: {
//         'url_image': base64Image,
//         'id_pegawai': idPegawai,
//         'name': name,
//       },
//     );

//     final result = json.decode(response.body);
//     print(result);
//   }

//   Future<void> _initializeCamera() async {
//     cameras = await availableCameras();
//     if (cameras != null && cameras!.isNotEmpty) {
//       _cameraController = CameraController(
//         cameras![1],
//         ResolutionPreset.high,
//       );

//       await _cameraController!.initialize();
//       if (!mounted) return;
//       setState(() {});
//     }
//   }

//   Future<void> _captureImage() async {
//     if (_cameraController != null && _cameraController!.value.isInitialized) {
//       try {
//         final image = await _cameraController!.takePicture();
//         final bytes = await image.readAsBytes(); // ambil data image

//         if (!mounted) return;
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ArithmeticCompressionPage(
//               imagePath: image.path,
//               imageData: bytes,
//               idPegawai: widget.idPegawai,
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
//       } catch (e) {
//         debugPrint("Error capturing image: $e");
//       }
//     }
//   }

//   Future<void> _submitAbsensi(String alamat) async {
//     var url = Uri.parse('$baseUrl/sipreti/log_absensi/');
//     var response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         "id_pegawai": widget.idPegawai,
//         "latitude": widget.latitude,
//         "longitude": widget.longitude,
//         "alamat": alamat,
//         'jenis': widget.jenis, // 0 = Harian, 1 = Dinas (misal)
//         'check_mode': widget.checkMode, // 0 = Check In, 1 = Check Out
//         'nama_kamera': 'Depan',
//         'waktu': DateTime.now().toIso8601String(),
//       }),
//     );

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Absen berhasil")),
//       );
//       Navigator.pop(context);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Absen gagal: ${response.body}")),
//       );
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
//                 width: 200,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromARGB(255, 7, 78, 230),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     elevation: 8,
//                   ),
//                   onPressed: _captureImage,
//                   child: Text(
//                     widget.checkMode == 0 ? 'Check In' : 'Check Out',
//                     style: const TextStyle(color: Colors.white, fontSize: 24),
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
