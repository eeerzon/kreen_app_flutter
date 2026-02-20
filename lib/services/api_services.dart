import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';

class ApiService {

  // static const Map<String, String> _headers = {
  //   'API-Secret-Key':
  //       'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=',
  //   'Content-Type': 'application/json',
  // };

  /// POST request
  static Future<Map<String, dynamic>?> post(
    String endpoint, 
    {
      Map<String, dynamic>? body,
      String? xLanguage,
      String? xCurrency,
      String? token
    }
  ) async {
    final bahasa = await LangService.getJsonData(xLanguage!, 'bahasa');

    Map<String, String> headers = {
      'API-Secret-Key':
          'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'x-language': xLanguage,
      'x-currency': ?xCurrency,
    };
    final url = Uri.parse("$baseapiUrl$endpoint");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final body = json.decode(response.body);

        return {
          "rc": response.statusCode,
          "success": false,
          "message": body['message'] ?? "Server error (${response.statusCode})",
          "data": body['data'] ?? []
        };
      }
    } on TimeoutException {
      return {
        "rc": 408,
        "status": false,
        "message": bahasa['timeout'],
        "data": []
      };
    } on SocketException {
      return {
        "rc": 503,
        "status": false,
        "message": bahasa['no_internet'],
        "data": []
      };
    } catch (e) {
      return {
        "rc": 500,
        "status": false,
        "message": bahasa['error'],
        "data": []
      };
    }
  }

  // POST upload image
  static Future<Map<String, dynamic>?> postImage(
    String endpoint, 
    {
      File? file,
      String? xLanguage,
    }
  ) async {
    final bahasa = await LangService.getJsonData(xLanguage!, 'bahasa');

    final url = Uri.parse("$baseapiUrl$endpoint");

    var request = http.MultipartRequest("POST", url);

    request.headers['API-Secret-Key'] = 'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=';

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath('files[]', file.path),
      );
    }

    try {
      final streamedResponse = await request.send();
      final respStr = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        return json.decode(respStr) as Map<String, dynamic>;
      } else {
        return {
          "rc": streamedResponse.statusCode,
          "status": false,
          "message": "Server error (${streamedResponse.statusCode})",
          "data": []
        };
      }
    } on TimeoutException {
      return {
        "rc": 408,
        "status": false,
        "message": bahasa['timeout'],
        "data": []
      };
    } on SocketException {
      return {
        "rc": 503,
        "status": false,
        "message": bahasa['no_internet'],
        "data": []
      };
    } catch (e) {
      return {
        "rc": 500,
        "status": false,
        "message": bahasa['error'],
        "data": []
      };
    }
  }

  static Future<Map<String, dynamic>?> postSetProfil(
    String endpoint, 
    {
      String? token,
      Map<String, dynamic>? body,
      String? xLanguage,
    }
  ) async {
    final bahasa = await LangService.getJsonData(xLanguage!, 'bahasa');

    final url = Uri.parse(endpoint);

    var headers = {
      'Authorization': 'Bearer $token',
      'API-Secret-Key': 'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=',
      'Content-Type': 'application/json'
    };

    try {
      final response = await http
        .post(url, headers: headers, body: json.encode(body))
        .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final body = json.decode(response.body);

        return {
          "rc": response.statusCode,
          "success": false,
          "message": body['message'] ?? "Server error (${response.statusCode})",
          "data": body['data'] ?? []
        };
      }
    } on TimeoutException {
      return {
        "rc": 408,
        "status": false,
        "message": bahasa['timeout'],
        "data": []
      };
    } on SocketException {
      return {
        "rc": 503,
        "status": false,
        "message": bahasa['no_internet'],
        "data": []
      };
    } catch (e) {
      return {
        "rc": 500,
        "status": false,
        "message": bahasa['error'],
        "data": []
      };
    }
  }


  /// GET request
  static Future<Map<String, dynamic>?> get(
    String endpoint, 
    {
      Map<String, String>? params,
      String? xLanguage,
      String? xCurrency,
    }
  ) async {
    final bahasa = await LangService.getJsonData(xLanguage!, 'bahasa');

    Map<String, String> headers = {
      'API-Secret-Key':
          'eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=',
      'Content-Type': 'application/json',
      'x-language': xLanguage,
      'x-currency': ?xCurrency,
    };

    Uri url = Uri.parse("$baseapiUrl$endpoint");

    // kalau ada query parameter
    if (params != null) {
      url = url.replace(queryParameters: params);
    }

    try {
      final response = await http
        .get(url, headers: headers)
        .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final body = json.decode(response.body);

        return {
          "rc": response.statusCode,
          "success": false,
          "message": body['message'] ?? "Server error (${response.statusCode})",
          "data": body['data'] ?? []
        };
      }
    } on TimeoutException {
      return {
        "rc": 408,
        "status": false,
        "message": bahasa['timeout'],
        "data": []
      };
    } on SocketException {
      return {
        "rc": 503,
        "status": false,
        "message": bahasa['no_internet'],
        "data": []
      };
    } catch (e) {
      return {
        "rc": 500,
        "status": false,
        "message": bahasa['error'],
        "data": []
      };
    }
  }
}
