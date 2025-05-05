import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> uploadImage(dynamic file) async {
  final url = 'http://127.0.0.1:5000/predict';

  if (kIsWeb) {
    // Web için dosya yükleme
    final formData = html.FormData();
    formData.appendBlob(
      'image',
      file,
    ); // 'file' burada web için doğru formatta olmalı.

    final request = html.HttpRequest();
    request.open('POST', url);
    request.send(formData);

    request.onLoadEnd.listen((e) {
      if (request.status == 200) {
        print('Upload Successful');
      } else {
        print('Upload Failed');
      }
    });
  } else {
    // Mobil için dosya yükleme (dart:io kullanılır)
    var uri = Uri.parse(url);
    var request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          file!.path, // Mobilde, dosya yoluna erişebiliriz.
        ),
      );

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Upload Successful');
    } else {
      print('Upload Failed');
    }
  }
}
