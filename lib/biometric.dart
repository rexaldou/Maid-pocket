import 'package:local_auth/local_auth.dart'; //Local Authentication,buat biometrik login,fingerprint,ya lu tau lah

class BiometricAuth {
  static final LocalAuthentication _auth = LocalAuthentication();

  //Ini ngecek si perangkat support biometrik atau enggak
  static Future<bool> hardwareCheck() async {
    final bool ngeCheck = await _auth.canCheckBiometrics;
    final bool didukung = await _auth.isDeviceSupported();
    return ngeCheck && didukung;
  }

  //Fungsi buat scan sidik jari si user
  static Future<bool> authenticate() async {
    try {
      bool hardwareAman = await hardwareCheck();
      if (!hardwareAman) return true;

      return await _auth.authenticate(
        localizedReason: 'Scan sidik jari dulu yaahhh :3',
        biometricOnly: true, //Wajib sidik jari atau face id,ga bisa pake pin/password kalo true
      );
    } catch (e) {
      return false; // Kalo error,ya ditolak doonh
    }
  }
}