import 'dart:convert';
import 'dart:io';

// http api 통신으로 이미지를 전달하기 위해 이미지 파일을 바이너리 파일로 변환
String base64Encode1(File file){
  final bytes = file.readAsBytesSync();
  String encode = base64Encode(bytes);
  return encode;
}