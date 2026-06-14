import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 

class StatistikChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const StatistikChart({super.key, required this.data});

      //Nentuin warna dari Chart kategori masing"
    Color _getWarnaKategori(String kategori) {
      switch (kategori) {
        case 'Makan':
          return Colors.orange;
        case 'Transportasi':
          return Colors.amber;
        case 'Top-Up':
          return Colors.purple;
        case 'Tagihan':
          return Colors.redAccent;
        case 'Utang':
          return Colors.red.shade900;
        default:
          return Colors.blueGrey;
      }
    }


  @override
  Widget build(BuildContext context) {
    Map<String, double> totalPerKategori = {};
    double totalPemasukan = 0.0;
    double totalPengeluaran = 0.0;

    //Buat ngitung total pemasukan dan pengeluaran per kategori
    for (var transaksi in data) {
      double nominal = (transaksi['amount']?? 0).toDouble();
      if (nominal >= 0) { 
        totalPemasukan += nominal;
      }else{
        String kategori = transaksi['kategori'] ?? 'Umum';
        totalPengeluaran += nominal.abs();
        totalPerKategori[kategori] = (totalPerKategori[kategori] ?? 0) + nominal.abs();
      }
    }

    //Total buat dimasukin ke Chart
    double totalSemua = totalPemasukan + totalPengeluaran;

    //if kalo kosong,placeholder tampilanya masih aman ga error
    if (totalSemua == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Waduh belom transaksi,transaksi dulu geh~',
          ),
        ),
      );
    }

    //ini Pie Chartnya, nanti bisa diganti pake package chart yang lebih bagus
    List<PieChartSectionData> sections = [];

    // Potongan chart 1 = PEMASUKAN || INGET BAEK BAEK
    if (totalPemasukan > 0) {
      double pctMasuk = (totalPemasukan / totalSemua) * 100;
      sections.add(
        PieChartSectionData(
          value: totalPemasukan,
          title: 'Pemasukan\n${pctMasuk.toStringAsFixed(1)}%',
          color: Colors.blue,
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    // Potongan chart 2 = PENGELUARAN || JANGAN AMPE KETUKER
    totalPerKategori.forEach((kategori, total) {
      double pctKeluar = (total / totalSemua) * 100;
      sections.add(
        PieChartSectionData(
          value: total,
          title: '$kategori\n${pctKeluar.toStringAsFixed(1)}%',
          color: _getWarnaKategori(kategori),
          radius: 55,
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    //Ini Tampilan Chartnya
    return Container(
      height: 240,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}