import 'package:flutter/material.dart';

class CheckOutDinasPage extends StatelessWidget {
  const CheckOutDinasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check Out',
          style: TextStyle(color: Colors.white),
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
          // Tambahkan logo di samping kanan header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset(
              'assets/pemkot_mlg.png', // Ganti dengan path logo Anda
              height: 40, // Atur tinggi logo sesuai kebutuhan
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/profil.png', // Ganti dengan path logo kedua
              height: 40, // Atur tinggi logo
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: double.infinity, // Mengisi lebar layar
                height: 250, // Atur tinggi sesuai kebutuhan
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/profil.png'), // Ganti dengan path foto Anda
                    fit: BoxFit.cover, // Mengisi area dengan proporsional
                  ),
                ),
              ),
            ),

            // Informasi Absensi
            const SizedBox(height: 20),
            const Text(
              'Absensi Reguler',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: const [
                Icon(Icons.calendar_today, size: 20), // Ikon kalender
                SizedBox(width: 8), // Jarak antara ikon dan teks
                Text(
                  'Kamis, 02 Januari 2025',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: const [
                Icon(Icons.access_time, size: 20), // Ikon jam
                SizedBox(width: 8), // Jarak antara ikon dan teks
                Text(
                  '17.23 WIB',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.location_on, size: 20), // Ikon alamat
                SizedBox(width: 8), // Jarak antara ikon dan teks
                Expanded(
                  // Agar teks bisa membungkus dengan baik
                  child: Text(
                    'KANTOR WALIKOTA MALANG, \nJalan Majapahit, RW. 08, KEL. KIDUL DALEM, \nKOTA MALANG, Bareng, Malang, \nJawa Timur, 65119, Indonesia',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: const [
                Icon(Icons.emoji_emotions,
                    size: 20, color: Colors.green), // Ikon tersenyum
                SizedBox(width: 8), // Jarak antara ikon dan teks
                Text(
                  'Data Valid',
                  style: TextStyle(fontSize: 20, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol Aksi
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text(
                      'FOTO ULANG',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: const Color.fromARGB(255, 79, 152, 236),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text(
                      'DOKUMEN PENDUKUNG',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.green, width: 2),
                      foregroundColor: const Color.fromARGB(255, 48, 189, 67),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text(
                      'SELESAI CHECK OUT',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text(
                      'BATAL CHECK OUT',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color.fromARGB(255, 146, 25, 16),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
