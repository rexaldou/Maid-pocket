import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Tambahan buat jembatan
import 'dart:io'; // Tambahan buat ngecek sistem operasi
import 'package:flutter/foundation.dart'; // Tambahan buat ngecek Web
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- KODE SAKTI ANTI ERROR FFI ---
  // Kita cek: Kalau bukan di Web, dan lagi jalan di Windows/Linux/Mac, pake jembatan FFI
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // ----------------------------------

  runApp(const MaidPocketApp());
}

class MaidPocketApp extends StatelessWidget {
  const MaidPocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaidPocket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
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
  bool isSaldoSembunyi = false;

  final List<IconData> pilihanIkon = [
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.account_balance,
    Icons.savings,
  ];

  @override
  void initState() {
    super.initState();
    _refreshData(); // Ambil data pas aplikasi dibuka
  }

  void _refreshData() async {
    final data = await DatabaseHelper.instance.ambilSemuaTabungan();
    setState(() {
      daftarKantong = data;
    });
  }

  void _tambahKantongBaru() {
    TextEditingController namaCtrl = TextEditingController();
    IconData ikonTerpilih = pilihanIkon[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              "Bikin Tabungan Baru",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  children: pilihanIkon.map((icon) {
                    bool isSelected = ikonTerpilih == icon;
                    return ChoiceChip(
                      label: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.blueAccent,
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      onSelected: (selected) =>
                          setDialogState(() => ikonTerpilih = icon),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (namaCtrl.text.isNotEmpty) {
                    await DatabaseHelper.instance.tambahTabungan({
                      'nama': namaCtrl.text,
                      'saldo': 0.0,
                      'icon':
                          ikonTerpilih.codePoint, // Simpan ikon sebagai angka
                    });
                    _refreshData(); // Update layar
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _hapusKantong(int id) async {
    await DatabaseHelper.instance.hapusTabungan(id);
    _refreshData();
  }

  void _tampilkanPanelInput() {
    if (daftarKantong.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bikin tabungan dulu!")));
      return;
    }

    double nominal = 0;
    String tipeTransaksi = 'Pemasukan';
    int indexTerpilih = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Catat Transaksi 💸",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Pemasukan',
                        label: Text('Pemasukan'),
                      ),
                      ButtonSegment(
                        value: 'Pengeluaran',
                        label: Text('Pengeluaran'),
                      ),
                    ],
                    selected: {tipeTransaksi},
                    onSelectionChanged: (val) =>
                        setModalState(() => tipeTransaksi = val.first),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: indexTerpilih,
                    decoration: const InputDecoration(
                      labelText: "Pilih Tabungan",
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(daftarKantong.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(daftarKantong[index]['nama']),
                      );
                    }),
                    onChanged: (val) =>
                        setModalState(() => indexTerpilih = val ?? 0),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Nominal",
                      prefixText: "Rp ",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      nominal = double.tryParse(val.replaceAll('.', '')) ?? 0;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nominal > 0) {
                          var kantong = daftarKantong[indexTerpilih];
                          double saldoBaru = kantong['saldo'];

                          if (tipeTransaksi == 'Pemasukan') {
                            saldoBaru += nominal;
                          } else {
                            if (saldoBaru >= nominal) {
                              saldoBaru -= nominal;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Saldo ga cukup uhee~"),
                                ),
                              );
                              return;
                            }
                          }

                          await DatabaseHelper.instance.updateSaldo(
                            kantong['id'],
                            saldoBaru,
                          );
                          _refreshData();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        "Simpan Transaksi",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "MaidPocket 🧹",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isSaldoSembunyi ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => isSaldoSembunyi = !isSaldoSembunyi),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.blueAccent,
            ),
            onPressed: _tambahKantongBaru,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (daftarKantong.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  "Belum ada tabungan, bikin dulu yuk~",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: daftarKantong.length,
                itemBuilder: (context, index) {
                  var kantong = daftarKantong[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.blueAccent,
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Ikon diambil dari angka database
                              Icon(
                                IconData(
                                  kantong['icon'],
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: Colors.white,
                                size: 30,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white70,
                                ),
                                onPressed: () => _hapusKantong(kantong['id']),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            kantong['nama'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isSaldoSembunyi
                                ? "Rp ***.***"
                                : "Rp ${kantong['saldo'].toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.blueAccent,
        onPressed: _tampilkanPanelInput,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home_filled, color: Colors.blueAccent),
                onPressed: () {},
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
