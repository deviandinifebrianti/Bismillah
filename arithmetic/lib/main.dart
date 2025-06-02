import 'package:flutter/material.dart';
import 'package:absensi/pages/dashboard.dart';
import 'package:absensi/pages/checkout.dart';
import 'package:absensi/pages/pendukung.dart';
import 'package:absensi/pages/checkoutdinas.dart';
import 'package:absensi/pages/lokasi.dart';
import 'package:absensi/pages/kamera2.dart';
import 'package:absensi/pages/starter.dart';
import 'package:absensi/pages/daftar.dart';
import 'package:absensi/pages/arithmatic.dart';
import 'package:absensi/pages/akun.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi App', 
      theme: ThemeData(
        primarySwatch: Colors.teal, 
      ),
      home: const StarterPage(), 
      initialRoute: '/',
      onGenerateRoute: (settings) {
    switch (settings.name) {
      case '/dashboard':
        final args = settings.arguments as Map<String, dynamic>?;

        final idPegawai = args?['idPegawai']?.toString() ?? '';
        final nama = args?['nama'] ?? '';
        final nip = args?['nip'] ?? '';
        final jenis = int.tryParse(args?['jenis'].toString() ?? '0') ?? 0;
        final lokasi = args?['lokasi'] ?? '';
        final checkMode = int.tryParse(args?['checkMode'].toString() ?? '0') ?? 0;
        final idUnitKerja = args?['idUnitKerja']?.toString() ?? '';
        final latitude = args?['latitude']?.toString() ?? '';
        final longitude = args?['longitude']?.toString() ?? '';

        return MaterialPageRoute(
          builder: (context) => DashboardPage(
            idPegawai: idPegawai,
            nama: nama,
            nip: nip,
            jenis: jenis,
            checkMode: checkMode,
            idUnitKerja: idUnitKerja,
            lokasi: lokasi,
            latitude: latitude,
            longitude: longitude,
          ),
        );

        case '/akun':
            final args = settings.arguments as Map<String, dynamic>?;
            
            // Convert data sesuai format yang dibutuhkan AkunPage
            final userData = {
              'idPegawai': args?['idPegawai']?.toString() ?? '',
              'nama': args?['nama'] ?? '',
              'nip': args?['nip'] ?? '',
              'jenis': args?['jenis']?.toString() ?? '0',
              'idUnitKerja': args?['idUnitKerja']?.toString() ?? '',
              'lokasi': args?['lokasi'] ?? '',
              'latitude': args?['latitude']?.toString() ?? '',
              'longitude': args?['longitude']?.toString() ?? '',
              'checkMode': args?['checkMode']?.toString() ?? '0',
              'checkInTime': args?['checkInTime'],
              'checkOutTime': args?['checkOutTime'],
              'sudahCheckIn': args?['sudahCheckIn'] ?? false,
              'sudahCheckOut': args?['sudahCheckOut'] ?? false,
            };

            return MaterialPageRoute(
              builder: (context) => AkunPage(userData: userData),
            );
            
          // case '/huffman':
          //   final args = settings.arguments as Map<String, dynamic>;
          //   final imagePath = args['imagePath']; 
          //   final imageData = args['imageData']; 
          //   final idPegawai = args['idPegawai'];
          //   return MaterialPageRoute(
          //     builder: (_) => ArithmeticCompressionPage(
          //       imagePath: imagePath!,
          //       imageData: imageData!,
          //       idPegawai: idPegawai!,
          //       jenis: int.tryParse(args['jenis'].toString()) ?? 0,
          //       lokasi: args['lokasi']!,
          //       checkMode: args['checkMode']!,
          //       nama: args['nama']!,
          //       nip: args['nip']!,
          //       idUnitKerja: args['idUnitKerja']!, 
          //       latitude: args['latitude']!,
          //       longitude: args['longitude']!,               
          //     ),
          //   );
          case '/dokumen':
            return MaterialPageRoute(builder: (_) => const DokumenPage());
          case '/checkoutdinas':
            return MaterialPageRoute(builder: (_) => const CheckOutDinasPage());
          case '/lokasi':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => LokasiPage(
                idPegawai: args['idPegawai'],
                jenis: int.parse(args['harian'].toString()),
                checkMode: int.tryParse(args['checkMode'].toString()) ?? 0,
                nama: args['nama'],
                nip: args['nip'],
                idUnitKerja: args['idUnitKerja'],
                latitude: args['latitude'],
                longitude: args['longitude'],
                lokasi: args['lokasi'],
              ),
            );
          // case '/kamera':
          //   final args = settings.arguments as Map<String, dynamic>;
          //   return MaterialPageRoute(
          //     builder: (_) => KameraPage(
          //       idPegawai: args['idPegawai'],
          //       jenis: int.parse(args['jenis'].toString()),
          //       lokasi: args['lokasi'],
          //       checkMode: args['checkMode'],
          //       nama: args['nama'],
          //       nip: args['nip'],
          //       idUnitKerja: args['idUnitKerja'],
          //       latitude: args['latitude'],
          //       longitude: args['longitude'],
          //     ),
          //   );

          case '/starter':
            return MaterialPageRoute(builder: (_) => const StarterPage());
          case '/daftar':
            return MaterialPageRoute(builder: (_) => DaftarPage());
          case '/checkout':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CheckOutPage(
                idPegawai: args['idPegawai'],
                jenis: int.parse(args['jenis'].toString()),
                lokasi: args['lokasi'],
                imagePath: args['imagePath'],
                imageData: args['imageData'],
                checkMode: args['checkMode'],
                nama: args['nama'],
                nip: args['nip'],
                idUnitKerja: args['idUnitKerja'],
                latitude: args['latitude'],
                longitude: args['longitude'],
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const StarterPage());
        }
      },
    );
  }
}