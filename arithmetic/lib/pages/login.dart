import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:absensi/pages/daftar.dart';
import 'package:absensi/pages/dashboard.dart';
import 'dart:convert';
import 'package:absensi/utils/device_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';

const String baseUrl = "http://192.168.1.88:8000"; // Ganti dengan IP kamu

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  Future<bool> kirimDeviceInfoKeUserAndroid(
      String idPegawai, String nama) async {
    try {
      // Get device information
      String? deviceId = await DeviceHelper.getDeviceId();

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      // Prepare data to send
      final deviceData = {
        'id_pegawai': idPegawai,
        'username': nama,
        'device_id': deviceId ?? 'unknown',
        'device_brand': androidInfo.brand,
        'device_model': androidInfo.model,
        'device_os_version': androidInfo.version.release,
        'device_sdk_version': androidInfo.version.sdkInt.toString(),
        'last_login': DateTime.now().toIso8601String(),
      };

      // Log the data being sent
      print('Mengirim data perangkat: $deviceData');

      try {
        // Send to Django backend
        final response = await http
            .post(
              Uri.parse('$baseUrl/sipreti/user_android/'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(deviceData),
            )
            .timeout(Duration(seconds: 10)); // Tambahkan timeout

        print('Status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Info perangkat berhasil disimpan ke tabel user_android');
          return true;
        } else {
          print('❌ Gagal menyimpan info perangkat: ${response.statusCode}');
          print('Response body: ${response.body}');
          return false;
        }
      } catch (httpError) {
        print('❌ HTTP Error saat mengirim info perangkat: $httpError');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error saat mendapatkan info perangkat: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController nipController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/latar.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/pemkot_mlg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 320),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masuk Presensi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField('Masukkan NIP', nipController),
                      _buildTextField('Email', emailController),
                      _buildTextFieldPassword('Password', passwordController),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final nip = nipController.text;
                          final email = emailController.text;
                          final password = passwordController.text;

                          if (nip.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Semua field wajib diisi!')),
                            );
                            return;
                          }

                          final response = await http.post(
                            Uri.parse('$baseUrl/sipreti/login/'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'nip': nipController.text,
                              'email': emailController.text,
                              'password': passwordController.text,
                            }),
                          );

                          print('Response body: ${response.body}');

                          if (response.statusCode == 200) {
                            final data = json.decode(response.body);

                            if (data['status'] == 'success' &&
                                data['data'] != null) {
                              final user = data['data'];
                              String idPegawai = user['id_pegawai'].toString();
                              String nama = user['nama'];

                              // Kirim device info setelah login berhasil
                              try {
                                await kirimDeviceInfoKeUserAndroid(
                                    idPegawai, nama);
                                print(
                                    "Info perangkat berhasil dikirim saat login");
                              } catch (deviceError) {
                                print(
                                    "Gagal mengirim info perangkat: $deviceError");
                                // Lanjutkan proses meskipun gagal mengirim device info
                              }

                              final absensiResponse = await http.get(
                                Uri.parse('$baseUrl/sipreti/log_absensi/'),
                                headers: {'Content-Type': 'application/json'},
                              );

                              Map<String, dynamic> absensiData = {};
                              String? checkInTime;
                              String? checkOutTime;
                              bool sudahCheckIn = false;
                              bool sudahCheckOut = false;

                              if (absensiResponse.statusCode == 200) {
                                absensiData = json.decode(absensiResponse.body);

                                // Ambil data check-in dan check-out
                                checkInTime = absensiData['check_in'];
                                checkOutTime = absensiData['check_out'];

                                // Tentukan status
                                sudahCheckIn = checkInTime != null &&
                                    checkInTime.isNotEmpty;
                                sudahCheckOut = checkOutTime != null &&
                                    checkOutTime.isNotEmpty;
                              }
                              Navigator.pushNamed(
                                context,
                                '/dashboard',
                                arguments: {
                                  'idPegawai': user['id_pegawai'].toString(),
                                  'nama': user['nama'],
                                  'nip': user['nip'],
                                  // 'email': user['email'],
                                  // 'no_hp': user['no_hp'],
                                  'jenis': user['jenis'],
                                  'idUnitKerja':
                                      user['id_unit_kerja'].toString(),
                                  'checkInTime': sudahCheckIn
                                      ? checkInTime
                                      : null, // Gunakan string sebagai kunci
                                  'checkOutTime':
                                      sudahCheckOut ? checkOutTime : null,
                                  'sudahCheckIn':
                                      sudahCheckIn, // Kirim flag boolean
                                  'sudahCheckOut': sudahCheckOut,
                                },
                              );
                            } else {
                              print('Login gagal: ${data['message']}');
                            }
                          } else {
                            print('Error: ${response.statusCode}');
                          }
                        },
                        child: const Text(
                          'MASUK',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DaftarPage()),
                            );
                          },
                          child: const Text(
                            'Belum punya akun? Daftar di sini',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldPassword(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
