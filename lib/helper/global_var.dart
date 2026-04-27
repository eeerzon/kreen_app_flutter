// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// padding global
const EdgeInsets kGlobalPadding = EdgeInsets.all(20);

const String baseUrl = "https://dev.kreenconnect.com"; //dev
// const String baseUrl = "https://kreenconnect.com"; //prod
// const String baseUrl = "https://bc.kreenconnect.com"; //semiprod

const String baseapiUrl = "$baseUrl/kreenapi";

const String STRIPE_PUBLIC_KEY_PRODUCTION = "pk_live_51PqeNlL6LohooVUu0QrXYjrfhmEDj7WZuzm4EF6FeTGUmErLKRXoGU2UUr0GvrYUFONNGm6jtRr0e0adYXL4guXX00A4ft7WN1";
const String STRIPE_PUBLIC_KEY_SANDBOX = "pk_test_51PqeNlL6LohooVUuQ3XETGCDPNsYsMG7CEt1wBLeUSslqxjKyTcTFxQ3Ue5ysqCfZLsiGnP2e6Q9Y8hsydwAoixS00m5Q7OvmP";

const String formatDateEn = "MMM d, yyyy";
const String formatDateId = "dd MMM yyyy";
const String formatDay = "EEEE";

bool isValidEmail(String email) {
  final regex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@([a-zA-Z0-9-]+\.)+([a-zA-Z]{3,}|[a-zA-Z]{2}\.[a-zA-Z]{2,})$'
  );
  return regex.hasMatch(email);
}

bool isValidPhone(String phone) {
  final regex = RegExp(r'^[0-9]{7,15}$');
  return regex.hasMatch(phone);
}

bool isValidPhoneIDR(String phone) {
  final regex = RegExp(r'^08[0-9]{7,15}$');
  return regex.hasMatch(phone);
}

// String? currencyCode = 'IDR';
String? userCurrency = 'IDR'; // preference user
String? lastCurrency;

int isChoosed = 1; // 0 = belum pilih, 1 = sudah pilih

DateTime parseWib(String value) {
  // Ubah ke ISO +07:00 agar Flutter tahu ini WIB
  return DateTime.parse(
    '${value.replaceAll(' ', 'T')}+07:00',
  );
}

String formatHtmlContent(String? text) {
  if (text == null) return "";
  return text
      .replaceAll('\r\n', '<br>')
      .replaceAll('\n\n', '<br><br>')
      .replaceAll('\n', '<br>');
}

bool paymentExpired = false;

ValueNotifier<bool> orderNeedRefresh = ValueNotifier(false);

ValueNotifier<String> langNotifier = ValueNotifier('id');

final Map<String, String> languages = {
  "id": "Indonesia",
  "en": "English",
};

final Map<String, String> currencies = {
  "EUR": "Euro",
  "IDR": "Indonesian Rupiah",
  "MYR": "Malaysian Ringgit",
  "PHP": "Philippine Peso",
  "SGD": "Singapore Dollar",
  "THB": "Thai Baht",
  "USD": "US Dollar",
  "VND": "Vietnamese Dong",
};

bool hasFile(String answer) {
  final uri = Uri.tryParse(answer);
  if (uri == null) return false;
  final path = uri.path;
  return path.contains('.'); // ada ekstensi = ada file
}

String cleanYoutubeUrl(String url) {
  if (url.isEmpty) return '';

  try {
    final uri = Uri.parse(url);

    if (uri.host.contains('youtu.be')) {
      final videoId = uri.pathSegments.first;
      return 'https://www.youtube.com/watch?v=$videoId';
    }

    if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
      final videoId = uri.queryParameters['v']!;
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    
    return url;

  } catch (_) {
    return url;
  }
}

final Map<String, String> errorTranslationMap = {
  "Email diperlukan": 'Email is required',

  "Email tidak terdaftar": 'Email is not registered',

  "Email sudah terdaftar": 'Email is already registered',

  'Email harus berupa email yang valid': 'Email must be a valid email',

  'Email harus alamat email yang valid': 'Email must be a valid email address',

  'Email harus memiliki domain yang valid': 'Email must have a valid domain',

  'Nomor telepon minimal 7 karakter': 'Phone number at least 7 characters',

  "Password diperlukan": 'Password is required',

  'Password minimal 8 karakter': 'Password must be at least 8 characters',

  'Password harus mengandung setidaknya satu huruf dan satu angka':
      'Password must contain at least one letter and one number',

  'Password tidak cocok': 'Password does not match',


  // current password
  'Current password minimal 8 karakter':
      'Current password must be at least 8 characters',
  'Current password diperlukan': 'Current password is required',
  'Password saat ini salah': 'Current password is incorrect',

  // new password
  'new password minimal 8 karakter':
      'New password must be at least 8 characters',
  'New password diperlukan': 'New password is required',

  // confirm password
  'Konfirmasi password tidak cocok':
      'Confirm password does not match',
  'Confirm password diperlukan': 'Confirm password is required',

  'Format password tidak valid': 'Password format is invalid',
};


// Map khusus normalisasi bahasa ID (server → tampilan)
final Map<String, String> idNormalizationMap = {
  'Nomor telepon minimal 7 karakter': 'Nomor handphone harus minimal 7 karakter',
  'email harus memiliki domain yang valid.': 'Email harus memiliki domain yang valid',
  'Current password minimal 8 karakter': 'Kata sandi lama minimal 8 karakter',
  'Current password diperlukan': 'Kata sandi lama diperlukan',
  'Password saat ini salah': 'Kata sandi lama salah',
  'New password minimal 8 karakter': 'Kata sandi baru minimal 8 karakter',
  'New password diperlukan': 'Kata sandi baru diperlukan',
  'Confirm password diperlukan': 'Konfirmasi kata sandi diperlukan',
  'Konfirmasi password tidak cocok': 'Konfirmasi kata sandi tidak cocok',
  'Format password tidak valid': 'Format kata sandi tidak valid',
  'Password diperlukan': 'Password diperlukan',
  'Password minimal 8 karakter': 'Kata sandi minimal 8 karakter',
  'Password harus mengandung setidaknya satu huruf dan satu angka': 'Kata sandi harus mengandung setidaknya satu huruf dan satu angka',
  'Password tidak cocok': 'Kata sandi tidak cocok',
};


class EmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus SEMUA spasi
    String text = newValue.text.replaceAll(RegExp(r'\s'), '');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}