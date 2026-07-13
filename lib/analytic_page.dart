import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final bool isDarkMode;

  const AnalyticPage({super.key, required this.data, required this.isDarkMode});

  @override
  State<AnalyticPage> createState() => _AnalyticPageState();
}

class _AnalyticPageState extends State<AnalyticPage> {
  bool _showPercent = true;
  bool _isPieChart = true;

  Color _getWarna(String kategori) {
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
    Map<String, double> katKeluar = {};
    double totalKeluar = 0;

    for (var trx in widget.data) {
      double nom = (trx['amount'] ?? 0).toDouble();
      if (nom < 0) {
        String kat = trx['kategori'] ?? 'Umum';
        katKeluar[kat] = (katKeluar[kat] ?? 0) + nom.abs();
        totalKeluar += nom.abs();
      }
    }

    Color txtCol = widget.isDarkMode ? Colors.white : Colors.black87;
    Color bgCol = widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text("Analitik Dompet", style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: txtCol),
        actions: [
          IconButton(
            icon: Icon(_isPieChart ? Icons.bar_chart : Icons.pie_chart, color: txtCol),
            onPressed: () => setState(() => _isPieChart = !_isPieChart),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: totalKeluar == 0
          ? Center(child: Text("Data pengeluaran masih kosong.", style: TextStyle(color: txtCol)))
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Rp", style: TextStyle(color: !_showPercent ? Colors.blueAccent : Colors.grey, fontWeight: FontWeight.bold)),
                    Switch(
                      value: _showPercent,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (val) => setState(() => _showPercent = val),
                    ),
                    Text("%", style: TextStyle(color: _showPercent ? Colors.blueAccent : Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: _isPieChart 
                    ? PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: katKeluar.entries.map((e) {
                            double pct = (e.value / totalKeluar) * 100;
                            String title = _showPercent 
                                ? "${pct.toStringAsFixed(1)}%" 
                                : NumberFormat.compactCurrency(locale: 'id', symbol: '').format(e.value);
                            return PieChartSectionData(
                              value: e.value,
                              title: title,
                              color: _getWarna(e.key),
                              radius: 60,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  if (value.toInt() >= katKeluar.keys.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      katKeluar.keys.elementAt(value.toInt()).substring(0, 3), // Disingkat 3 huruf biar rapi
                                      style: TextStyle(color: txtCol, fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: katKeluar.entries.toList().asMap().entries.map((entry) {
                            int index = entry.key;
                            var e = entry.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: _getWarna(e.key),
                                  width: 25,
                                  borderRadius: BorderRadius.circular(6),
                                )
                              ]
                            );
                          }).toList(),
                        ),
                      ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: ListView(
                      children: katKeluar.entries.map((e) {
                        double pct = (e.value / totalKeluar) * 100;
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: _getWarna(e.key).withValues(alpha:0.2), child: Icon(Icons.circle, color: _getWarna(e.key), size: 16)),
                          title: Text(e.key, style: TextStyle(color: txtCol, fontWeight: FontWeight.bold)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(e.value), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("${pct.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              ],
            ),
    );
  }
} 