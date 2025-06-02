import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:absensi/utils/device_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:absensi/pages/login.dart';
import 'package:image_picker/image_picker.dart';

const String baseUrl = "http://192.168.1.14:8000";

class AkunPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AkunPage({Key? key, required this.userData}) : super(key: key);

  @override
  _AkunPageState createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  // Definisikan semua variabel yang dibutuhkan
  Map<String, dynamic> deviceInfo = {};
  Map<String, dynamic> pegawaiDetail = {};
  bool isLoading = true;
  int _currentIndex = 3; // Index untuk tab Akun
  String? profileImageUrl;
  bool isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
void didPopNext() {
  super.didPopNext();
  // ✅ Auto refresh ketika kembali ke halaman ini
  _loadData();
}

  Future<void> _loadData() async {
    await Future.wait([
      _getDeviceInfo(),
      _getPegawaiDetail(),
      _getProfilePhoto(),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getDeviceInfo() async {
    try {
      String? deviceId = await DeviceHelper.getDeviceId();
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;

      setState(() {
        deviceInfo = {
          'nama': _safeString(widget.userData['nama']) ?? 'Unknown',
          'email':
              '${_safeString(widget.userData['nama'])?.toLowerCase() ?? 'user'}@gmail.com',
          'no_hp': _safeString(widget.userData['no_hp']) ?? '081234567890',
          'device_id': deviceId ?? androidInfo.id,
          'device_brand': androidInfo.brand ?? 'Unknown',
          'device_model': androidInfo.model ?? 'Unknown',
        };
      });
    } catch (e) {
      print('Error getting device info: $e');
      // Set default values jika error
      setState(() {
        deviceInfo = {
          'nama': _safeString(widget.userData['nama']) ?? 'Unknown',
          'email': 'user@gmail.com',
          'no_hp': '081234567890',
          'device_id': 'Unknown',
          'device_brand': 'Unknown',
          'device_model': 'Unknown',
        };
      });
    }
  }

  Future<void> _getProfilePhoto() async {
    try {
      final idPegawai = widget.userData['idPegawai'];
      if (idPegawai == null) {
        print('Cannot get profile photo: idPegawai is null');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sipreti/get_profile_photo/$idPegawai/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null &&
            data['status'] == 'success' &&
            data['data'] != null &&
            data['data']['has_photo'] == true) {
          setState(() {
            profileImageUrl = data['data']['foto_url'];
          });
        }
      }
    } catch (e) {
      print('Error getting profile photo: $e');
    }
  }

  Future<void> _getPegawaiDetail() async {
    try {
      print('=== DEBUG: Getting Pegawai Detail ===');

      // Safe check untuk idPegawai
      final idPegawai = widget.userData['idPegawai'];
      if (idPegawai == null) {
        print('ERROR: idPegawai is null in userData');
        _setFallbackData();
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/sipreti/pegawai/$idPegawai/?_t=$timestamp';
      print('URL: $url');
      print('userData: ${widget.userData}');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json',
        'Cache-Control': 'no-cache', // ✅ TAMBAH INI
        'Pragma': 'no-cache', // ✅ TAMBAH INI
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed Data: $data');

        if (data != null &&
            data['status'] == 'success' &&
            data['data'] != null) {
          final apiData = data['data'];

          // ✅ DEBUG: Print data mentah dari API
          print('=== DEBUG API RESPONSE ===');
        print('Raw apiData: $apiData');
        print('Email dari API: "${apiData['email']}" (type: ${apiData['email'].runtimeType})');
        print('No HP dari API: "${apiData['no_hp']}" (type: ${apiData['no_hp'].runtimeType})');

          setState(() {
            pegawaiDetail = {
              'id_pegawai': _safeString(apiData['id_pegawai']) ??
                  _safeString(widget.userData['idPegawai']) ??
                  'Unknown',
              'nama': _safeString(apiData['nama']) ??
                  _safeString(widget.userData['nama']) ??
                  'Unknown',
              'nip': _safeString(apiData['nip']) ??
                  _safeString(widget.userData['nip']) ??
                  'Unknown',
              'jabatan': _safeString(apiData['jabatan']) ?? 'Tidak Diset',
              'unit_kerja': _safeString(apiData['unit_kerja']) ?? 'Tidak Diset',
              'email': apiData['email'] ?? '',
              'no_hp': apiData['no_hp'] ?? '',
              'foto': apiData['foto'],
            };
          });
          print('pegawaiDetail set: $pegawaiDetail');
          print('Email hasil: "${pegawaiDetail['email']}"');
          print('No HP hasil: "${pegawaiDetail['no_hp']}"');
        } else {
          print('API returned invalid data structure');
          _setFallbackData();
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        _setFallbackData();
      }
    } catch (e) {
      print('Exception in _getPegawaiDetail: $e');
      _setFallbackData();
    }
  }

  // Helper method untuk safely convert ke String
  String? _safeString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  Future<void> _refreshData() async {
  setState(() {
    isLoading = true;
  });
  
  await _loadData();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.refresh, color: Colors.white),
          SizedBox(width: 8),
          Text('Data berhasil diperbarui'),
        ],
      ),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}

  void _setFallbackData() {
    setState(() {
      pegawaiDetail = {
        'id_pegawai': _safeString(widget.userData['idPegawai']) ?? 'Unknown',
        'nama': _safeString(widget.userData['nama']) ?? 'Unknown',
        'nip': _safeString(widget.userData['nip']) ?? 'Unknown',
        'jabatan': _safeString(widget.userData['jabatan']) ?? 'Tidak Diset',
        'unit_kerja':
            _safeString(widget.userData['unit_kerja']) ?? 'Tidak Diset',

        // ✅ UBAH BAGIAN INI JUGA
        'email': _safeString(widget.userData['email'])?.isEmpty == true
            ? 'Belum diisi'
            : _safeString(widget.userData['email']) ?? 'Belum diisi',
        'no_hp': _safeString(widget.userData['no_hp'])?.isEmpty == true
            ? 'Belum diisi'
            : _safeString(widget.userData['no_hp']) ?? 'Belum diisi',

        'foto': widget.userData['foto'],
      };
    });
    print('Fallback data set: $pegawaiDetail');
  }

  Future<void> _showEditDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _namaController = TextEditingController(text: pegawaiDetail['nama']);
    final _emailController =
        TextEditingController(text: pegawaiDetail['email']);
    final _noHpController = TextEditingController(text: pegawaiDetail['no_hp']);
    final _passwordController = TextEditingController(); // Password baru
    final _confirmPasswordController = TextEditingController();

    bool _isPasswordVisible = false;
    bool _isConfirmPasswordVisible = false;

     await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Informasi Pribadi'),
              ],
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nama
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // No HP
                    TextFormField(
                      controller: _noHpController,
                      decoration: InputDecoration(
                        labelText: 'No. HP',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'No. HP tidak boleh kosong';
                        }
                        if (value.length < 10) {
                          return 'No. HP minimal 10 digit';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Divider untuk bagian password
                    Divider(thickness: 1),
                    Text(
                      'Ubah Password (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Password Baru
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Kosongkan jika tidak ingin mengubah',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Konfirmasi Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Konfirmasi password baru',
                      ),
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty) {
                          if (value != _passwordController.text) {
                            return 'Password tidak sama';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    await _updatePegawaiInfo(
                      _namaController.text,
                      _emailController.text,
                      _noHpController.text,
                      _passwordController.text.isNotEmpty ? _passwordController.text : null,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}


  Future<void> _updatePegawaiInfo(String nama, String email, String noHp, String? password) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Menyimpan perubahan...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Prepare request body
    final requestBody = {
      'nama': nama,
      'email': email,
      'no_hp': noHp,
    };
    
    // Tambahkan password jika diisi
    if (password != null && password.isNotEmpty) {
      requestBody['password'] = password;
    }

    final url = '$baseUrl/sipreti/pegawai/${widget.userData['idPegawai']}/';

    print('=== DEBUG UPDATE PEGAWAI ===');
    print('URL: $url');
    print('Request Body: $requestBody');

    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    Navigator.pop(context); // Tutup loading dialog

    // Cek apakah response adalah JSON
    if (response.headers['content-type']?.contains('application/json') != true) {
      throw Exception('Server mengembalikan HTML, bukan JSON. Status: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      // Update data lokal
      setState(() {
        pegawaiDetail['nama'] = nama;
        pegawaiDetail['email'] = email;
        pegawaiDetail['no_hp'] = noHp;
      });
      await _getPegawaiDetail();
  await _getDeviceInfo();

      String successMessage = 'Informasi berhasil diperbarui';
      if (password != null && password.isNotEmpty) {
        successMessage += ' (termasuk password)';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(successMessage)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Gagal memperbarui: ${data['message'] ?? 'Status ${response.statusCode}'}')
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Tutup loading dialog jika masih ada
    }

    print('Error updating pegawai info: $e');

    String errorMessage = 'Terjadi kesalahan';
    if (e.toString().contains('FormatException')) {
      errorMessage = 'Server mengembalikan format yang salah';
    } else if (e.toString().contains('SocketException')) {
      errorMessage = 'Tidak dapat terhubung ke server';
    } else if (e.toString().contains('TimeoutException')) {
      errorMessage = 'Koneksi timeout';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(errorMessage)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
      ),
    );
  }
}

  Future<void> _pickAndUploadImage() async {
    try {
      // Tampilkan dialog dengan opsi lengkap
      final String? action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Kelola Foto Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.green),
                title: Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              if (profileImageUrl != null) // Tampil opsi hapus jika ada foto
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Hapus Foto'),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
            ],
          ),
        ),
      );

      if (action != null) {
        if (action == 'delete') {
          await _deleteProfilePhoto();
        } else {
          final ImageSource source =
              action == 'camera' ? ImageSource.camera : ImageSource.gallery;

          final XFile? image = await _picker.pickImage(
            source: source,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 80,
          );

          if (image != null) {
            setState(() {
              isUploadingPhoto = true;
            });

            await _uploadProfilePhoto(image);
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProfilePhoto() async {
    try {
      // Konfirmasi hapus
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Hapus Foto Profil'),
          content: Text('Apakah Anda yakin ingin menghapus foto profil?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        setState(() {
          isUploadingPhoto = true;
        });

        final response = await http.delete(
          Uri.parse(
              '$baseUrl/sipreti/delete_profile_photo/${widget.userData['idPegawai']}/'),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['status'] == 'success') {
          setState(() {
            profileImageUrl = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Foto profil berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal hapus foto: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error hapus foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isUploadingPhoto = false;
      });
    }
  }

  Future<void> _uploadProfilePhoto(XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/sipreti/upload_profile_photo/'),
      );

      request.fields['id_pegawai'] = widget.userData['idPegawai'].toString();
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', image.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var data = json.decode(responseBody);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          profileImageUrl = data['data']['foto_url'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto profil berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: ${data['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error upload foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isUploadingPhoto = false;
      });
    }
  }

  Future<void> _logout() async {
    // Tampilkan dialog konfirmasi
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Keluar'),
          content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // Navigate ke login page dan hapus semua route sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate berdasarkan tab yang dipilih
    switch (index) {
      case 0:
        // Home - kembali ke Dashboard
        Navigator.pushReplacementNamed(context, '/dashboard',
            arguments: widget.userData);
        break;
      case 1:
        // Riwayat
        Navigator.pushNamed(context, '/riwayat', arguments: widget.userData);
        break;
      case 2:
        // Pesan
        Navigator.pushNamed(context, '/pesan', arguments: widget.userData);
        break;
      case 3:
        // Akun - sudah di halaman ini
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          'Profil Pegawai',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset('assets/pemkot_mlg.png', height: 40),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: profileImageUrl == null
                  ? Icon(Icons.person, color: Colors.blue)
                  : null,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Avatar dengan upload
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue[100],
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blue[300],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap:
                                isUploadingPhoto ? null : _pickAndUploadImage,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isUploadingPhoto
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          

                  // Informasi Pribadi Card - DENGAN TOMBOL EDIT
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween, // ✅ TAMBAH INI
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Informasi Pribadi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              // ✅ TAMBAH TOMBOL EDIT INI
                              IconButton(
                                onPressed: _showEditDialog,
                                icon: Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                                tooltip: 'Edit Informasi',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(8),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow('ID Pegawai',
                              pegawaiDetail['id_pegawai'] ?? 'Tidak Tersedia'),
                          _buildInfoRow('Nama Lengkap',
                              pegawaiDetail['nama'] ?? 'Tidak Tersedia'),
                          _buildInfoRow(
                              'NIP', pegawaiDetail['nip'] ?? 'Tidak Tersedia'),
                          _buildInfoRow('Email',
                              pegawaiDetail['email'] ?? 'Tidak Tersedia'),
                          _buildInfoRow('No. HP',
                              pegawaiDetail['no_hp'] ?? 'Tidak Tersedia'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Informasi Jabatan Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.work_outline,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Jabatan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow('Jabatan',
                              pegawaiDetail['jabatan'] ?? 'Tidak Tersedia'),
                          _buildInfoRow('Unit Kerja',
                              pegawaiDetail['unit_kerja'] ?? 'Tidak Tersedia'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Data Pengguna Android Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.android,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Perangkat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow('Device ID',
                              deviceInfo['device_id'] ?? 'Unknown'),
                          _buildInfoRow(
                              'Brand', deviceInfo['device_brand'] ?? 'Unknown'),
                          _buildInfoRow(
                              'Model', deviceInfo['device_model'] ?? 'Unknown'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Pesan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
