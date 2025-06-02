import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> uploadBase64Image(String base64Image, String idPegawai, String name) async {
  final url = Uri.parse('http://192.168.1.10:8000/sipreti/add_image/'); // sesuaikan URL-nya

  final response = await http.post(
    url,
    body: {
      'url_image': base64Image,
      'id_pegawai': idPegawai,
      'name': name,
    },
  );

  final result = json.decode(response.body);
  print(result);
}
