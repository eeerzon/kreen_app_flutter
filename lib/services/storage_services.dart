// ignore_for_file: non_constant_identifier_names

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> setOnboardingDone() async {
    await _storage.write(key: 'hasSeenOnboarding', value: 'true');
  }

  static Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: 'hasSeenOnboarding');
    return value == 'true';
  }

  static Future<void> setLanguage(String langCode) async {
    await _storage.write(key: 'language_code', value: langCode);
  }

  static Future<String?> getLanguage() async {
    return await _storage.read(key: 'language_code');
  }

  static Future<void> setCurrency(String currencyCode) async {
    await _storage.write(key: 'currency_code', value: currencyCode);
  }

  static Future<String?> getCurrency() async {
    return await _storage.read(key: 'currency_code');
  }

  static Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  static Future<void> setUser({
    String? id,
    required String first_name,
    required String? last_name,
    required String? phone,
    required String email,
    String? gender,
    required String? photo,
    required String? DOB,
    String? verifEmail, 
    String? company,
    String? jobTitle,
    String? link_linkedin,
    String? link_ig,
    String? link_twitter,
  }) async {
    await _storage.write(key: 'user_id', value: id);
    await _storage.write(key: 'user_firstname', value: first_name);
    await _storage.write(key: 'user_lastname', value: last_name);
    await _storage.write(key: 'user_phone', value: phone);
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_gender', value: gender);
    await _storage.write(key: 'user_photo', value: photo);
    await _storage.write(key: 'user_dob', value: DOB);
    await _storage.write(key: 'user_verifEmail', value: verifEmail);
    await _storage.write(key: 'user_company', value: company);
    await _storage.write(key: 'user_jobTitle', value: jobTitle);
    await _storage.write(key: 'user_link_linkedin', value: link_linkedin);
    await _storage.write(key: 'user_link_ig', value: link_ig);
    await _storage.write(key: 'user_link_twitter', value: link_twitter);
  }

  static Future<Map<String, String?>> getUser() async {
    final id = await _storage.read(key: 'user_id');
    final first_name = await _storage.read(key: 'user_firstname');
    final last_name = await _storage.read(key: 'user_lastname');
    final phone = await _storage.read(key: 'user_phone');
    final email = await _storage.read(key: 'user_email');
    final gender = await _storage.read(key: 'user_gender');
    final photo = await _storage.read(key: 'user_photo');
    final DOB = await _storage.read(key: 'user_dob');
    final verifEmail = await _storage.read(key: 'user_verifEmail');
    final company = await _storage.read(key: 'user_company');
    final jobTitle = await _storage.read(key: 'user_jobTitle');
    final link_linkedin = await _storage.read(key: 'user_link_linkedin');
    final link_ig = await _storage.read(key: 'user_link_ig');
    final link_twitter = await _storage.read(key: 'user_link_twitter');

    return {
      'id': id,
      'first_name': first_name,
      'last_name': last_name,
      'phone': phone,
      'email': email,
      'gender': gender,
      'photo': photo,
      'dob': DOB,
      'verifEmail': verifEmail,
      'company': company,
      'jobTitle': jobTitle,
      'link_linkedin': link_linkedin,
      'link_ig': link_ig,
      'link_twitter': link_twitter,
    };
  }

  static Future<void> clearUser() async {
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_firstname');
    await _storage.delete(key: 'user_lastname');
    await _storage.delete(key: 'user_phone');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_gender');
    await _storage.delete(key: 'user_photo');
    await _storage.delete(key: 'user_dob');
    await _storage.delete(key: 'user_verifEmail');
    await _storage.delete(key: 'user_company');
    await _storage.delete(key: 'user_jobTitle');
    await _storage.delete(key: 'user_link_linkedin');
    await _storage.delete(key: 'user_link_ig');
    await _storage.delete(key: 'user_link_twitter');
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> setLoginMethod(String method) async {
    await _storage.write(key: 'login_method', value: method);
  }

  static Future<String?> getLoginMethod() async {
    return await _storage.read(key: 'login_method');
  }

  static Future<void> clearLoginMethod() async {
    await _storage.delete(key: 'login_method');
  }

  static Future<void> setGuestMode(bool value) async {
    await _storage.write(key: 'isGuest', value: value ? '1' : '0');
  }

  static Future<bool> isGuestMode() async {
    final v = await _storage.read(key: 'isGuest');
    return v == '1';
  }

  static Future<void> setIsChoosed(int isChoosed) async {
    await _storage.write(key: 'isChoosed', value: isChoosed.toString());
  }

  static Future<int?> getIsChoosed() async {
    final value = await _storage.read(key: 'isChoosed');
    return value != null ? int.tryParse(value) : null;
  }
}
