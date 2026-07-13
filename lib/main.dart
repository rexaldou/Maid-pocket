import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_helper.dart';
import 'walletcard.dart';
import 'currency.dart';
import 'cloud_backup.dart';
import 'modern_drawer.dart';
import 'riwayat_list.dart';
import 'action_buttons.dart';
import 'popup_dialog.dart';
import 'statistik_chart.dart';
import 'biometric.dart';
import 'login_screen.dart';
import 'riwayat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "ISI_API_KEY_KAMU",
      appId: "ISI_APP_ID_KAMU",
      messagingSenderId: "ISI_SENDER_ID_KAMU",
      projectId: "ISI_PROJECT_ID_KAMU",
    ),
  );
  runApp(const MaidPocketApp());
}

class MaidPocketApp extends StatelessWidget {
  const MaidPocketApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MaidPocket',
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.lexendTextTheme(),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const LoginScreen(),
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
  bool _isDarkMode = false;
  bool _biometricAktif = true;
  late PageController _pageController;

  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String _mataUangAktif = 'IDR';
  Map<String, dynamic> _allRates = {'IDR': 1.0};

  @override
  void initState() {
    super.initState();
    _inisialisasiKurs();
    _pageController = PageController(viewportFraction: 0.75);
    _refresh();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() => _currentUser = account);
      if (account != null) CloudService.autoBackupCloud(_currentUser);
    });
    _googleSignIn.signInSilently();
  }

  void _inisialisasiKurs() async {
    final dataLokal = await CurrencyLogic.loadKursLokal();
    if (dataLokal != null) setState(() => _allRates = dataLokal);
    final dataOnline = await CurrencyLogic.fetchKursOtomatis();
    if (dataOnline != null) setState(() => _allRates = dataOnline);
  }

  // Menyegarkan data dengan menyortir urutan dompet berdasarkan preferensi user
  void _refresh() async {
    final data = await DatabaseHelper.instance.ambilSemuaTabungan();
    if (data.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      List<String>? orderIds = prefs.getStringList('urutan_dompet_lokal');
      List<Map<String, dynamic>> sortedData = List.from(data);
      
      if (orderIds != null) {
        sortedData.sort((a, b) {
          int indexA = orderIds.indexOf(a['id'].toString());
          int indexB = orderIds.indexOf(b['id'].toString());
          if (indexA == -1) indexA = 999;
          if (indexB == -1) indexB = 999;
          return indexA.compareTo(indexB);
        });
      }

      if (indexTerpilih >= sortedData.length) indexTerpilih = 0;
      final log = await DatabaseHelper.instance.ambilRiwayat(sortedData[indexTerpilih]['id']);
      if (!mounted) return;
      setState(() {
        daftarKantong = sortedData;
        riwayatTransaksi = log;
      });
    } else {
      if (!mounted) return;
      setState(() {
        daftarKantong = [];
        riwayatTransaksi = [];
        indexTerpilih = 0;
      });
    }
  }

  void _hapusTrx(Map<String, dynamic> trx) async {
    await DatabaseHelper.instance.hapusTransaksi(trx['id']);
    await DatabaseHelper.instance.updateSaldo(
      daftarKantong[indexTerpilih]['id'],
      daftarKantong[indexTerpilih]['saldo'] - trx['amount'],
    );
    _refresh();
  }

  void _bukaPopupTransfer() {
    if (daftarKantong.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus memiliki 2 dompet untuk melakukan transfer")),
      );
      return;
    }

    Map<String, dynamic> dompetAsal = daftarKantong[indexTerpilih];
    List<Map<String, dynamic>> opsiDompetTujuan = daftarKantong.where((kntg) => kntg['id'] != dompetAsal['id']).toList();
    Map<String, dynamic> dompetTujuan = opsiDompetTujuan.first;
    final TextEditingController nominalController = TextEditingController();
    final TextEditingController catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Transfer Antar Dompet", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dari: ${dompetAsal['nama'].toString().toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 15),
                    Text("Ke Dompet Tujuan", style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: _isDarkMode ? Colors.black26 : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          dropdownColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                          value: dompetTujuan['id'],
                          items: opsiDompetTujuan.map((kntg) {
                            return DropdownMenuItem<int>(
                              value: kntg['id'],
                              child: Text(kntg['nama'].toString().toUpperCase(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              dompetTujuan = opsiDompetTujuan.firstWhere((kntg) => kntg['id'] == val);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nominalController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Nominal Transfer",
                        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: catatanController,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Catatan (Opsional)",
                        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    double? jumlah = double.tryParse(nominalController.text);
                    if (jumlah == null || jumlah <= 0) return;
                    double saldoAsal = (dompetAsal['saldo'] ?? 0).toDouble();
                    if (jumlah > saldoAsal) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saldo tidak mencukupi")));
                      return;
                    }
                    int idAsal = dompetAsal['id'];
                    int idTujuan = dompetTujuan['id'];
                    String catatanUser = catatanController.text.trim();
                    String waktuSekarang = DateTime.now().toIso8601String();

                    await DatabaseHelper.instance.updateSaldo(idAsal, saldoAsal - jumlah);
                    await DatabaseHelper.instance.updateSaldo(idTujuan, (dompetTujuan['saldo'] ?? 0).toDouble() + jumlah);

                    await DatabaseHelper.instance.tambahTransaksi({
                      'tabungan_id': idAsal, 'amount': -jumlah,
                      'notes': "Transfer ke ${dompetTujuan['nama']}: $catatanUser".trim(),
                      'created_at': waktuSekarang, 'kategori': 'Umum'
                    });
                    await DatabaseHelper.instance.tambahTransaksi({
                      'tabungan_id': idTujuan, 'amount': jumlah,
                      'notes': "Transfer dari ${dompetAsal['nama']}: $catatanUser".trim(),
                      'created_at': waktuSekarang, 'kategori': 'Umum'
                    });

                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    _refresh();
                  },
                  child: const Text("Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color currentBg = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final Color txtCol = _isDarkMode ? Colors.white : Colors.black87;
    final Color cardCol = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text("Maid Pocket", style: TextStyle(fontWeight: FontWeight.bold, color: txtCol, fontSize: 20)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: txtCol),
        actions: [
          _buildThemeToggle(),
          IconButton(
            onPressed: _bukaPopupTransfer,
            icon: Icon(Icons.swap_horiz, color: _isDarkMode ? Colors.blueAccent : Colors.blue),
          ),
          IconButton(
            onPressed: () => PopupHelper.tambahDompet(context, _isDarkMode, _refresh),
            icon: Icon(Icons.add_circle_outline, color: _isDarkMode ? Colors.blueAccent : Colors.blue),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: ModernDrawer(
        biometricAktif: _biometricAktif,
        txtCol: txtCol, cardCol: cardCol, isDarkMode: _isDarkMode,
        currentUser: _currentUser, hideSaldo: _hideSaldo, googleSignIn: _googleSignIn,
        onToggleHideSaldo: (val) => setState(() => _hideSaldo = val),
        onToggleBiometric: (val) async {
          if (val == false) {
            bool lolos = await BiometricAuth.authenticate();
            if (lolos) {
              setState(() => _biometricAktif = false);
            } else {
              setState(() => _biometricAktif = true);
            }
          } else {
            setState(() => _biometricAktif = true);
          }
        },
      ),
      body: daftarKantong.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Uhee~ dompetnya masih kosong, Senpai!", style: TextStyle(color: txtCol.withValues(alpha: 0.6))),
                ],
              ),
            )
          : Column(
              children: [
                Walletcard(
                  daftarKantong: daftarKantong, isDarkMode: _isDarkMode, pageController: _pageController,
                  mataUangAktif: _mataUangAktif, hideSaldo: _hideSaldo, allRates: _allRates,
                  onPageChanged: (i) => setState(() { indexTerpilih = i; _refresh(); }),
                  // Meneruskan daftarKantong lengkap agar menu "Atur Urutan Dompet" bisa membaca semua data
                  onEditBanner: (kntg) => PopupHelper.tampilkanPilihanBanner(context, _isDarkMode, kntg, daftarKantong, _refresh),
                  onPilihKurs: () => PopupHelper.tampilkanPilihanKurs(context, _isDarkMode, _allRates, _mataUangAktif, (code) => setState(() => _mataUangAktif = code)),
                ),
                ActionButtons(
                  txtCol: txtCol,
                  onMasuk: () => PopupHelper.bukaForm(context: context, isDarkMode: _isDarkMode, tabunganId: daftarKantong[indexTerpilih]['id'], saldoSekarang: (daftarKantong[indexTerpilih]['saldo'] ?? 0).toDouble(), tipe: "Masuk", onRefresh: _refresh),
                  onKeluar: () => PopupHelper.bukaForm(context: context, isDarkMode: _isDarkMode, tabunganId: daftarKantong[indexTerpilih]['id'], saldoSekarang: (daftarKantong[indexTerpilih]['saldo'] ?? 0).toDouble(), tipe: "Keluar", onRefresh: _refresh),
                  onTransfer: _bukaPopupTransfer,
                ),
                StatistikChart(data: riwayatTransaksi, isDarkMode: _isDarkMode),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 10, top: 15, bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Riwayat Terakhir",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txtCol),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RiwayatPage(
                                      tabunganId: daftarKantong[indexTerpilih]['id'],
                                      isDarkMode: _isDarkMode,
                                      biometricAktif: _biometricAktif,
                                      onDataBerubah: _refresh,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Lihat Semua", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 300,
                        child: RiwayatList(
                          riwayatTransaksi: riwayatTransaksi.take(3).toList(),
                          txtCol: txtCol, 
                          cardCol: cardCol,
                          onEdit: (trx) async {
                            bool lolos = _biometricAktif ? await BiometricAuth.authenticate() : true; 
                            if (lolos) {
                              if (!context.mounted) return;
                              PopupHelper.tampilkanDetailTransaksi(
                                context: context, 
                                isDarkMode: _isDarkMode, 
                                item: trx, 
                                onRefresh: _refresh
                              );
                            }
                          },
                          onHapus: (trx) => _hapusTrx(trx),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildThemeToggle() => GestureDetector(
        onTap: () => setState(() => _isDarkMode = !_isDarkMode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), width: 60, height: 30, padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _isDarkMode ? Colors.blueGrey.shade900 : Colors.grey.shade300),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300), alignment: _isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Icon(_isDarkMode ? Icons.nightlight_round : Icons.wb_sunny, size: 12, color: _isDarkMode ? Colors.black : Colors.orange),
            ),
          ),
        ),
      );
}