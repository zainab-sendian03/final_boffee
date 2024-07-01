import 'dart:io';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Crud {
  getrequest(String Url) async {
    try {
      var response = await http.get(Uri.parse(Url));
      if (response.statusCode == 200) {
        var responsebody = jsonDecode(response.body);
        return responsebody;
      } else {
        print("Erorr ${response.statusCode}");
      }
    } catch (e) {
      print("Error catch $e");
    }
  }

  Future<dynamic> postrequest(String Url, Map data) async {
    try {
      var response = await http.post(
        Uri.parse(Url),
        body: data,
      );
      if (response.statusCode == 200) {
        var responsebody = jsonDecode(response.body);
        if (responsebody['data'] != null &&
            responsebody['data']['token'] != null) {
          String token = responsebody['data']['token'];
          print("the token is $token");
          print(response.body);
          return responsebody;
        } else {
          print("Error: Token not found in response");
          return 'Token not found';
        }
      } else {
        print("Error ${response.statusCode}");
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      print("Error catch $e");
      return 'Error catch $e';
    }
  }

  postRequestwithFile(String Url, Map data, File file) async {
    var request = http.MultipartRequest("POST", Uri.parse(Url));

    var lenght = await file.length();
    var stream = http.ByteStream(file.openRead());
    var multipartFile = http.MultipartFile("file", stream, lenght,
        filename: basename(file.path));
    request.files.add(multipartFile);
    data.forEach((key, value) {
      request.fields[key] = value;
    });
    var myreq = await request.send();
    var response = await http.Response.fromStream(myreq);
    if (response.statusCode == 200) {
      var responsebody = jsonDecode(response.body);
      return responsebody;
    } else {
      print("Erorr ${response.statusCode}");
    }
  }
}