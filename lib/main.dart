import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_button/animated_button.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.green,
      ),
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            "Leaforia",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green[700],
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {},
              color: Colors.white,
            ),
          ],
        ),
        body: UploadImagePage(),
      ),
    );
  }
}

class UploadImagePage extends StatefulWidget {
  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  html.File? _selectedFile;
  String _prediction = "";

  void _selectImage() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files!.isEmpty) return;

      setState(() {
        _selectedFile = files[0];
      });
    });
  }

  Future<void> _uploadImage() async {
    if (_selectedFile == null) {
      print("No file selected.");
      return;
    }

    final url = 'http://127.0.0.1:5000/predict';
    setState(() {
      _prediction = "";
    });

    if (kIsWeb) {
      final formData = html.FormData();
      formData.appendBlob('image', _selectedFile!);

      final request = html.HttpRequest();
      request.open('POST', url);
      request.send(formData);

      request.onLoadEnd.listen((e) {
        if (request.status == 200) {
          print('Upload Successful');
          setState(() {
            _prediction = _getHighestPrediction(request.responseText ?? '{}');
          });
        } else {
          print('Upload Failed: ${request.status} ${request.statusText}');
          print('Response: ${request.responseText}');
        }
      });
    } else {
      var uri = Uri.parse(url);
      var request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath('image', _selectedFile!.name),
        );

      var response = await request.send();

      if (response.statusCode == 200) {
        print('Upload Successful');
        response.stream.listen((value) {
          setState(() {
            _prediction = _getHighestPrediction(String.fromCharCodes(value));
          });
        });
      } else {
        print('Upload Failed: ${response.statusCode}');
      }
    }
  }

  String _getHighestPrediction(String responseText) {
    try {
      final Map<String, dynamic> data = json.decode(responseText);
      final probabilities = data['probabilities'] as Map<String, dynamic>;

      String highestClass = '';
      double highestAccuracy = 0.0;

      const validClasses = [
        'Corn___Cercospora_leaf_spot',
        'Gray_leaf_spot',
        'Corn___Common_rust',
        'Corn___healthy',
        'Corn___Northern_Leaf_Blight',
      ];

      probabilities.forEach((key, value) {
        if (validClasses.contains(key) &&
            value is double &&
            value > highestAccuracy) {
          highestAccuracy = value;
          highestClass = key;
        }
      });

      if (highestClass.isEmpty) {
        return 'No valid disease detected.';
      }

      return 'Hastalık adı: $highestClass / Olasılık: $highestAccuracy';
    } catch (e) {
      print('Error parsing response: $e');
      return 'Error parsing response';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔁 Lottie animasyonu arka plan
        Positioned.fill(
          child: Lottie.asset(
            'assets/arkaplan.json',
            fit: BoxFit.cover,
            repeat: true,
          ),
        ),

        // İçerik kutusu
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Leaforia",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 30),

                  AnimatedButton(
                    onPressed: _selectImage,
                    child: Text("Resim Seç"),
                    height: 50,
                    width: 200,
                    color: Colors.green[700]!,
                    borderRadius: 16,
                    shadowDegree: ShadowDegree.dark,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      "Seçilen dosya: ${_selectedFile!.name}",
                      style: TextStyle(color: Colors.green[900]),
                    ),
                  ],
                  const SizedBox(height: 20),

                  AnimatedButton(
                    onPressed: _uploadImage,
                    child: Text("Yükle"),
                    height: 50,
                    width: 200,
                    color: Colors.teal[700]!,
                    borderRadius: 16,
                    shadowDegree: ShadowDegree.dark,
                  ),
                  if (_prediction.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    Text(
                      "Tahmin: $_prediction",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],

                  // Gelecekteki özellikler için butonlar
                  const SizedBox(height: 30),
                  AnimatedButton(
                    onPressed: () {
                      // Hava durumu butonuna tıklandığında yapılacak işlem
                    },
                    child: Text("Hava Durumu"),
                    height: 50,
                    width: 200,
                    color: Colors.blue[700]!,
                    borderRadius: 16,
                    shadowDegree: ShadowDegree.dark,
                  ),
                  const SizedBox(height: 20),
                  AnimatedButton(
                    onPressed: () {
                      // Bitki bilgileri butonuna tıklandığında yapılacak işlem
                    },
                    child: Text("Bitki Bilgileri"),
                    height: 50,
                    width: 200,
                    color: Colors.orange[700]!,
                    borderRadius: 16,
                    shadowDegree: ShadowDegree.dark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
