import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';
import 'form_transaksi.dart';

class PopupHelper {
  // 1. Pop-up Buka Form Transaksi
  static void bukaForm({
    required BuildContext context,
    required bool isDarkMode,
    required int tabunganId,
    required double saldoSekarang,
    Map<String, dynamic>? dataLama,
    String? tipe,
    required VoidCallback onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopupFormTransaksi(
        isDarkMode: isDarkMode,
        tabunganId: tabunganId,
        saldoSekarang: saldoSekarang,
        dataLama: dataLama,
        tipe: tipe,
        onDataTersimpan: onRefresh,
      ),
    );
  }

  // 2. Pop-up Pilihan Menu Banner
  static void tampilkanPilihanBanner(BuildContext context, bool isDarkMode, Map<String, dynamic> kntg, VoidCallback onRefresh) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.palette, color: isDarkMode ? Colors.white : Colors.black),
            title: Text("Ganti Mood Dompet", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.pop(ctx);
              pilihTema(context, isDarkMode, kntg, onRefresh);
            },
          ),
          ListTile(
            leading: Icon(Icons.tune, color: isDarkMode ? Colors.white : Colors.black),
            title: Text("Edit Limit Saldo", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.pop(ctx);
              editLimit(context, isDarkMode, kntg, onRefresh);
            },
          ),
          ListTile(
            leading: Icon(Icons.image, color: isDarkMode ? Colors.white : Colors.black),
            title: Text("Custom Banner Galeri", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.pop(ctx);
              handleImagePick(kntg, onRefresh);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Hapus Dompet", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              konfirmasiHapusDompet(context, isDarkMode, kntg, onRefresh);
            },
          ),
        ],
      ),
    );
  }

  // 3. Pop-up Pilihan Kurs
  static void tampilkanPilihanKurs(BuildContext context, bool isDarkMode, Map<String, dynamic> allRates, String mataUangAktif, Function(String) onPilihKurs) {
    List<String> semuaNegara = allRates.keys.toList()..sort();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(15),
            child: Text("Pilih Mata Uang Global", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: semuaNegara.length,
              itemBuilder: (ctx, i) {
                String code = semuaNegara[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                    child: Text(code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(code, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  trailing: mataUangAktif == code ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                  onTap: () {
                    onPilihKurs(code); // Remote panggil setState di main.dart
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 4. Pop-up Pilih Tema
  static void pilihTema(BuildContext context, bool isDarkMode, Map<String, dynamic> kntg, VoidCallback onRefresh) {
    final listTema = [
      {"icon": Icons.circle, "name": "🎨 Default Mood", "color": Colors.blueAccent},
      {"icon": Icons.spa, "name": "🌸 Sakura Mood", "color": Colors.pinkAccent},
      {"icon": Icons.water_drop, "name": "🌊 Ocean Mood", "color": Colors.lightBlue},
      {"icon": Icons.park, "name": "🍂 Autumn Mood", "color": Colors.orange},
      {"icon": Icons.forest, "name": "🌲 Forest Mood", "color": Colors.green},
      {"icon": Icons.diamond, "name": "🔮 Amethyst Mood", "color": Colors.purpleAccent},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: listTema.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: Icon(listTema[i]['icon'] as IconData, color: listTema[i]['color'] as Color),
          title: Text(
            listTema[i]['name'] as String,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            DatabaseHelper.instance.updateTema(kntg['id'], i, null);
            onRefresh();
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  // 5. Pop-up Tambah Dompet
  static void tambahDompet(BuildContext context, bool isDarkMode, VoidCallback onRefresh) {
    String n = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Dompet Baru", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: TextField(
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          onChanged: (v) => n = v,
          decoration: InputDecoration(
            hintText: "Nama Dompet",
            hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (n.isNotEmpty) {
                await DatabaseHelper.instance.tambahTabungan({
                  'nama': n, 'saldo': 0, 'limit_kuning': 50000, 'limit_hijau': 100000, 'tema_id': 0,
                });
                onRefresh();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: const Text("Buat"),
          ),
        ],
      ),
    );
  }

  // 6. Pop-up Edit Limit
  static void editLimit(BuildContext context, bool isDarkMode, Map<String, dynamic> kntg, VoidCallback onRefresh) {
    double kun = (kntg['limit_kuning'] ?? 50000).toDouble();
    double hij = (kntg['limit_hijau'] ?? 500000).toDouble();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Edit Limit Mood", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: "Batas Kuning", labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: kun.toStringAsFixed(0)),
              onChanged: (v) => kun = double.tryParse(v.replaceAll('.', '')) ?? kun,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Batas Hijau", labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: hij.toStringAsFixed(0)),
              onChanged: (v) => hij = double.tryParse(v.replaceAll('.', '')) ?? hij,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateLimit(kntg['id'], kun, hij);
              onRefresh();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // 7. Pop-up Hapus Dompet
  static void konfirmasiHapusDompet(BuildContext context, bool isDarkMode, Map<String, dynamic> kntg, VoidCallback onRefresh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Hapus Dompet?", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: Text("Seluruh riwayat transaksi di dompet ini akan hilang selamanya.", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.hapusTabungan(kntg['id']);
              onRefresh();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 8. Logika Ambil Gambar Banner
  static Future<void> handleImagePick(Map<String, dynamic> kntg, VoidCallback onRefresh) async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: p.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [AndroidUiSettings(toolbarTitle: 'Potong Banner', toolbarColor: Colors.blueAccent, toolbarWidgetColor: Colors.white)],
      );
      if (croppedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.png';
        final File localImage = await File(croppedFile.path).copy('${directory.path}/$fileName');
        await DatabaseHelper.instance.updateTema(kntg['id'], 0, localImage.path);
        onRefresh();
      }
    }
  }
}