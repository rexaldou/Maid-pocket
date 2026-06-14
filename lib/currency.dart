import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyLogic {
  
  // 🔥 1. Fungsi Narik Data API (Ngembaliin Map/Kamus Data)
  static Future<Map<String, dynamic>?> fetchKursOtomatis() async {
    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        double usdToIdr = rates['IDR']?.toDouble() ?? 16000.0;
        Map<String, dynamic> convertedRates = {};

        rates.forEach((key, value) {
          convertedRates[key] = usdToIdr / (value?.toDouble() ?? 1.0);
        });

        // Simpan ke memori HP (Cache)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('all_rates_cache', json.encode(convertedRates));

        // Lempar datanya keluar biar ditangkep main.dart
        return convertedRates; 
      }
    } catch (e) {
      debugPrint("Gagal update global currency, aman pake data lokal.");
    }
    return null; // Kalau internet mati / gagal
  }

  // 🔥 2. Fungsi Baca Cache Lokal (Offline Mode)
  static Future<Map<String, dynamic>?> loadKursLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedRates = prefs.getString('all_rates_cache');
    
    if (cachedRates != null) {
      // Lempar data offline-nya ke main.dart
      return Map<String, dynamic>.from(json.decode(cachedRates));
    }
    return null;
  }

  // 🔥 3. Fungsi Tukang Hitung Saldo
  static double getConvertedSaldo(double saldo, String mataUangAktif, Map<String, dynamic> allRates) {
    double rate = allRates[mataUangAktif]?.toDouble() ?? 1.0;
    if (mataUangAktif == 'IDR') return saldo;
    return saldo / rate; // Hasil hitungannya dikembalikan
  }
}