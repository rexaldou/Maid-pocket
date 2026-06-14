import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ModernDrawer extends StatelessWidget {
  // Minta data dari main.dart
  final Color txtCol;
  final Color cardCol;
  final bool isDarkMode;
  final GoogleSignInAccount? currentUser;
  final bool hideSaldo;
  final GoogleSignIn googleSignIn;
  final bool biometricAktif;
  final ValueChanged<bool> onToggleBiometric;

  // Tombol switch buat Privacy,ya sensor lah
  final ValueChanged<bool> onToggleHideSaldo;

  const ModernDrawer({
    super.key,
    required this.txtCol,
    required this.cardCol,
    required this.isDarkMode,
    required this.currentUser,
    required this.hideSaldo,
    required this.googleSignIn,
    required this.onToggleHideSaldo,
    required this.biometricAktif,
    required this.onToggleBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cardCol,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.blueAccent.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: currentUser?.photoUrl != null
                      ? NetworkImage(currentUser!.photoUrl!)
                      : null,
                  child: currentUser == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  currentUser?.displayName ?? "User Offline",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: txtCol,
                  ),
                ),
                Text(
                  currentUser?.email ?? "Sinkronkan data ke Cloud",
                  style: TextStyle(
                    fontSize: 12,
                    color: txtCol.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _drawerItem(
            Icons.cloud_sync,
            "Auto-Backup Status",
            currentUser != null ? "Aktif" : "Nonaktif (Login Required)",
            Colors.green,
            txtCol,
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.orange),
            title: Text(
              "Data Privacy",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: txtCol,
              ),
            ),
            subtitle: Text(
              hideSaldo ? "Aktif (Saldo Disensor)" : "Nonaktif (Saldo Terlihat)",
              style: TextStyle(
                fontSize: 11,
                color: txtCol.withValues(alpha: 0.7),
              ),
            ),
            trailing: Switch(
              value: hideSaldo,
              activeThumbColor: Colors.orange,
              onChanged: onToggleHideSaldo, // 🌸 Mencet remote ke main.dart
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: currentUser == null ? Colors.green : Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                currentUser == null ? googleSignIn.signIn() : googleSignIn.disconnect();
              },
              icon: Icon(currentUser == null ? Icons.login : Icons.logout),
              label: Text(
                currentUser == null ? "Hubungkan ke Google" : "Putuskan Akun",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi tambahan ditaruh di dalam class
  Widget _drawerItem(IconData i, String t, String sub, Color c, Color txtCol) {
    return ListTile(
      leading: Icon(i, color: c),
      title: Text(
        t,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: txtCol,
        ),
      ),
      subtitle: Text(
        sub,
        style: TextStyle(fontSize: 11, color: txtCol.withValues(alpha: 0.7)),
      ),
    );
  }
}