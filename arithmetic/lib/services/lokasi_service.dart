import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LokasiService {
  final String baseUrl;

  LokasiService(this.baseUrl);

  Future<double?> getRadiusMeter() async {
    final url = Uri.parse('$baseUrl/sipreti/get_radius/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.tryParse(data['ukuran'].toString());
    } else {
      print("Gagal ambil radius: ${response.body}");
      return null;
    }
  }

  Future<LatLng?> getLokasiUnitKerja() async {
    final url = Uri.parse('$baseUrl/sipreti/get_lokasi_unit_kerja/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LatLng(
        double.parse(data['latitude'].toString()),
        double.parse(data['longitude'].toString()),
      );
    } else {
      print("Gagal ambil lokasi unit kerja: ${response.body}");
      return null;
    }
  }

  double hitungJarak(LatLng posisiA, LatLng posisiB) {
    return const Distance().as(LengthUnit.Meter, posisiA, posisiB);
  }
}
