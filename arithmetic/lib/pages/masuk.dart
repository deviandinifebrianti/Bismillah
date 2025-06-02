import 'package:flutter/material.dart';
import 'package:absensi/pages/daftar.dart';

class MasukPage extends StatelessWidget {
  const MasukPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String nip = ""; // Variabel untuk menyimpan NIP

    return Scaffold(
      body: Stack(
        children: [
          
          Container(
            decoration: BoxDecoration(
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
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/pemkot_mlg.png'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Konten Utama
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Akun Baru',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField('Masukkan NIP', (value) {
                        nip = value; // Simpan nilai NIP saat diinput
                      }),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (nip.isEmpty) {
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Harap isi NIP!')),
                              );
                            } else if (int.tryParse(nip) == null) {
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('NIP harus berupa angka!')),
                              );
                            } else {
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DaftarPage()),
                              );
                            }
                          },
                          child: const Text(
                            'LOAD NIP',
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

  Widget _buildTextField(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        keyboardType: TextInputType.number, 
        onChanged: onChanged, // Panggil fungsi saat input berubah
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}