import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'analytic_page.dart';

class StatistikChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isDarkMode;

  const StatistikChart({super.key, required this.data, required this.isDarkMode});

  Color _getWarnaKategori(String kategori) {
    switch (kategori) {
      case 'Makan': return Colors.orange;
      case 'Transportasi': return Colors.amber;
      case 'Top-up': return Colors.purple;
      case 'Tagihan': return Colors.redAccent;
      case 'Utang': return Colors.red.shade900;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> totalPerKategori = {};
    double totalKeluar = 0.0;

    for (var trx in data) {
      double nom = (trx['amount'] ?? 0).toDouble();
      if (nom < 0) {
        String kat = trx['kategori'] ?? 'Umum';
        totalPerKategori[kat] = (totalPerKategori[kat] ?? 0) + nom.abs();
        totalKeluar += nom.abs();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnalyticPage(data: data, isDarkMode: isDarkMode)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
            ]
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: totalKeluar == 0
                    ? const Icon(Icons.pie_chart_outline, color: Colors.grey, size: 30)
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 18,
                          sections: totalPerKategori.entries.map((e) {
                            return PieChartSectionData(
                              value: e.value,
                              color: _getWarnaKategori(e.key),
                              radius: 12,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Analitik Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(totalKeluar == 0 ? "Belum ada data" : "Klik untuk melihat rincian", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.white54 : Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}