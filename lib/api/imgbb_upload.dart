import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<String?> uploadImage(String img) async {

  final url = Uri.https('api.imgbb.com', '1/upload');
  final key = dotenv.env['imgbb_apiKey'];
  const expiration = "259200"; // 3일 유효기간

  final response = await http.post(
        url,
        body: {
          'key': key,
          'image': img,
          'expiration':expiration,
        }
      );

  Map<String, dynamic> jsonResult = jsonDecode(response.body);
  final thumb = jsonResult['data']['thumb']['url'];

  return thumb;
}