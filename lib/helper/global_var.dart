// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

// padding global
const EdgeInsets kGlobalPadding = EdgeInsets.all(20);

const String baseUrl = "https://dev.kreenconnect.com"; //dev
// const String baseUrl = "https://kreenconnect.com"; //prod

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
  final regex = RegExp(r'^08[0-9]{8,11}$');
  return regex.hasMatch(phone);
}

String? currencyCode = 'IDR'; // currency aktif UI
String? userCurrency = 'IDR'; // preference user
String? lastCurrency;

int isChoosed = 0; // 0 = belum pilih, 1 = sudah pilih

DateTime parseWib(String value) {
  // Ubah ke ISO +07:00 agar Flutter tahu ini WIB
  return DateTime.parse(
    '${value.replaceAll(' ', 'T')}+07:00',
  );
}