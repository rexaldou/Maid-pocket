import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_helper.dart';
import 'walletcard.dart';
import 'currency.dart';
import 'cloud_backup.dart';
import 'modern_drawer.dart';
import 'riwayat_list.dart';
import 'action_buttons.dart';
import 'popup_dialog.dart'; // 🌸 Import file barumu!

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
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.lexendTextTheme(),
      ),
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
  bool _isDarkMode = false;
  late PageController _pageController;

  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String _mataUangAktif = 'IDR';
  Map<String, dynamic> _allRates = {'IDR': 1.0};

  @override
  void initState() {
    super.initState();
    _inisialisasiKurs();
    _pageController = PageController(viewportFraction: 0.85);
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

  void _refresh() async {
    final data = await DatabaseHelper.instance.ambilSemuaTabungan();
    if (data.isNotEmpty) {
      if (indexTerpilih >= data.length) indexTerpilih = 0;
      final log = await DatabaseHelper.instance.ambilRiwayat(data[indexTerpilih]['id']);
      if (!mounted) return;
      setState(() {
        daftarKantong = data;
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

  @override
  Widget build(BuildContext context) {
    final Color currentBg = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final Color txtCol = _isDarkMode ? Colors.white : Colors.black87;
    final Color cardCol = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text("MaidPocket", style: TextStyle(fontWeight: FontWeight.bold, color: txtCol, fontSize: 20)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: txtCol),
        actions: [
          _buildThemeToggle(),
          IconButton(
            onPressed: () => PopupHelper.tambahDompet(context, _isDarkMode, _refresh),
            icon: Icon(Icons.add_circle_outline, color: _isDarkMode ? Colors.blueAccent : Colors.blue),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: ModernDrawer(
        txtCol: txtCol, cardCol: cardCol, isDarkMode: _isDarkMode,
        currentUser: _currentUser, hideSaldo: _hideSaldo, googleSignIn: _googleSignIn,
        onToggleHideSaldo: (val) => setState(() => _hideSaldo = val),
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
                  onEditBanner: (kntg) => PopupHelper.tampilkanPilihanBanner(context, _isDarkMode, kntg, _refresh),
                  onPilihKurs: () => PopupHelper.tampilkanPilihanKurs(context, _isDarkMode, _allRates, _mataUangAktif, (code) => setState(() => _mataUangAktif = code)),
                ),
                ActionButtons(
                  txtCol: txtCol,
                  onMasuk: () => PopupHelper.bukaForm(context: context, isDarkMode: _isDarkMode, tabunganId: daftarKantong[indexTerpilih]['id'], saldoSekarang: (daftarKantong[indexTerpilih]['saldo'] ?? 0).toDouble(), tipe: "Masuk", onRefresh: _refresh),
                  onKeluar: () => PopupHelper.bukaForm(context: context, isDarkMode: _isDarkMode, tabunganId: daftarKantong[indexTerpilih]['id'], saldoSekarang: (daftarKantong[indexTerpilih]['saldo'] ?? 0).toDouble(), tipe: "Keluar", onRefresh: _refresh),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Riwayat Terkini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: txtCol)),
                          Icon(Icons.history, size: 18, color: txtCol.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: txtCol.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 20)),
                    const SizedBox(height: 5),
                  ],
                ),
                RiwayatList(
                  riwayatTransaksi: riwayatTransaksi, txtCol: txtCol, cardCol: cardCol,
                  onEdit: (trx) => PopupHelper.bukaForm(context: context, isDarkMode: _isDarkMode, tabunganId: daftarKantong[indexTerpilih]['id'], saldoSekarang: (daftarKantong[indexTerpilih]['saldo'] ?? 0).toDouble(), dataLama: trx, onRefresh: _refresh),
                  onHapus: (trx) => _hapusTrx(trx),
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