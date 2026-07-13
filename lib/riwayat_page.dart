import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'database_helper.dart';
import 'riwayat_list.dart';
import 'popup_dialog.dart';
import 'biometric.dart';

class RiwayatPage extends StatefulWidget {
  final int tabunganId;
  final bool isDarkMode;
  final bool biometricAktif;
  final VoidCallback onDataBerubah;

  const RiwayatPage({
    super.key,
    required this.tabunganId,
    required this.isDarkMode,
    required this.biometricAktif,
    required this.onDataBerubah,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<Map<String, dynamic>> riwayatTransaksi = [];
  String _kataKunci = "";
  
  // 🌸 Filter State
  String _filterKategori = 'Semua';
  String _filterBulan = 'Semua';
  String _filterTahun = 'Semua';
  
  List<String> _listTahun = ['Semua'];
  final List<String> _listBulan = [
    'Semua', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final data = await DatabaseHelper.instance.ambilRiwayat(widget.tabunganId);
    
    // 🌸 Extract Tahun Otomatis dari Data
    Set<String> tahunSet = {};
    for (var trx in data) {
      if (trx['created_at'] != null) {
        DateTime dt = DateTime.parse(trx['created_at']);
        tahunSet.add(dt.year.toString());
      }
    }
    
    List<String> tahunUrut = tahunSet.toList()..sort((a, b) => b.compareTo(a)); // Urut dari terbaru

    if (!mounted) return;
    setState(() {
      riwayatTransaksi = data;
      _listTahun = ['Semua', ...tahunUrut];
      _isLoading = false;
    });
  }

  void _hapusTrx(Map<String, dynamic> trx) async {
    await DatabaseHelper.instance.hapusTransaksi(trx['id']);
    final dompet = await DatabaseHelper.instance.database.then((db) => db.query('tabungan', where: 'id = ?', whereArgs: [widget.tabunganId]));
    if (dompet.isNotEmpty) {
      double saldoSkrg = (dompet.first['saldo'] as num).toDouble();
      await DatabaseHelper.instance.updateSaldo(widget.tabunganId, saldoSkrg - trx['amount']);
    }
    widget.onDataBerubah();
    _muatData();
  }

  // 🌸 Logika Filter Cerdas
  List<Map<String, dynamic>> _getFilteredData() {
    return riwayatTransaksi.where((trx) {
      final catatan = (trx['notes'] ?? "").toString().toLowerCase();
      bool lolosTeks = catatan.contains(_kataKunci.toLowerCase());
      
      String kat = trx['kategori'] ?? 'Umum';
      bool lolosKategori = _filterKategori == 'Semua' || kat == _filterKategori;
      
      bool lolosBulan = true;
      bool lolosTahun = true;

      if (trx['created_at'] != null) {
        DateTime date = DateTime.parse(trx['created_at']);
        
        if (_filterBulan != 'Semua') {
          String bulanTeks = _listBulan[date.month];
          lolosBulan = bulanTeks == _filterBulan;
        }
        
        if (_filterTahun != 'Semua') {
          lolosTahun = date.year.toString() == _filterTahun;
        }
      }
      return lolosTeks && lolosKategori && lolosBulan && lolosTahun;
    }).toList();
  }

  Future<void> _exportKeCSV() async {
    final dataFiltered = _getFilteredData();

    if (dataFiltered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diexport")),
      );
      return;
    }

    // 🌸 Header CSV Rapi
    String csvData = "ID,Tanggal,Waktu,Kategori,Nominal,Catatan\n";

    for (var trx in dataFiltered) {
      String id = trx['id'].toString();
      String rawDate = trx['created_at'] ?? "";
      String tanggal = "";
      String waktu = "";
      
      if (rawDate.isNotEmpty) {
        DateTime dt = DateTime.parse(rawDate);
        tanggal = DateFormat('dd MMM yyyy').format(dt);
        waktu = DateFormat('HH:mm').format(dt);
      }

      String kategori = trx['kategori'] ?? "Umum";
      String nominal = "Rp ${trx['amount'].abs().toStringAsFixed(0)}";
      String tipe = (trx['amount'] as num) > 0 ? "[Masuk]" : "[Keluar]";
      String catatan = (trx['notes'] ?? "").toString().replaceAll(",", " ");
      
      csvData += "$id,$tanggal,$waktu,$kategori,$tipe $nominal,$catatan\n";
    }

    try {
      final direktori = await getTemporaryDirectory();
      // 🌸 Nama File dinamis biar enak nyarinya
      String namaFile = "Rekap_MaidPocket_${_filterBulan}_$_filterTahun.csv";
      final String pathFile = "${direktori.path}/$namaFile";
      final File file = File(pathFile);
      await file.writeAsString(csvData);
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pathFile)],
          text: 'Laporan Keuangan MaidPocket - $_filterBulan $_filterTahun',
        ),
      );
    } catch (e) {
      debugPrint("Gagal export: $e");
    }
  }

  void _tampilkanFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Color txtColor = widget.isDarkMode ? Colors.white : Colors.black;
            Color bgDrop = widget.isDarkMode ? Colors.black26 : Colors.grey.shade100;
            
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Filter Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: txtColor)),
                  const SizedBox(height: 15),
                  
                  // Kategori
                  Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: txtColor.withValues(alpha: 0.7))),
                  const SizedBox(height: 5),
                  _buildDropdown(bgDrop, txtColor, _filterKategori, ['Semua', 'Umum', 'Makan', 'Transportasi', 'Top-up', 'Tagihan', 'Utang'], (val) {
                    setModalState(() => _filterKategori = val!);
                    setState(() => _filterKategori = val!);
                  }),
                  const SizedBox(height: 10),

                  // Row untuk Bulan & Tahun
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bulan", style: TextStyle(fontWeight: FontWeight.bold, color: txtColor.withValues(alpha: 0.7))),
                            const SizedBox(height: 5),
                            _buildDropdown(bgDrop, txtColor, _filterBulan, _listBulan, (val) {
                              setModalState(() => _filterBulan = val!);
                              setState(() => _filterBulan = val!);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tahun", style: TextStyle(fontWeight: FontWeight.bold, color: txtColor.withValues(alpha: 0.7))),
                            const SizedBox(height: 5),
                            _buildDropdown(bgDrop, txtColor, _filterTahun, _listTahun, (val) {
                              setModalState(() => _filterTahun = val!);
                              setState(() => _filterTahun = val!);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Terapkan Filter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildDropdown(Color bg, Color txt, String val, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          value: val,
          items: items.map((String i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(color: txt)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color txtCol = widget.isDarkMode ? Colors.white : Colors.black87;
    Color bgCol = widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    Color cardCol = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final dataTampil = _getFilteredData();

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text("Semua Riwayat", style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: txtCol),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: txtCol),
            onPressed: _exportKeCSV,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: TextField(
                          style: TextStyle(color: txtCol),
                          decoration: InputDecoration(
                            hintText: "Cari transaksi...",
                            hintStyle: TextStyle(color: txtCol.withValues(alpha: 0.5)),
                            prefixIcon: Icon(Icons.search, color: widget.isDarkMode ? Colors.white54 : Colors.black54),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                          ),
                          onChanged: (val) => setState(() => _kataKunci = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _tampilkanFilter,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 45, width: 45,
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_filterKategori != 'Semua' || _filterBulan != 'Semua' || _filterTahun != 'Semua') ? Colors.blueAccent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.filter_list, size: 22, 
                          color: (_filterKategori != 'Semua' || _filterBulan != 'Semua' || _filterTahun != 'Semua') ? Colors.blueAccent : (widget.isDarkMode ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              if (dataTampil.isEmpty)
                Expanded(child: Center(child: Text("Uhee~ datanya kosong...", style: TextStyle(color: txtCol.withValues(alpha: 0.5)))))
              else
                RiwayatList(
                  riwayatTransaksi: dataTampil,
                  txtCol: txtCol, 
                  cardCol: cardCol,
                  onEdit: (trx) async {
                    bool lolos = widget.biometricAktif ? await BiometricAuth.authenticate() : true; 
                    if (lolos) {
                      if (!context.mounted) return;
                      PopupHelper.tampilkanDetailTransaksi(
                        context: context, 
                        isDarkMode: widget.isDarkMode, 
                        item: trx, 
                        onRefresh: () {
                          widget.onDataBerubah();
                          _muatData();
                        }
                      );
                    }
                  },
                  onHapus: (trx) => _hapusTrx(trx),
                ),
            ],
          ),
    );
  }
}