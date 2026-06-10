import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'database_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'apptheme_helper.dart';
import 'walletcard.dart';
import 'currency.dart';


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
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String _mataUangAktif = 'IDR';
  Map<String, dynamic> _allRates = {'IDR': 1.0};

  String _kategoriterpilih = 'Umum';
  final List<String> _listkategori =['Umum','Makan','Transportasi','Top-up','Tagihan','Utang'];

  @override
  void initState() {
    super.initState();
    CurrencyProvider.loadKursLokal();
    CurrencyProvider.fetchKursOtomatis();

    _pageController = PageController(viewportFraction: 0.85);
    _refresh();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
      });
      if (account != null) _autoBackupCloud();
    });
    _googleSignIn.signInSilently();
  }

  // --- LOGIKA DATABASE & CLOUD ---
  void _refresh() async {
    final data = await DatabaseHelper.instance.ambilSemuaTabungan();
    if (data.isNotEmpty) {
      if (indexTerpilih >= data.length) indexTerpilih = 0;
      final log = await DatabaseHelper.instance.ambilRiwayat(
        data[indexTerpilih]['id'],
      );
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

  Future<void> _autoBackupCloud() async {
    if (_currentUser == null) return;
    final List<ConnectivityResult> connectRes = await Connectivity()
        .checkConnectivity();
    if (connectRes.contains(ConnectivityResult.none)) return;
    final firestore = FirebaseFirestore.instance;
    final String uid = _currentUser!.id;
    final lokalKantong = await DatabaseHelper.instance.ambilSemuaTabungan();
    for (var kntg in lokalKantong) {
      final String idDompet = kntg['id'].toString();
      await firestore
          .collection('users')
          .doc(uid)
          .collection('dompet')
          .doc(idDompet)
          .set({
            'nama': kntg['nama'],
            'saldo': kntg['saldo'],
            'limit_kuning': kntg['limit_kuning'],
            'limit_hijau': kntg['limit_hijau'],
            'tema_id': kntg['tema_id'],
          });
      final lokalTrx = await DatabaseHelper.instance.ambilRiwayat(kntg['id']);
      for (var trx in lokalTrx) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('dompet')
            .doc(idDompet)
            .collection('transaksi')
            .doc(trx['id'].toString())
            .set({
              'amount': trx['amount'],
              'notes': trx['notes'],
              'created_at': trx['created_at'],
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color currentBg = _isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF8F9FA);
    final Color txtCol = _isDarkMode ? Colors.white : Colors.black87;
    final Color cardCol = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          "MaidPocket",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: txtCol,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: txtCol),
        actions: [
          _buildThemeToggle(),
          IconButton(
            onPressed: _tambahDompet,
            icon: Icon(
              Icons.add_circle_outline,
              color: _isDarkMode ? Colors.blueAccent : Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildModernDrawer(txtCol, cardCol),
      body: daftarKantong.isEmpty
          ? _buildEmptyState(txtCol)
          : Column(
              children: [
                Walletcard._buildWalletSlider(),
                _buildActionButtons(txtCol),
                const SizedBox(height: 10),
                _buildRiwayatHeader(txtCol),
                _buildRiwayatList(txtCol, cardCol),
              ],
            ),
    );
  }

  // --- DRAWER DENGAN TEKS ANTI-HILANG ---
  Widget _buildModernDrawer(Color txtCol, Color cardCol) {
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
              color: _isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.blueAccent.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: _currentUser?.photoUrl != null
                      ? NetworkImage(_currentUser!.photoUrl!)
                      : null,
                  child: _currentUser == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  _currentUser?.displayName ?? "User Offline",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: txtCol,
                  ),
                ),
                Text(
                  _currentUser?.email ?? "Sinkronkan data ke Cloud",
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
            _currentUser != null ? "Aktif" : "Nonaktif (Login Required)",
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
              _hideSaldo
                  ? "Aktif (Saldo Disensor)"
                  : "Nonaktif (Saldo Terlihat)",
              style: TextStyle(
                fontSize: 11,
                color: txtCol.withValues(alpha: 0.7),
              ),
            ),
            trailing: Switch(
              value: _hideSaldo,
              activeThumbColor: Colors.orange,
              onChanged: (val) => setState(() => _hideSaldo = val),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _currentUser == null
                    ? Colors.green
                    : Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _currentUser == null
                    ? _googleSignIn.signIn()
                    : _googleSignIn.disconnect();
              },
              icon: Icon(_currentUser == null ? Icons.login : Icons.logout),
              label: Text(
                _currentUser == null ? "Hubungkan ke Google" : "Putuskan Akun",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData i, String t, String sub, Color c, Color txtCol) =>
      ListTile(
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

  Widget _buildThemeToggle() => GestureDetector(
    onTap: () => setState(() => _isDarkMode = !_isDarkMode),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _isDarkMode ? Colors.blueGrey.shade900 : Colors.grey.shade300,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        alignment: _isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(
            _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
            size: 12,
            color: _isDarkMode ? Colors.black : Colors.orange,
          ),
        ),
      ),
    ),
  );



  Widget _buildActionButtons(Color txtCol) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _btnAction(
        "Masuk",
        Icons.add,
        Colors.green,
        () => _inputTransaksi(tipe: "Masuk"),
        txtCol,
      ),
      _btnAction(
        "Keluar",
        Icons.remove,
        Colors.red,
        () => _inputTransaksi(tipe: "Keluar"),
        txtCol,
      ),
    ],
  );

  Widget _btnAction(
    String t,
    IconData i,
    Color c,
    VoidCallback o,
    Color txtCol,
  ) => InkWell(
    onTap: o,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(i, color: c, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          t,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: txtCol,
          ),
        ),
      ],
    ),
  );

  IconData _getIkonKategori(String kategori) {
    switch (kategori) {
      case 'Makan': return Icons.fastfood;
      case 'Transportasi': return Icons.directions_car;
      case 'Top-up': return Icons.account_balance_wallet;
      case 'Tagihan': return Icons.receipt_long;
      default: return Icons.category; //Inih ikon yang umum,kurang Utang
    }
  }

  Widget _buildRiwayatHeader(Color txtCol) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Riwayat Terkini",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: txtCol,
              ),
            ),
            Icon(Icons.history, size: 18, color: txtCol.withValues(alpha: 0.6)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        height: 1,
        color: txtCol.withValues(alpha: 0.1),
        margin: const EdgeInsets.symmetric(horizontal: 20),
      ), // PEMBATAS VISUAL
      const SizedBox(height: 5),
    ],
  );

  Widget _buildRiwayatList(Color txtCol, Color cardCol) => Expanded(
    child: ListView.builder(
      itemCount: riwayatTransaksi.length,
      itemBuilder: (ctx, i) {
        var trx = riwayatTransaksi[i];
        bool inc = trx['amount'] >= 0;
        return Dismissible(
          key: Key(trx['id'].toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (dir) => _hapusTrx(trx),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: cardCol,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ListTile(
              onTap: () => _inputTransaksi(dataLama: trx),
              leading: CircleAvatar(
                backgroundColor: (inc ? Colors.green : Colors.red).withValues(
                  alpha: 0.1,
                ),
                child: Icon(
                  _getIkonKategori(trx['kategori'] ?? 'Umum'),
                  color: inc? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
              title: Text(
                trx['notes'] == ""
                    ? (inc ? "Pemasukan" : "Pengeluaran")
                    : trx['notes'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: txtCol,
                ),
              ),
              subtitle: Text(
                DateFormat(
                  'dd MMM, HH:mm',
                ).format(DateTime.parse(trx['created_at'])),
                style: TextStyle(
                  fontSize: 11,
                  color: txtCol.withValues(alpha: 0.6),
                ),
              ),
              trailing: Text(
                DatabaseHelper.instance.formatRupiah(trx['amount'].abs()),
                style: TextStyle(
                  color: inc ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildEmptyState(Color txtCol) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
        const SizedBox(height: 10),
        Text(
          "Uhee~ dompetnya masih kosong, Senpai!",
          style: TextStyle(color: txtCol.withValues(alpha: 0.6)),
        ),
      ],
    ),
  );

  void _hapusTrx(Map<String, dynamic> trx) async {
    await DatabaseHelper.instance.hapusTransaksi(trx['id']);
    await DatabaseHelper.instance.updateSaldo(
      daftarKantong[indexTerpilih]['id'],
      daftarKantong[indexTerpilih]['saldo'] - trx['amount'],
    );
    _refresh();
  }

  void _inputTransaksi({Map<String, dynamic>? dataLama, String? tipe}) {
    double nom = dataLama != null ? dataLama['amount'].abs() : 0;
    _nominalController.text = nom == 0 ? "" : nom.toStringAsFixed(0);
    _catatanController.text = dataLama?['notes'] ?? "";
    _kategoriterpilih = dataLama?
    ['kategori']?? 'Umum';
    DateTime tgl = dataLama != null
        ? DateTime.parse(dataLama['created_at'])
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dataLama != null ? "Edit Transaksi" : "Tambah $tipe",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: "Nominal (Rp)",
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value:_listkategori.contains(_kategoriterpilih)?_kategoriterpilih:'Umum',
              dropdownColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,style: TextStyle(color:_isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Kategori",
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
              ),
              items:_listkategori.map((kat)=>
              DropdownMenuItem(
                value: kat,
                child: Row (
                  children:[
                    Icon(_getIkonKategori(kat),size:18,color:Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(kat),
                  ],
                ),
                )).toList(),
                onChanged: (val){
                  if (val!= null) setModal(()=> _kategoriterpilih = val);
                },
                ),
                const SizedBox (height: 10),
              ListTile(
                leading: Icon(
                  Icons.calendar_month,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  DateFormat('dd MMMM yyyy').format(tgl),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: tgl,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setModal(() => tgl = d);
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  String teksbersih = _nominalController.text.replaceAll(
                    '.',
                    '',
                  );
                  double n = double.tryParse(teksbersih) ?? 0;
                  if (n > 0) {
                    if (dataLama == null) {
                      await DatabaseHelper.instance.tambahTransaksi({
                        'tabungan_id': daftarKantong[indexTerpilih]['id'],
                        'amount': tipe == 'Masuk' ? n : -n,
                        'notes': _catatanController.text,
                        'kategori': _kategoriterpilih,
                        'created_at': tgl.toIso8601String(),
                      });
                      await DatabaseHelper.instance.updateSaldo(
                        daftarKantong[indexTerpilih]['id'],
                        daftarKantong[indexTerpilih]['saldo'] +
                            (tipe == 'Masuk' ? n : -n),
                      );
                    } else {
                      double diff =
                          (dataLama['amount'] >= 0 ? n : -n) -
                          dataLama['amount'];
                      await DatabaseHelper.instance.updateTransaksi(
                        dataLama['id'],
                        dataLama['amount'] >= 0 ? n : -n,
                        _catatanController.text,
                        tgl.toIso8601String(),
                      );
                      await DatabaseHelper.instance.updateSaldo(
                        daftarKantong[indexTerpilih]['id'],
                        daftarKantong[indexTerpilih]['saldo'] + diff,
                      );
                    }
                    _refresh();
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Simpan Transaksi"),
              ),
              if (dataLama != null) ...[
                // TOMBOL HAPUS EKSPLISIT
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red,
                    elevation: 0,
                  ),
                  onPressed: () {
                    _hapusTrx(dataLama);
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Hapus Transaksi",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _tampilkanPilihanBanner(Map<String, dynamic> kntg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.palette,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            title: Text(
              "Ganti Mood Dompet",
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _pilihTema(kntg);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.tune,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            title: Text(
              "Edit Limit Saldo",
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _editLimit(kntg);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.image,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            title: Text(
              "Custom Banner Galeri",
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _handleImagePick(kntg);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Hapus Dompet",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _konfirmasiHapusDompet(kntg);
            },
          ),
        ],
      ),
    );
  }

  void _editLimit(Map<String, dynamic> kntg) {
    double kun = (kntg['limit_kuning'] ?? 50000).toDouble();
    double hij = (kntg['limit_hijau'] ?? 500000).toDouble();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          "Edit Limit Mood",
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Batas Kuning",
                labelStyle: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: kun.toStringAsFixed(0)),
              onChanged: (v) =>
                  kun = double.tryParse(v.replaceAll('.', '')) ?? kun,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: "Batas Hijau",
                labelStyle: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: hij.toStringAsFixed(0)),
              onChanged: (v) =>
                  hij = double.tryParse(v.replaceAll('.', '')) ?? hij,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateLimit(kntg['id'], kun, hij);
              _refresh();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _tampilkanPilihanKurs() {
    List<String> semuaNegara = _allRates.keys.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              "Pilih Mata Uang Global",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: semuaNegara.length,
              itemBuilder: (ctx, i) {
                String code = semuaNegara[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    code,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: _mataUangAktif == code
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _mataUangAktif = code);
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

  void _pilihTema(Map<String, dynamic> kntg) {
    final listTema = [
      {
        "icon": Icons.circle,
        "name": "🎨 Default Mood",
        "color": Colors.blueAccent,
      },
      {"icon": Icons.spa, "name": "🌸 Sakura Mood", "color": Colors.pinkAccent},
      {
        "icon": Icons.water_drop,
        "name": "🌊 Ocean Mood",
        "color": Colors.lightBlue,
      },
      {"icon": Icons.park, "name": "🍂 Autumn Mood", "color": Colors.orange},
      {"icon": Icons.forest, "name": "🌲 Forest Mood", "color": Colors.green},
      {
        "icon": Icons.diamond,
        "name": "🔮 Amethyst Mood",
        "color": Colors.purpleAccent,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: listTema.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: Icon(
            listTema[i]['icon'] as IconData,
            color: listTema[i]['color'] as Color,
          ),
          title: Text(
            listTema[i]['name'] as String,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            DatabaseHelper.instance.updateTema(kntg['id'], i, null);
            _refresh();
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _tambahDompet() {
    String n = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          "Dompet Baru",
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        content: TextField(
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          onChanged: (v) => n = v,
          decoration: InputDecoration(
            hintText: "Nama Dompet",
            hintStyle: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (n.isNotEmpty) {
                await DatabaseHelper.instance.tambahTabungan({
                  'nama': n,
                  'saldo': 0,
                  'limit_kuning': 50000,
                  'limit_hijau': 100000,
                  'tema_id': 0,
                });
                _refresh();
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

  void _konfirmasiHapusDompet(Map<String, dynamic> kntg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          "Hapus Dompet?",
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          "Seluruh riwayat transaksi di dompet ini akan hilang selamanya.",
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.hapusTabungan(kntg['id']);
              _refresh();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImagePick(Map<String, dynamic> kntg) async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: p.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Banner',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: Colors.white,
          ),
        ],
      );
      if (croppedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'banner_${DateTime.now().millisecondsSinceEpoch}.png';
        final File localImage = await File(
          croppedFile.path,
        ).copy('${directory.path}/$fileName');
        await DatabaseHelper.instance.updateTema(
          kntg['id'],
          0,
          localImage.path,
        );
        _refresh();
      }
    }
  }
}
