import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kreen_app_flutter/constants.dart';

class ApiService {

  static const Map<String, String> _headers = {
    'API-Secret-Key':
        'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=',
    'Content-Type': 'application/json',
  };

  /// POST request
  static Future<Map<String, dynamic>?> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse("$baseapiUrl$endpoint");

    final response = await http.post(
      url,
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  // POST upload image
  static Future<Map<String, dynamic>?> postImage(
    String endpoint, {
    File? file,
  }) async {
    final url = Uri.parse("$baseapiUrl$endpoint");

    var request = http.MultipartRequest("POST", url);

    request.headers['API-Secret-Key'] = 'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=';

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath('files[]', file.path),
      );
    }

    final streamedResponse = await request.send();
    final respStr = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return json.decode(respStr) as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> postSetProfil(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse("$baseapiUrl$endpoint");

    var headers = {
      'Authorization': 'Bearer $token',
      'API-Secret-Key': 'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=',
      'Content-Type': 'application/json'
    };

    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }


  /// GET request
  static Future<Map<String, dynamic>?> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    Uri url = Uri.parse("$baseapiUrl$endpoint");

    // kalau ada query parameter
    if (params != null) {
      url = url.replace(queryParameters: params);
    }

    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}
