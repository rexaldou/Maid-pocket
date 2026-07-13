import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class PopupFormTransaksi extends StatefulWidget {
  final bool isDarkMode;
  final int tabunganId;
  final double saldoSekarang;
  final Map<String, dynamic>? dataLama;
  final String? tipe;
  
  // 🌸 Ini colokan remotenya
  final VoidCallback onDataTersimpan;

  const PopupFormTransaksi({
    super.key,
    required this.isDarkMode,
    required this.tabunganId,
    required this.saldoSekarang,
    this.dataLama,
    this.tipe,
    required this.onDataTersimpan,
  });

  @override
  State<PopupFormTransaksi> createState() => _PopupFormTransaksiState();
}

class _PopupFormTransaksiState extends State<PopupFormTransaksi> {
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController(); // Controller ini udah lu siapin
  late DateTime _tgl;
  late String _kategoriterpilih;
  final List<String> _listkategori = ['Umum', 'Makan', 'Transportasi', 'Top-up', 'Tagihan', 'Utang'];

  @override
  void initState() {
    super.initState();
    double nom = widget.dataLama != null ? widget.dataLama!['amount'].abs() : 0;
    _nominalController.text = nom == 0 ? "" : nom.toStringAsFixed(0);
    _catatanController.text = widget.dataLama?['notes'] ?? ""; // Ambil notes lama kalau edit
    _kategoriterpilih = widget.dataLama?['kategori'] ?? 'Umum';
    _tgl = widget.dataLama != null ? DateTime.parse(widget.dataLama!['created_at']) : DateTime.now();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  IconData _getIkonKategori(String kategori) {
    switch (kategori) {
      case 'Makan': return Icons.fastfood;
      case 'Transportasi': return Icons.directions_car;
      case 'Top-up': return Icons.account_balance_wallet;
      case 'Tagihan': return Icons.receipt_long;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 25, right: 25, top: 25,
      ),
      // 🌸 Tambahin SingleChildScrollView di dalam modal biar aman dari keyboard juga
      child: SingleChildScrollView( 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.dataLama != null ? "Edit Transaksi" : "Tambah ${widget.tipe}",
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            
            // --- KOLOM NOMINAL ---
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Nominal (Rp)",
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 10),

            // --- 🌸 KOLOM CATATAN (Ini yang bikin catetan lu selalu kosong wkwkwk) ---
            TextField(
              controller: _catatanController, // Disambungin ke controller
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Catatan (Opsional)",
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 10),

            // --- DROPDOWN KATEGORI ---
            DropdownButtonFormField<String>(
              initialValue: _listkategori.contains(_kategoriterpilih) ? _kategoriterpilih : 'Umum',
              dropdownColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Kategori",
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
              items: _listkategori.map((kat) => DropdownMenuItem(
                value: kat,
                child: Row(
                  children: [
                    Icon(_getIkonKategori(kat), size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(kat),
                  ],
                ),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _kategoriterpilih = val);
              },
            ),
            const SizedBox(height: 10),

            // --- TANGGAL ---
            ListTile(
              leading: Icon(Icons.calendar_month, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              title: Text(
                DateFormat('dd MMMM yyyy').format(_tgl),
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _tgl,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _tgl = d);
              },
            ),
            const SizedBox(height: 15),

            // --- TOMBOL SIMPAN ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String teksbersih = _nominalController.text.replaceAll('.', '');
                double n = double.tryParse(teksbersih) ?? 0;
                
                if (n > 0) {
                  try { // 🌸 BUNGKUS TRY-CATCH BIAR GAK FREEZE
                    if (widget.dataLama == null) {
                      // Tambah Transaksi Baru
                      await DatabaseHelper.instance.tambahTransaksi({
                        'tabungan_id': widget.tabunganId,
                        'amount': widget.tipe == 'Masuk' ? n : -n,
                        'notes': _catatanController.text, // 🌸 Merekam isi catatan!
                        'kategori': _kategoriterpilih,
                        'created_at': _tgl.toIso8601String(),
                      });
                      await DatabaseHelper.instance.updateSaldo(
                        widget.tabunganId,
                        widget.saldoSekarang + (widget.tipe == 'Masuk' ? n : -n),
                      );
                    } else {
                      // Edit Transaksi Lama
                      double diff = (widget.dataLama!['amount'] >= 0 ? n : -n) - widget.dataLama!['amount'];
                      await DatabaseHelper.instance.updateTransaksi(
                        widget.dataLama!['id'],
                        widget.dataLama!['amount'] >= 0 ? n : -n,
                        _catatanController.text, // 🌸 Merekam editan catatan!
                        _tgl.toIso8601String(),
                      );
                      await DatabaseHelper.instance.updateSaldo(
                        widget.tabunganId,
                        widget.saldoSekarang + diff,
                      );
                    }
                    
                    widget.onDataTersimpan();
                    if (!context.mounted) return;
                    Navigator.pop(context); // Sukses nutup
                    
                  } catch (e) {
                    debugPrint("Uhee~ ada yang error pas nyimpen: $e");
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal menyimpan transaksi!")),
                    );
                  }
                }
              },
              child: const Text("Simpan Transaksi"),
            ),

            // --- TOMBOL HAPUS (Hanya tampil kalau edit) ---
            if (widget.dataLama != null) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
                onPressed: () async {
                  try {
                    await DatabaseHelper.instance.hapusTransaksi(widget.dataLama!['id']);
                    await DatabaseHelper.instance.updateSaldo(
                      widget.tabunganId,
                      widget.saldoSekarang - widget.dataLama!['amount'],
                    );
                    widget.onDataTersimpan();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Error Hapus: $e");
                  }
                },
                child: const Text("Hapus Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}