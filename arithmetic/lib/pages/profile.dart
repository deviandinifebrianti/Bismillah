// File: lib/widgets/profile_avatar.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileAvatar extends StatefulWidget {
  final String idPegawai;
  final String nama;
  final double radius;
  final Color borderColor;
  final VoidCallback? onTap;

  const ProfileAvatar({
    Key? key,
    required this.idPegawai,
    required this.nama,
    this.radius = 18,
    this.borderColor = Colors.white,
    this.onTap,
  }) : super(key: key);

  @override
  _ProfileAvatarState createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _getProfilePhoto();
  }

  Future<void> _getProfilePhoto() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.1.14:8000/sipreti/get_profile_photo/${widget.idPegawai}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data']['has_photo']) {
          if (mounted) {
            setState(() {
              profileImageUrl = data['data']['foto_url'];
            });
          }
        }
      }
    } catch (e) {
      print('Error getting profile photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.white,
          backgroundImage:
              profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
          child: profileImageUrl == null
              ? Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: widget.radius,
                )
              : null,
        ),
      ),
    );
  }
}
