import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaidPocketApp());
}

class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  const AnimatedCounter({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutExpo,
      builder: (context, double val, child) => Text(DatabaseHelper.instance.formatRupiah(val), style: style),
    );
  }
}

class MaidPocketApp extends StatelessWidget {
  const MaidPocketApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, textTheme: GoogleFonts.lexendTextTheme()),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> daftarKantong = [];
  List<Map<String, dynamic>> riwayatTransaksi = [];
  int indexTerpilih = 0;
  bool _hideSaldo = false;
  
  final PageController _pageController = PageController(viewportFraction: 0.80);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() async {
    final data = await DatabaseHelper.instance.ambilSemuaTabungan();
    if (data.isNotEmpty) {
      if (indexTerpilih >= data.length) indexTerpilih = 0;
      final log = await DatabaseHelper.instance.ambilRiwayat(data[indexTerpilih]['id']);
      if (!mounted) return;
      setState(() { daftarKantong = data; riwayatTransaksi = log; });
    } else {
      if (!mounted) return;
      setState(() { daftarKantong = []; riwayatTransaksi = []; indexTerpilih = 0; });
    }
  }

  Color _getMoodColor(Map<String, dynamic> kntg) {
    double saldo = (kntg['saldo'] ?? 0).toDouble();
    double lKuning = (kntg['limit_kuning'] ?? 50000).toDouble();
    double lHijau = (kntg['limit_hijau'] ?? 500000).toDouble();
    int tema = kntg['tema_id'] ?? 0;
    
    List<Color> palet;
    if (tema == 1) palet = [Colors.pink.shade700, Colors.pink.shade300, Colors.purple.shade200, Colors.deepPurple.shade400]; 
    else if (tema == 2) palet = [Colors.grey.shade900, Colors.blue.shade900, Colors.cyan.shade700, Colors.teal.shade300]; 
    else if (tema == 3) palet = [Colors.brown, Colors.orange, Colors.amber, Colors.yellow.shade600]; 
    else if (tema == 4) palet = [Colors.green.shade900, Colors.green, Colors.lightGreen, Colors.lime]; 
    else palet = [Colors.red.shade700, Colors.orange, Colors.green, Colors.blue.shade600]; 

    if (saldo <= 0) return palet[0];
    if (saldo <= lKuning) return palet[1];
    if (saldo <= lHijau) return palet[2];
    return palet[3]; 
  }

  void _tampilkanPilihanBanner(Map<String, dynamic> kntg) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(15), child: Text("Edit Dompet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ExpansionTile(
          leading: const Icon(Icons.palette),
          title: const Text("Ganti Tema / Foto"),
          children: [
            ListTile(leading: const Icon(Icons.color_lens, size: 20), title: const Text("Default Mood"), onTap: () { DatabaseHelper.instance.updateTema(kntg['id'], 0, null); _refresh(); Navigator.pop(ctx); }),
            ListTile(leading: const Icon(Icons.spa, size: 20), title: const Text("Sakura Bloom"), onTap: () { DatabaseHelper.instance.updateTema(kntg['id'], 1, null); _refresh(); Navigator.pop(ctx); }),
            ListTile(leading: const Icon(Icons.nightlight_round, size: 20), title: const Text("Midnight Tech"), onTap: () { DatabaseHelper.instance.updateTema(kntg['id'], 2, null); _refresh(); Navigator.pop(ctx); }),
            ListTile(leading: const Icon(Icons.wb_sunny, size: 20), title: const Text("Sunset Gold"), onTap: () { DatabaseHelper.instance.updateTema(kntg['id'], 3, null); _refresh(); Navigator.pop(ctx); }),
            ListTile(leading: const Icon(Icons.forest, size: 20), title: const Text("Forest Life"), onTap: () { DatabaseHelper.instance.updateTema(kntg['id'], 4, null); _refresh(); Navigator.pop(ctx); }),
            
            ListTile(leading: const Icon(Icons.image, size: 20), title: const Text("Pilih Foto Galeri"), onTap: () async {
              final p = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (p != null) {
                final croppedFile = await ImageCropper().cropImage(
                  sourcePath: p.path,
                  aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
                  uiSettings: [
                    AndroidUiSettings(
                      toolbarTitle: 'Geser & Sesuaikan',
                      toolbarColor: Colors.blueAccent,
                      toolbarWidgetColor: Colors.white,
                      initAspectRatio: CropAspectRatioPreset.ratio16x9,
                      lockAspectRatio: false,
                    ),
                  ],
                );
                
                if (croppedFile != null) {
                  await DatabaseHelper.instance.updateTema(kntg['id'], 0, croppedFile.path);
                  _refresh();
                }
              }
              if (mounted) Navigator.pop(ctx);
            }),
          ],
        ),
        ListTile(
          leading: const Icon(Icons.tune),
          title: const Text("Edit Limit Saldo"),
          onTap: () { Navigator.pop(ctx); _editLimit(kntg); },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text("Hapus Dompet Ini", style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); _konfirmasiHapusDompet(kntg); },
        ),
      ]),
    ));
  }

  void _editLimit(Map<String, dynamic> kntg) {
    double k = (kntg['limit_kuning'] ?? 50000).toDouble();
    double h = (kntg['limit_hijau'] ?? 500000).toDouble();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Edit Limit Mood"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          decoration: const InputDecoration(labelText: "Batas Kuning"), 
          keyboardType: TextInputType.number, 
          controller: TextEditingController(text: k.toStringAsFixed(0)), 
          onChanged: (v) {
            String cleanValue = v.replaceAll('.', '');
            k = double.tryParse(cleanValue) ?? k;
          }
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Batas Hijau"), 
          keyboardType: TextInputType.number, 
          controller: TextEditingController(text: h.toStringAsFixed(0)), 
          onChanged: (v) {
            String cleanValue = v.replaceAll('.', '');
            h = double.tryParse(cleanValue) ?? h;
          }
        ),
      ])),
      actions: [ElevatedButton(onPressed: () async {
        await DatabaseHelper.instance.updateLimit(kntg['id'], k, h);
        await DatabaseHelper.instance.tambahTransaksi({'tabungan_id': kntg['id'], 'amount': 0.0, 'notes': 'Uhee~ Limit saldo diubah!', 'created_at': DateTime.now().toIso8601String()});
        _refresh(); Navigator.pop(ctx);
      }, child: const Text("Simpan"))],
    ));
  }

  void _konfirmasiHapusDompet(Map<String, dynamic> kntg) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Hapus Dompet?"),
      content: Text("Yakin mau hapus dompet '${kntg['nama']}'? Semua riwayat di dompet ini bakal hilang tanpa sisa lho..."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {
          await DatabaseHelper.instance.hapusTabungan(kntg['id']);
          _refresh(); Navigator.pop(ctx);
        }, child: const Text("Hapus", style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  void _tambahDompet() {
    String nama = ""; double k = 50000, h = 500000;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Dompet Baru"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(decoration: const InputDecoration(labelText: "Nama Dompet"), onChanged: (v) => nama = v),
        TextField(
          decoration: const InputDecoration(labelText: "Batas Kuning (Misal: 50.000)"), 
          keyboardType: TextInputType.number, 
          onChanged: (v) {
            String cleanValue = v.replaceAll('.', '');
            k = double.tryParse(cleanValue) ?? 50000;
          }
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Batas Hijau (Misal: 500.000)"), 
          keyboardType: TextInputType.number, 
          onChanged: (v) {
            String cleanValue = v.replaceAll('.', '');
            h = double.tryParse(cleanValue) ?? 500000;
          }
        ),
      ])),
      actions: [ElevatedButton(onPressed: () async {
        if (nama.isNotEmpty) {
          await DatabaseHelper.instance.tambahTabungan({'nama': nama, 'saldo': 0.0, 'limit_kuning': k, 'limit_hijau': h, 'tema_id': 0});
          _refresh(); Navigator.pop(ctx);
        }
      }, child: const Text("Buat"))],
    ));
  }

  void _tambahTransaksi(String tipe) {
    if (daftarKantong.isEmpty) return;
    double nom = 0; String ket = "";
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Input $tipe", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextField(
          decoration: const InputDecoration(labelText: "Jumlah Nominal (Rp)"), 
          keyboardType: TextInputType.number, 
          onChanged: (v) {
            String cleanValue = v.replaceAll('.', '');
            nom = double.tryParse(cleanValue) ?? 0;
          }
        ),
        TextField(decoration: const InputDecoration(labelText: "Catatan (Beli apa/Dari mana)"), onChanged: (v) => ket = v),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          onPressed: () async {
            if (nom > 0) {
              await DatabaseHelper.instance.tambahTransaksi({'tabungan_id': daftarKantong[indexTerpilih]['id'], 'amount': tipe == 'Masuk' ? nom : -nom, 'notes': ket, 'created_at': DateTime.now().toIso8601String()});
              await DatabaseHelper.instance.updateSaldo(daftarKantong[indexTerpilih]['id'], daftarKantong[indexTerpilih]['saldo'] + (tipe == 'Masuk' ? nom : -nom));
              _refresh(); Navigator.pop(ctx);
            }
          }, child: const Text("Simpan")
        ),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _konfirmasiHapus(Map<String, dynamic> trx) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Hapus Riwayat?"),
      content: const Text("Uhee~ Senpai beneran mau hapus catatan ini? Nanti saldonya Ojisan balikin kayak semula lho..."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Gak jadi", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await DatabaseHelper.instance.hapusTransaksi(trx['id']);
            double saldoSekarang = daftarKantong[indexTerpilih]['saldo'];
            await DatabaseHelper.instance.updateSaldo(daftarKantong[indexTerpilih]['id'], saldoSekarang - trx['amount']);
            _refresh();
            if(mounted) Navigator.pop(ctx);
          }, 
          child: const Text("Hapus", style: TextStyle(color: Colors.white))
        )
      ]
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("MaidPocket", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uhee~ Fitur Dark Mode & Analitik grafik nyusul di V.2 ya! Sabar!"))), 
            icon: const Icon(Icons.settings, color: Colors.grey)
          ),
          IconButton(
            onPressed: _tambahDompet, 
            icon: const Icon(Icons.add_circle, size: 30, color: Colors.blueAccent)
          ),
          const SizedBox(width: 8),
        ]
      ),
      body: daftarKantong.isEmpty ? Center(
        child: InkWell(
          onTap: _tambahDompet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(20)),
            child: const Text("Uhee~ belum ada dompet nih... ayo bikin sekarang!", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        )
      ) : Column(children: [
        SizedBox(height: 230, child: PageView.builder(
          controller: _pageController,
          itemCount: daftarKantong.length,
          onPageChanged: (i) => setState(() { indexTerpilih = i; _refresh(); }),
          itemBuilder: (ctx, i) {
            var kntg = daftarKantong[i];
            Color mood = _getMoodColor(kntg);
            
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - i;
                  value = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
                }
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value.clamp(0.4, 1.0), child: child),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), 
                  gradient: LinearGradient(colors: [mood, mood.withAlpha(150)]), 
                  image: kntg['banner_path'] != null ? DecorationImage(image: FileImage(File(kntg['banner_path'])), fit: BoxFit.cover) : null
                ),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.black.withAlpha(kntg['banner_path'] != null ? 80 : 0)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(kntg['nama'].toUpperCase(), style: const TextStyle(color: Colors.white, letterSpacing: 1.5, fontSize: 12)),
                      IconButton(onPressed: () => _tampilkanPilihanBanner(kntg), icon: const Icon(Icons.edit_note, color: Colors.white)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _hideSaldo ? const Text("Rp ••••••••", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)) 
                      : AnimatedCounter(value: (kntg['saldo'] ?? 0).toDouble(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => setState(() => _hideSaldo = !_hideSaldo), icon: Icon(_hideSaldo ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 20)),
                    ]),
                    const Spacer(),
                    Text((kntg['saldo'] ?? 0) <= 0 ? "uhee~ kering bgt dompetnya..." : "Masih aman, Senpai!", style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 11)),
                  ]),
                ),
              )
            );
          },
        )),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _btn("Masuk", Icons.add, Colors.green, () => _tambahTransaksi("Masuk")),
          _btn("Keluar", Icons.remove, Colors.red, () => _tambahTransaksi("Keluar")),
        ]),
        const Padding(padding: EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text("Riwayat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
        Expanded(child: ListView.builder(
          itemCount: riwayatTransaksi.length,
          itemBuilder: (ctx, i) {
            var trx = riwayatTransaksi[i]; bool inc = trx['amount'] >= 0;
            bool isSistem = trx['amount'] == 0; 

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSistem ? Colors.blue.withAlpha(30) : (inc ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30)), 
                child: Icon(
                  isSistem ? Icons.info_outline : (inc ? Icons.add : Icons.remove), 
                  color: isSistem ? Colors.blue : (inc ? Colors.green : Colors.red), 
                  size: 18
                )
              ),
              title: Text(trx['notes'] == "" ? (inc ? "Masuk" : "Keluar") : trx['notes'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(DateFormat('HH:mm').format(DateTime.parse(trx['created_at']))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSistem) Text(DatabaseHelper.instance.formatRupiah(trx['amount'].abs()), style: TextStyle(color: inc ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: () => _konfirmasiHapus(trx))
                ]
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _btn(String t, IconData i, Color c, VoidCallback o) => InkWell(onTap: o, child: Column(children: [CircleAvatar(backgroundColor: Colors.white, child: Icon(i, color: c)), const SizedBox(height: 5), Text(t, style: const TextStyle(fontSize: 12))]));
}