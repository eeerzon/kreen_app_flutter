import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';

class ApiService {
  
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
          apiSecretKey,
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

      return json.decode(response.body) as Map<String, dynamic>;

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

    request.headers['API-Secret-Key'] = apiSecretKey;

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath('files[]', file.path),
      );
    }

    try {
      final streamedResponse = await request.send();
      final respStr = await streamedResponse.stream.bytesToString();
      
      return json.decode(respStr) as Map<String, dynamic>;

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
      'API-Secret-Key': apiSecretKey,
      'Content-Type': 'application/json'
    };

    try {
      final response = await http
        .post(url, headers: headers, body: json.encode(body))
        .timeout(Duration(seconds: 22));
        
      return json.decode(response.body) as Map<String, dynamic>;
      
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
  
  static Future<Map<String, dynamic>?> get(
    String endpoint, 
    {
      Map<String, String>? params,
      String? xLanguage,
      String? xCurrency,
      String? token
    }
  ) async {
    final bahasa = await LangService.getJsonData(xLanguage!, 'bahasa');

    Map<String, String> headers = {
      'API-Secret-Key':
          apiSecretKey,
      'Content-Type': 'application/json',
      'x-language': xLanguage,
      'x-currency': ?xCurrency,
      'Authorization': 'Bearer $token',
    };

    String? editedUrl;
    if (baseapiUrl.contains('https://bc.kreenconnect.com')) {
      editedUrl = 'https://kreenconnect.com/kreenapi';
    } else {
      editedUrl = baseapiUrl;
    }
    // Uri url = Uri.parse("$baseapiUrl$endpoint");
    Uri url = Uri.parse("$editedUrl$endpoint");
    
    if (params != null) {
      url = url.replace(queryParameters: params);
    }

    try {
      final response = await http
        .get(url, headers: headers)
        .timeout(Duration(seconds: 15));
        
      return json.decode(response.body) as Map<String, dynamic>;

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

  static Future<Map<String, dynamic>?> getLoginUser(
    String endpoint, 
    {
      String? token,
      String? xLanguage,
    }
  ) async {
    final bahasa = await LangService.getJsonData(xLanguage!, 'bahasa');

    final url = Uri.parse("$baseapiUrl$endpoint");

    var headers = {
      'Authorization': 'Bearer $token',
      'API-Secret-Key': apiSecretKey,
      'Content-Type': 'application/json'
    };

    try {
      final response = await http
        .get(url, headers: headers)
        .timeout(Duration(seconds: 15));
        
      return json.decode(response.body) as Map<String, dynamic>;

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

  static Future<Map<String, dynamic>?> patch(
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
          apiSecretKey,
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'x-language': xLanguage,
      'x-currency': ?xCurrency,
    };

    final url = Uri.parse("$baseapiUrl$endpoint");

    try {
      final response = await http
        .patch(url, headers: headers, body: json.encode(body))
        .timeout(Duration(seconds: 15));
        
      return json.decode(response.body) as Map<String, dynamic>;
      
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
