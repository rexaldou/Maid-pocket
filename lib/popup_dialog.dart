import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahan untuk simpan urutan

import 'database_helper.dart';
import 'form_transaksi.dart';

class PopupHelper {
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

  // Mengubah parameter kntg menjadi menerima full list daftarKantong agar bisa diurutkan
  static void tampilkanPilihanBanner(BuildContext context, bool isDarkMode, Map<String, dynamic> kntg, List<Map<String, dynamic>> daftarKantong, VoidCallback onRefresh) {
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
          // Fitur baru untuk mengurutkan dompet secara offline
          ListTile(
            leading: Icon(Icons.swap_vert, color: isDarkMode ? Colors.white : Colors.black),
            title: Text("Atur Urutan Dompet", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.pop(ctx);
              aturUrutanDompet(context, isDarkMode, daftarKantong, onRefresh);
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

  // Fungsi popup drag and drop untuk mengubah urutan dompet secara fisik
  static void aturUrutanDompet(BuildContext context, bool isDarkMode, List<Map<String, dynamic>> daftarKantong, VoidCallback onRefresh) {
    List<Map<String, dynamic>> lokalList = List.from(daftarKantong);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text("Geser Urutan Dompet", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                height: 250,
                child: ReorderableListView(
                  shrinkWrap: true,
                  children: List.generate(lokalList.length, (index) {
                    final item = lokalList[index];
                    return ListTile(
                      key: Key(item['id'].toString()),
                      leading: Icon(Icons.drag_handle, color: isDarkMode ? Colors.white54 : Colors.black54),
                      title: Text(item['nama'].toString().toUpperCase(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 14)),
                    );
                  }),
                  onReorderItem: (oldIndex, newIndex) {
                    setModalState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = lokalList.removeAt(oldIndex);
                      lokalList.insert(newIndex, item);
                    });
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    List<String> urutanIds = lokalList.map((e) => e['id'].toString()).toList();
                    await prefs.setStringList('urutan_dompet_lokal', urutanIds);
                    onRefresh();
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                  },
                  child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static const Map<String, Map<String, String>> _kamusNegara = {
    'IDR': {'nama': 'Indonesia', 'bendera': '🇮🇩'}, 'USD': {'nama': 'Amerika Serikat', 'bendera': '🇺🇸'},
    'JPY': {'nama': 'Jepang', 'bendera': '🇯🇵'}, 'EUR': {'nama': 'Uni Eropa', 'bendera': '🇪🇺'},
    'GBP': {'nama': 'Inggris', 'bendera': '🇬🇧'}, 'SGD': {'nama': 'Singapura', 'bendera': '🇸🇬'},
  };

  static void tampilkanPilihanKurs(BuildContext context, bool isDarkMode, Map<String, dynamic> allRates, String mataUangAktif, Function(String) onPilihKurs) {
    List<String> semuaNegara = allRates.keys.toList()..sort();
    String querySearch = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          List<String> terfilter = semuaNegara.where((code) {
            final info = _kamusNegara[code];
            final namaNegara = info?['nama']?.toLowerCase() ?? '';
            final kodeCurr = code.toLowerCase();
            return namaNegara.contains(querySearch.toLowerCase()) || kodeCurr.contains(querySearch.toLowerCase());
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.all(15), child: Text("Pilih Negara Asal Mata Uang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: TextField(
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Cari nama negara atau mata uang...",
                      hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                      prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => setModalState(() => querySearch = val),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: terfilter.length,
                    itemBuilder: (ctx, i) {
                      String code = terfilter[i];
                      final info = _kamusNegara[code] ?? {'nama': 'Mata Uang ($code)', 'bendera': '🌐'};
                      return ListTile(
                        leading: Text(info['bendera']!, style: const TextStyle(fontSize: 26)),
                        title: Text(info['nama']!, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                        subtitle: Text(code, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: mataUangAktif == code ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                        onTap: () { onPilihKurs(code); Navigator.pop(ctx); },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void pilihTema(BuildContext context, bool isDarkMode, Map<String, dynamic> kntg, VoidCallback onRefresh) {
    // 🌸 List lengkap 6 tema sesuai index di apptheme_helper.dart
    final listTema = [
      {"icon": Icons.circle, "name": "🎨 Default Mood", "color": Colors.blueAccent},
      {"icon": Icons.spa, "name": "🌸 Sakura Mood", "color": Colors.pinkAccent},
      {"icon": Icons.water_drop, "name": "🌊 Ocean Mood", "color": Colors.lightBlue},
      {"icon": Icons.coffee, "name": "☕ Coffee Sunset Mood", "color": Colors.orangeAccent},
      {"icon": Icons.eco, "name": "🌿 Matcha Eco Mood", "color": Colors.greenAccent},
      {"icon": Icons.brightness_3, "name": "🌌 Deep Indigo Mood", "color": Colors.indigoAccent},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text("Pilih Mood Dompet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: listTema.length,
              itemBuilder: (ctx, i) => ListTile(
                leading: Icon(listTema[i]['icon'] as IconData, color: listTema[i]['color'] as Color),
                title: Text(
                  listTema[i]['name'] as String, 
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
                ),
                trailing: kntg['tema_id'] == i ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                onTap: () { 
                  DatabaseHelper.instance.updateTema(kntg['id'], i, null); 
                  onRefresh(); 
                  Navigator.pop(ctx); 
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void tambahDompet(BuildContext context, bool isDarkMode, VoidCallback onRefresh) {
    String n = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Dompet Baru", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                onChanged: (v) => n = v,
                decoration: InputDecoration(hintText: "Nama Dompet", hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (n.isNotEmpty) {
                await DatabaseHelper.instance.tambahTabungan({'nama': n, 'saldo': 0, 'limit_kuning': 50000, 'limit_hijau': 100000, 'tema_id': 0});
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

  static void editLimit(BuildContext context, bool isDarkMode, Map<String, dynamic> kntg, VoidCallback onRefresh) {
    double kun = (kntg['limit_kuning'] ?? 50000).toDouble();
    double hij = (kntg['limit_hijau'] ?? 500000).toDouble();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Edit Limit Mood", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: SingleChildScrollView(
          child: Column(
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

  static void tampilkanDetailTransaksi({
    required BuildContext context,
    required bool isDarkMode,
    required Map<String, dynamic> item,
    required VoidCallback onRefresh,
  }) {
    final tglAsli = DateTime.parse(item['created_at']);
    final String formatTanggal = DateFormat('dd MMMM yyyy').format(tglAsli);
    final String formatJam = DateFormat('HH:mm').format(tglAsli);
    final bool isMinus = item['amount'] < 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['kategori'] ?? 'Umum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 5),
            Text("${isMinus ? '-' : '+'}${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['amount'].abs())}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isMinus ? Colors.red : Colors.green)),
            const SizedBox(height: 20),
            if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: const Border(left: BorderSide(color: Colors.blueAccent, width: 4))),
                child: Text(item['notes'], style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.white70 : Colors.black87)),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: isDarkMode ? Colors.white60 : Colors.black54),
                const SizedBox(width: 8), Text(formatTanggal, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: isDarkMode ? Colors.white60 : Colors.black54),
                const SizedBox(width: 8), Text(formatJam, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent), padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.edit, size: 18), label: const Text("Edit"),
                    onPressed: () { Navigator.pop(ctx); bukaForm(context: context, isDarkMode: isDarkMode, tabunganId: item['tabungan_id'], saldoSekarang: 0, dataLama: item, onRefresh: onRefresh); },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.delete, size: 18), label: const Text("Hapus"),
                    onPressed: () async { Navigator.pop(ctx); await DatabaseHelper.instance.hapusTransaksi(item['id']); onRefresh(); },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}