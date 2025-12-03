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
    required String last_name,
    required String phone,
    required String email,
    String? gender,
    required String photo,
    required String DOB
  }) async {
    await _storage.write(key: 'user_id', value: id);
    await _storage.write(key: 'user_firstname', value: first_name);
    await _storage.write(key: 'user_lastname', value: last_name);
    await _storage.write(key: 'user_phone', value: phone);
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_gender', value: gender);
    await _storage.write(key: 'user_photo', value: photo);
    await _storage.write(key: 'user_dob', value: DOB);
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

    return {
      'id': id,
      'first_name': first_name,
      'last_name': last_name,
      'phone': phone,
      'email': email,
      'gender': gender,
      'photo': photo,
      'dob': DOB
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
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
