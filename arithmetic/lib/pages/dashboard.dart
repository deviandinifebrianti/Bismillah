import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lokasi.dart';
import 'package:intl/intl.dart';
import 'package:absensi/pages/starter.dart';
import 'package:absensi/pages/akun.dart';
import 'package:absensi/pages/profile.dart';
import 'dart:async';

const String baseUrl = "http://192.168.1.14:8000";

class DashboardPage extends StatefulWidget {
  final String idPegawai;
  final String nama;
  final String nip;
  final int jenis;
  final int checkMode;
  final DateTime? waktuAbsensi;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String idUnitKerja;
  final String lokasi;
  final String latitude;
  final String longitude;
  final bool shouldRefreshAttendance;

  const DashboardPage({
    Key? key,
    required this.idPegawai,
    required this.nama,
    required this.nip,
    required this.jenis,
    required this.checkMode,
    required this.idUnitKerja,
    required this.lokasi,
    required this.latitude,
    required this.longitude,
    this.waktuAbsensi,
    this.checkInTime,
    this.checkOutTime,
    this.shouldRefreshAttendance = false,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String checkInTime = '-';
  String checkOutTime = '-';
  String jabatan = '';
  String bagian = '';
  bool isLoading = true;

  DateTime? lastCheckInTime;
  DateTime? lastCheckOutTime;
  DateTime? todayCheckInTime;
  DateTime? todayCheckOutTime;
  bool isLoadingAttendance = true;

  @override
  void initState() {
    super.initState();
    print('checkMode: ${widget.checkMode}');
    print('jenis: ${widget.jenis}');

    if (widget.shouldRefreshAttendance) {
      print('🔄 Dashboard: shouldRefreshAttendance = true, will refresh data');
    }

    fetchDataClean();
  }

  Future<void> fetchDataClean() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('🔄 Loading dashboard data...');

      // HANYA 2 FUNGSI YANG DIPERLUKAN
      await Future.wait([
        _fetchLastAttendanceData(), // Data absensi
        fetchJabatanUnitKerja(), // Data jabatan & unit kerja LANGSUNG dari tabel pegawai
      ]);

      print('✅ Dashboard data loaded successfully');
    } catch (e) {
      print('❌ Error fetching dashboard data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchLastAttendanceData() async {
    try {
      setState(() {
        isLoadingAttendance = true;
      });

      print('📡 Fetching TODAY\'S LATEST attendance for: ${widget.idPegawai}');

      final response = await http.get(
        Uri.parse('$baseUrl/sipreti/get_attendance/${widget.idPegawai}/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          print('📊 Today\'s latest attendance: $data');

          setState(() {
            // AMBIL ABSENSI HARI INI YANG TERBARU
            if (data['today_check_in'] != null) {
              todayCheckInTime = DateTime.parse(data['today_check_in']);
              lastCheckInTime = todayCheckInTime;
              checkInTime = todayCheckInTime!.toIso8601String();
              print('✅ Today\'s latest check-in: $todayCheckInTime');
            } else {
              todayCheckInTime = null;
              lastCheckInTime = null;
              checkInTime = '-';
              print('❌ No check-in today');
            }

            if (data['today_check_out'] != null) {
              todayCheckOutTime = DateTime.parse(data['today_check_out']);
              lastCheckOutTime = todayCheckOutTime;
              checkOutTime = todayCheckOutTime!.toIso8601String();
              print('✅ Today\'s latest check-out: $todayCheckOutTime');
            } else {
              todayCheckOutTime = null;
              lastCheckOutTime = null;
              checkOutTime = '-';
              print('❌ No check-out today');
            }

            isLoadingAttendance = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Server error');
        }
      } else {
        // PERBAIKAN: Tidak fallback ke method lama, langsung set default
        print(
            '❌ Endpoint get_attendance tidak tersedia: ${response.statusCode}');
        setState(() {
          todayCheckInTime = null;
          lastCheckInTime = null;
          todayCheckOutTime = null;
          lastCheckOutTime = null;
          checkInTime = '-';
          checkOutTime = '-';
          isLoadingAttendance = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching attendance data: $e');

      // PERBAIKAN: Tidak fallback, langsung set default
      setState(() {
        todayCheckInTime = null;
        lastCheckInTime = null;
        todayCheckOutTime = null;
        lastCheckOutTime = null;
        checkInTime = '-';
        checkOutTime = '-';
        isLoadingAttendance = false;
      });
    }
  }

  // TAMBAH: Method untuk manual refresh dengan feedback
  Future<void> _manualRefresh() async {
    print('🔄 Manual refresh triggered by user');

    try {
      // Refresh hanya data attendance
      await _fetchLastAttendanceData();

      // Tampilkan feedback sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data absensi berhasil diperbarui'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Manual refresh error: $e');

      // Tampilkan feedback error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Gagal memperbarui data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  // Method untuk mendapatkan status absensi hari ini
  Color _getAttendanceStatusColor() {
    bool hasCheckInToday = todayCheckInTime != null;
    bool hasCheckOutToday = todayCheckOutTime != null;

    if (hasCheckInToday && hasCheckOutToday) {
      return Colors.green;
    } else if (hasCheckInToday) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getAttendanceStatusText() {
    bool hasCheckInToday = todayCheckInTime != null;
    bool hasCheckOutToday = todayCheckOutTime != null;

    if (hasCheckInToday && hasCheckOutToday) {
      return '✅ Absensi Hari Ini Lengkap';
    } else if (hasCheckInToday) {
      return '⏰ Sudah Check-In, Belum Check-Out';
    } else {
      return '❌ Belum Melakukan Absensi Hari Ini';
    }
  }

  Future<void> fetchJabatanUnitKerja() async {
    try {
      print('=== FETCH JABATAN & UNIT KERJA DARI RELASI PEGAWAI ===');
      print('ID Pegawai: ${widget.idPegawai}');

      final response = await http.get(
        Uri.parse('$baseUrl/sipreti/login/${widget.idPegawai}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Parsed data: $data');

        setState(() {
          // AMAN: Gunakan ?? untuk fallback ke string kosong
          String tempJabatan = data['nama_jabatan']?.toString() ??
              data['jabatan']?.toString() ??
              data['jabatan_name']?.toString() ??
              '';

          String tempUnitKerja = data['nama_unit_kerja']?.toString() ??
              data['unit_kerja']?.toString() ??
              data['unit_kerja_name']?.toString() ??
              '';

          // SET HANYA JIKA TIDAK KOSONG
          if (tempJabatan.isNotEmpty) {
            jabatan = tempJabatan;
            print('✅ Jabatan dari JOIN: $jabatan');
          } else {
            // Coba fetch manual berdasarkan ID
            String tempIdJabatan = data['id_jabatan']?.toString() ?? '';
            if (tempIdJabatan.isNotEmpty) {
              print('🔍 Will fetch jabatan by ID: $tempIdJabatan');
              _fetchJabatanById(tempIdJabatan);
            }
          }

          if (tempUnitKerja.isNotEmpty) {
            bagian = tempUnitKerja;
            print('✅ Unit kerja dari JOIN: $bagian');
          } else {
            // Coba fetch manual berdasarkan ID
            String tempIdUnitKerja =
                data['id_unit_kerja']?.toString() ?? widget.idUnitKerja ?? '';
            if (tempIdUnitKerja.isNotEmpty) {
              print('🔍 Will fetch unit kerja by ID: $tempIdUnitKerja');
              _fetchUnitKerjaById(tempIdUnitKerja);
            }
          }
        });

        print('📊 Result after login endpoint:');
        print('   - jabatan: "$jabatan"');
        print('   - bagian: "$bagian"');
      } else {
        print('❌ Login endpoint failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching from pegawai: $e');
    }
  }

  Future<void> _fetchJabatanById(String idJabatan) async {
    try {
      print('🔍 Fetching jabatan by ID: $idJabatan');

      final response = await http.get(
        Uri.parse('$baseUrl/sipreti/jabatan/$idJabatan/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Jabatan response: $data');

        // AMAN: Fallback ke string kosong
        String tempJabatan = data['nama_jabatan']?.toString() ??
            data['jabatan']?.toString() ??
            data['name']?.toString() ??
            '';

        if (tempJabatan.isNotEmpty) {
          setState(() {
            jabatan = tempJabatan; // ✅ AMAN: String ke String
          });
          print('✅ Jabatan berhasil diambil: $jabatan');
        }
      }
    } catch (e) {
      print('❌ Error fetching jabatan by ID: $e');
    }
  }

  Future<void> _fetchUnitKerjaById(String idUnitKerja) async {
    try {
      print('🔍 Fetching unit kerja by ID: $idUnitKerja');

      final response = await http.get(
        Uri.parse('$baseUrl/sipreti/unit_kerja/$idUnitKerja/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Unit kerja response: $data');

        String tempUnitKerja = '';

        if (data is List) {
          // Cari dalam array
          for (var unit in data) {
            if (unit['id_unit_kerja']?.toString() == idUnitKerja) {
              tempUnitKerja = unit['nama_unit_kerja']?.toString() ?? '';
              break;
            }
          }
        } else if (data is Map) {
          // Ambil dari object
          tempUnitKerja = data['nama_unit_kerja']?.toString() ??
              data['unit_kerja']?.toString() ??
              data['name']?.toString() ??
              '';
        }

        if (tempUnitKerja.isNotEmpty) {
          setState(() {
            bagian = tempUnitKerja; // ✅ AMAN: String ke String
          });
          print('✅ Unit kerja berhasil diambil: $bagian');
        } else {
          print('⚠️ Unit kerja tidak ditemukan untuk ID: $idUnitKerja');
        }
      }
    } catch (e) {
      print('❌ Error fetching unit kerja by ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Online',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset('assets/pemkot_mlg.png', height: 40),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Blue Header Background
                Container(
                  color: Color(0xFF2196F3),
                  height: 230,
                  width: double.infinity,
                  child: _buildProfileSection(),
                ),
                // White Card Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildMainContent(),
                  ),
                ),
                _buildBottomNavigationBar(),
              ],
            ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProfileAvatar(
            idPegawai: widget.idPegawai,
            nama: widget.nama,
            radius: 70, // Perbesar dari 18 ke 35
            borderColor: Colors.transparent, // Hilangkan border
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Halo ${widget.nama}!')),
              );
            },
          ),
          SizedBox(height: 8),
          Text(
            widget.nama.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          // NIP
          Text(
            'NIP. ${widget.nip}',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),

          if (bagian.isNotEmpty &&
              bagian != 'Error memuat unit kerja' &&
              bagian != 'Unit kerja tidak tersedia' &&
              bagian != 'Kantor Walikota Malang') // Bukan default
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                bagian,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // JABATAN - HANYA TAMPILKAN JIKA ADA DATA DARI API
          if (jabatan.isNotEmpty &&
              jabatan != 'Error memuat jabatan' &&
              jabatan != 'Jabatan tidak tersedia' &&
              jabatan != 'Pegawai Negeri Sipil' && // Bukan default
              jabatan != 'Pegawai Honorer' &&
              jabatan != 'Pegawai Kontrak' &&
              jabatan != 'Staff')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                jabatan,
                style: TextStyle(
                  color: Colors.yellow[300],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Loading indicator HANYA jika sedang loading
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white60),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Memuat data...',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEnhancedAttendanceCard(),

          SizedBox(height: 16),

          // Reports and User Data
          Row(
            children: [
              Expanded(
                child: _buildSquareButton('Laporan', Icons.description),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSquareButton('Data Pegawai', Icons.person),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAttendanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Absensi Hari Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                // ENHANCED: Tombol refresh yang lebih jelas
                if (isLoadingAttendance)
                  Container(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _manualRefresh,
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
              ],
            ),

            SizedBox(height: 20),
            // Check In/Out Times - HARI INI YANG TERBARU
            Row(
              children: [
                // CHECK IN SECTION
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.login, color: Colors.green[600], size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Check In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        if (isLoadingAttendance)
                          Text('Loading...', style: TextStyle(fontSize: 12))
                        else ...[
                          Text(
                            _formatTime(todayCheckInTime),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: todayCheckInTime != null
                                  ? Colors.green[700]
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            todayCheckInTime != null
                                ? _formatDate(todayCheckInTime)
                                : 'Hari ini',
                            style: TextStyle(
                              fontSize: 10,
                              color: todayCheckInTime != null
                                  ? Colors.green[600]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // CHECK OUT SECTION
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.logout, color: Colors.orange[600], size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Check Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        if (isLoadingAttendance)
                          Text('Loading...', style: TextStyle(fontSize: 12))
                        else ...[
                          Text(
                            _formatTime(todayCheckOutTime),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: todayCheckOutTime != null
                                  ? Colors.orange[700]
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            todayCheckOutTime != null
                                ? _formatDate(todayCheckOutTime)
                                : 'Hari ini',
                            style: TextStyle(
                              fontSize: 10,
                              color: todayCheckOutTime != null
                                  ? Colors.orange[600]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // STATUS SECTION
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getAttendanceStatusColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getAttendanceStatusText(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Action Buttons dengan auto-refresh setelah absensi
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LokasiPage(
                            idPegawai: widget.idPegawai,
                            jenis: widget.jenis,
                            checkMode: 0,
                            nama: widget.nama,
                            nip: widget.nip,
                            idUnitKerja: widget.idUnitKerja,
                            lokasi: widget.lokasi,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                          ),
                        ),
                      );
                      // AUTO REFRESH setelah absensi
                      if (result != null) {
                        print('🔄 Auto refresh after check-in');
                        await _fetchLastAttendanceData();
                      }
                    },
                    icon: Icon(Icons.login, color: Colors.white, size: 20),
                    label:
                        Text('Check In', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LokasiPage(
                            idPegawai: widget.idPegawai,
                            jenis: widget.jenis,
                            checkMode: 1,
                            nama: widget.nama,
                            nip: widget.nip,
                            idUnitKerja: widget.idUnitKerja,
                            lokasi: widget.lokasi,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                          ),
                        ),
                      );
                      // AUTO REFRESH setelah absensi
                      if (result != null) {
                        print('🔄 Auto refresh after check-out');
                        await _fetchLastAttendanceData();
                      }
                    },
                    icon: Icon(Icons.logout, color: Colors.white, size: 20),
                    label: Text('Check Out',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),

            Divider(height: 24),

            // Index Presensi
            Text('Index Presensi Januari',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPercentageIndicator('Kehadiran', 100, Colors.blue),
                _buildPercentageIndicator('Sakit', 0, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageIndicator(String label, int percentage, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSquareButton(String title, IconData icon) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(0xFF2196F3), size: 28),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        final userData = {
          'idPegawai': widget.idPegawai,
          'nama': widget.nama,
          'nip': widget.nip,
          'jenis': widget.jenis.toString(),
          'idUnitKerja': widget.idUnitKerja,
          'lokasi': widget.lokasi,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'checkMode': widget.checkMode.toString(),
        };

        switch (index) {
          case 0:
            break; // Home
          case 1:
            Navigator.pushNamed(context, '/riwayat', arguments: userData);
            break;
          case 2:
            Navigator.pushNamed(context, '/pesan', arguments: userData);
            break;
          case 3:
            Navigator.pushNamed(context, '/akun', arguments: userData);
            break;
        }
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Pesan'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
      ],
    );
  }
}
