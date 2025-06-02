import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:absensi/pages/login.dart';
import 'package:geolocator/geolocator.dart';
import 'package:absensi/utils/device_helper.dart';

final String baseUrl = "http://192.168.1.14:8000";

class DaftarPage extends StatefulWidget {
  const DaftarPage({Key? key}) : super(key: key);

  @override
  _DaftarPageState createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final TextEditingController nipController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isRegistering = false;

  List<dynamic> jabatanList = [];
  List<dynamic> unitKerjaList = [];

  String? selectedJabatan;
  String? selectedUnitKerja;

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    try {
      print(
          "Mencoba mengambil data dropdown dari: $baseUrl/sipreti/jabatan/ dan $baseUrl/sipreti/unit_kerja/");

      final jabatanRes = await http.get(Uri.parse('$baseUrl/sipreti/jabatan/'));
      final unitRes = await http.get(Uri.parse('$baseUrl/sipreti/unit_kerja/'));

      print("Status code jabatan: ${jabatanRes.statusCode}");
      print("Status code unit kerja: ${unitRes.statusCode}");

      if (jabatanRes.statusCode == 200 && unitRes.statusCode == 200) {
        final jabatanData = json.decode(jabatanRes.body);
        final unitKerjaData = json.decode(unitRes.body);

        print('Raw Jabatan data: $jabatanData');
        print('Raw Unit Kerja data: $unitKerjaData');

        setState(() {
          jabatanList = jabatanData;
          unitKerjaList = unitKerjaData;
        });

        print('Jumlah jabatan: ${jabatanList.length}');
        print('Jumlah unit kerja: ${unitKerjaList.length}');

        if (jabatanList.isNotEmpty) {
          print('Contoh format jabatan pertama: ${jabatanList[0]}');
        }
        if (unitKerjaList.isNotEmpty) {
          print('Contoh format unit kerja pertama: ${unitKerjaList[0]}');
        }
      } else {
        print(
            "Gagal ambil data dropdown: ${jabatanRes.statusCode} - ${jabatanRes.body}");
        print(
            "Gagal ambil data dropdown: ${unitRes.statusCode} - ${unitRes.body}");
      }
    } catch (e, stackTrace) {
      print("Error ambil data dropdown: $e");
      print("Stack trace: $stackTrace");
    }
  }

  Future<void> daftarAkun(BuildContext context) async {
    if (_validateInputs(context)) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password tidak cocok')),
        );
        return;
      }

      setState(() {
        _isRegistering = true;
      });

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/sipreti/daftar/'),
          body: {
            'email': emailController.text,
            'no_hp': phoneController.text,
            'nama': nameController.text,
            'password': passwordController.text,
            'nip': nipController.text,
            'id_jabatan': selectedJabatan.toString(),
            'id_unit_kerja': selectedUnitKerja.toString(),
          },
        ).timeout(Duration(seconds: 5));

        if (response.statusCode == 201) {
          var responseBody = json.decode(response.body);

          // Tampilkan notifikasi sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Akun berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate ke Login page
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          });
        } else {
          var body = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Gagal daftar: ${body['message'] ?? 'Terjadi kesalahan'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Aktifkan kembali tombol daftar
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });
        }
      }
    }
  }

  bool _validateInputs(BuildContext context) {
    if (emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        nameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        selectedJabatan == null ||
        selectedUnitKerja == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua kolom!')),
      );
      return false;
    }
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid!')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          backgroundImage(),
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: formContainer(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget backgroundImage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/latar.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget formContainer(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 150),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buat Akun Baru',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField('NIP Pegawai', nipController),
          _buildTextField('Nama Pegawai', nameController),
          _buildTextField('Email', emailController),
          _buildTextField('No. Telepon', phoneController),
          _buildTextField('Password', passwordController, isPassword: true),
          _buildTextField('Konfirmasi Password', confirmPasswordController,
              isPassword: true),
          const SizedBox(height: 10),
          _buildDropdown(
            label: 'Pilih Unit Kerja',
            items: unitKerjaList,
            selectedValue: selectedUnitKerja,
            onChanged: (value) {
              setState(() {
                selectedUnitKerja = value;
              });
            },
            valueKey: 'id_unit_kerja',
            labelKey: 'nama_unit_kerja',
          ),
          SizedBox(height: 20),
          _buildDropdown(
            label: 'Pilih Jabatan',
            items: jabatanList,
            selectedValue: selectedJabatan,
            onChanged: (value) {
              setState(() {
                selectedJabatan = value;
              });
            },
            valueKey: 'id_jabatan',
            labelKey: 'nama_jabatan',
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _isRegistering ? null : () => daftarAkun(context),
              child: _isRegistering
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )),
                        SizedBox(width: 10),
                        Text('SEDANG MENDAFTAR...',
                            style: TextStyle(fontSize: 18)),
                      ],
                    )
                  : Text('DAFTAR SEKARANG', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<dynamic> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    required String valueKey,
    required String labelKey,
  }) {
    // Tambahkan logging untuk debugging
    print("Building dropdown untuk $label dengan ${items.length} items");
    print("Selected value: $selectedValue");

    // Periksa apakah items kosong
    if (items.isEmpty) {
      return Container(
        margin: EdgeInsets.only(bottom: 15),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "$label (Memuat data...)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Menunggu data", style: TextStyle(color: Colors.grey)),
              Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    // Verifikasi bahwa setiap item memiliki key yang diperlukan
    items.forEach((item) {
      if (!item.containsKey(valueKey) || !item.containsKey(labelKey)) {
        print("WARNING: Item tidak memiliki key yang diperlukan: $item");
      }
    });

    try {
      return DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
        isExpanded: true,
        items: items.map<DropdownMenuItem<String>>((item) {
          // Periksa apakah item memiliki key yang diperlukan
          if (!item.containsKey(valueKey) || !item.containsKey(labelKey)) {
            print("Item tanpa key yang diperlukan: $item");
            return DropdownMenuItem<String>(
              value: "error",
              child: Text("Error: Format data tidak valid"),
            );
          }

          return DropdownMenuItem<String>(
            value: item[valueKey].toString(),
            child: Text(item[labelKey].toString()),
          );
        }).toList(),
        onChanged: onChanged,
        hint: Text("Pilih $label"),
        menuMaxHeight: 300, // Batasi tinggi menu
      );
    } catch (e) {
      print("Error rendering dropdown $label: $e");
      return Container(
        margin: EdgeInsets.only(bottom: 15),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "$label (Error)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          ),
          child: Text("Error: $e", style: TextStyle(color: Colors.red)),
        ),
      );
    }
  }
}
