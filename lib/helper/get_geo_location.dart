

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

Future<Position?> getCurrentLocationWithValidation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    String? langCode = await StorageService.getLanguage();
    Map<String, dynamic> modalLang = await LangService.getJsonData(langCode!, "modal");
    
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(modalLang['gps_aktif'])), //"Aktifkan GPS terlebih dahulu."
      );
      return null;
    }
    
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(modalLang['izin_lokasi'])), //"Izin lokasi dibutuhkan untuk melanjutkan."
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(modalLang['izin_lokasi_ditolak'])), //"Izin lokasi ditolak permanen. Buka setting untuk mengaktifkan."
      );
      await Geolocator.openAppSettings();
      return null;
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }