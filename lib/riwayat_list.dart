import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class RiwayatList extends StatelessWidget {
  final List<Map<String, dynamic>> riwayatTransaksi;
  final Color txtCol;
  final Color cardCol;
  
  // 🌸 Colokan Remote buat edit dan hapus
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onHapus;

  const RiwayatList({
    super.key,
    required this.riwayatTransaksi,
    required this.txtCol,
    required this.cardCol,
    required this.onEdit,
    required this.onHapus,
  });

  // Fungsi ambil ikon kita pindah ke sini aja biar mandiri
  IconData _getIkonKategori(String kategori) {
    switch (kategori) {
      case 'Makan': return Icons.fastfood;
      case 'Transportasi': return Icons.directions_car;
      case 'Top-up': return Icons.account_balance_wallet;
      case 'Tagihan': return Icons.receipt_long;
      default: return Icons.category;
    }
  }

  // 🌸 INI WUJUD ASLINYA (Wajib pakai "build")
  @override
  Widget build(BuildContext context) {
    return Expanded(
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
            onDismissed: (dir) => onHapus(trx), // 🌸 Mencet remote Hapus
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
                onTap: () => onEdit(trx), // 🌸 Mencet remote Edit (Buka Form)
                leading: CircleAvatar(
                  backgroundColor: (inc ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  child: Icon(
                    _getIkonKategori(trx['kategori'] ?? 'Umum'),
                    color: inc ? Colors.green : Colors.red,
                    size: 18,
                  ),
                ),
                title: Text(
                  trx['notes'] == "" ? (inc ? "Pemasukan" : "Pengeluaran") : trx['notes'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: txtCol,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd MMM, HH:mm').format(DateTime.parse(trx['created_at'])),
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
  }
}