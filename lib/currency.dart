import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  // --- API Global negara yah
  Future<void> _fetchKursOtomatis() async {
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

        setState(() {
          _allRates = convertedRates;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('all_rates_cache', json.encode(convertedRates));
      }
    } catch (e) {
      debugPrint("Gagal update global currency, aman pake data lokal.");
    }
  }

  // Baca data yang udah didownload pas lagi offline
  Future<void> _loadKursLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedRates = prefs.getString('all_rates_cache');
    if (cachedRates != null) {
      setState(() {
        _allRates = Map<String, dynamic>.from(json.decode(cachedRates));
      });
    }
  }

  // Logika hitung konversi saldo
  double _getConvertedSaldo(double saldo) {
    double rate = _allRates[_mataUangAktif]?.toDouble() ?? 1.0;
    if (_mataUangAktif == 'IDR') return saldo;
    return saldo / rate;
  }
}