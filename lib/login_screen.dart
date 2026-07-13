import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'biometric.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Variabel state untuk menyimpan input PIN, PIN tersimpan, dan mode operasional
  String _pin = '';
  String _savedPin = '';
  bool _isCreatingPin = false; // Mode buat PIN baru
  bool _isConfirmingPin = false; // Mode konfirmasi PIN baru
  String _tempPin = '';
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    _inisialisasiKeamanan();
  }

  // Memeriksa apakah PIN sudah ada di penyimpanan lokal dan cek ketersediaan biometrik
  Future<void> _inisialisasiKeamanan() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedpin = prefs.getString('pin');

    bool bioAman = await BiometricAuth.hardwareCheck();
    if (mounted) {
      setState(() {
        _isBiometricSupported = bioAman;
      });
    }

    if (storedpin == null) {
      setState(() {
        _isCreatingPin = true;
      });
    } else {
      setState(() {
        _savedPin = storedpin;
      });
      _cobaBiometric();
    }
  }

  // Fungsi untuk memicu otentikasi biometrik jika perangkat mendukung
  Future<void> _cobaBiometric() async {
    if (!_isBiometricSupported) return;

    bool sukses = await BiometricAuth.authenticate();
    if (sukses) {
      _masukAplikasi();
    } else {
      _tampilPesan("Uhee~ Biometrik kamu gagal,coba lagi~");
    }
  }

  // Navigasi ke halaman utama jika otentikasi berhasil
  void _masukAplikasi() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  // Mengelola input angka dari user dan validasi PIN
  void _tekanAngka(String angka) async {
    if (_pin.length < 6) {
      setState (() {
        _pin += angka;
      });
      if (_pin.length == 6) {
        if (_isCreatingPin) {
          if (!_isConfirmingPin) {
            // Jika mode buat PIN baru, simpan sementara untuk konfirmasi
            setState(() {
              _tempPin = _pin;
              _pin = '';
              _isConfirmingPin = true;
            });
          } else {
            // Validasi kecocokan PIN konfirmasi dengan PIN awal
            if (_pin == _tempPin) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('pin', _pin);
              _masukAplikasi();
            } else {
              _tampilPesan("PIN tidak cocok. Silakan coba lagi.");
              setState(() {
                _pin = '';
                _tempPin = '';
                _isConfirmingPin = false;
              });
            }
          }
        } else {
          // Verifikasi PIN dengan data yang sudah tersimpan
          if (_pin == _savedPin) {
            _masukAplikasi();
          } else {
            _tampilPesan("PIN salah. Silakan coba lagi.");
            setState(() {
              _pin = '';
            });
          }
        }
      }
    }
  }

  // Menghapus karakter terakhir dari input PIN
  void _hapusAngka() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  // Menampilkan pesan umpan balik (Snackbar)
  void _tampilPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), duration: const Duration(seconds: 2)),
    );
  }

  // Merender visual indikator PIN berupa titik-titik
  Widget _buildPinIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  // Merender tombol angka pada layar login
  Widget _buildNumpadButton(String angka) {
    return InkWell(
      onTap: () => _tekanAngka(angka),
      borderRadius: BorderRadius.circular(40),
      child: Container  (
        width: 75,
        height: 75,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        child: Text(
          angka,
          style: const TextStyle(fontSize: 28,fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String judul = "Masukkan PIN";
    if (_isCreatingPin) {
      judul = _isConfirmingPin ? "Konfirmasi PIN Baru" : "Buat PIN 6 Digit";
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.lock_outline, size: 60, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              judul,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildPinIndicator(),
            const Spacer(),
            // Numpad Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildNumpadButton("1"), _buildNumpadButton("2"), _buildNumpadButton("3")],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildNumpadButton("4"), _buildNumpadButton("5"), _buildNumpadButton("6")],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildNumpadButton("7"), _buildNumpadButton("8"), _buildNumpadButton("9")],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol biometrik, hanya muncul jika fitur didukung dan bukan mode pembuatan PIN
                      InkWell(
                        onTap: (!_isCreatingPin && _isBiometricSupported) ? _cobaBiometric : null,
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 75,
                          height: 75,
                          alignment: Alignment.center,
                          child: (!_isCreatingPin && _isBiometricSupported)
                              ? const Icon(Icons.fingerprint, size: 35, color: Colors.blueAccent)
                              : const SizedBox(width: 75), 
                        ),
                      ),
                      _buildNumpadButton("0"),
                      InkWell(
                        onTap: _hapusAngka,
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 75,
                          height: 75,
                          alignment: Alignment.center,
                          child: const Icon(Icons.backspace_outlined, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}