import 'dart:io'; // 🌸 Buat baca gambar banner dari memori HP
import 'dart:async'; // 🌸 Buat fitur Timer 5 detiknya
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'apptheme_helper.dart';
import 'currency.dart';

// --- CLASS UTAMA DOMPET ---
class Walletcard extends StatelessWidget {
  final List<Map<String, dynamic>> daftarKantong;
  final bool isDarkMode;
  final PageController pageController;
  final String mataUangAktif;
  final bool hideSaldo;
  final Map<String, dynamic> allRates;

  final Function(int) onPageChanged;
  final Function(Map<String, dynamic>) onEditBanner;
  final VoidCallback onPilihKurs;

  const Walletcard({
    super.key,
    required this.daftarKantong,
    required this.isDarkMode,
    required this.pageController,
    required this.mataUangAktif,
    required this.hideSaldo,
    required this.allRates,
    required this.onPageChanged,
    required this.onEditBanner,
    required this.onPilihKurs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: pageController,
        itemCount: daftarKantong.length,
        onPageChanged: onPageChanged,
        itemBuilder: (ctx, i) {
          var kntg = daftarKantong[i];

          // 1. Ambil data dompet mentah
          double saldoAsli = (kntg['saldo'] ?? 0).toDouble();
          double batasKuning = (kntg['limit_kuning'] ?? 50000).toDouble();
          double batasHijau = (kntg['limit_hijau'] ?? 500000).toDouble();

          // 2. Panggil status tema
          int status = Temapp.getStatus(saldoAsli, batasKuning, batasHijau);

          // 3. Logika warna saldo otomatis
          Color warnaSaldoTxt = isDarkMode ? Colors.white : Colors.black;
          if (saldoAsli <= batasKuning) {
            warnaSaldoTxt = Colors.redAccent;
          } else if (saldoAsli <= batasHijau) {
            warnaSaldoTxt = Colors.orangeAccent;
          }

          List<Color> grad = Temapp.getAdaptiveGradient(status, kntg['tema_id'] ?? 0, isDarkMode);

          return AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double value = 1.0;
              if (pageController.position.haveDimensions) {
                value = pageController.page! - i;
                value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
              }
              return Transform.scale(
                scale: Curves.easeOut.transform(value),
                child: Opacity(opacity: value.clamp(0.4, 1.0), child: child),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: grad[0].withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: kntg['banner_path'] != null
                    ? DecorationImage(
                        image: FileImage(File(kntg['banner_path'])),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.black.withValues(alpha: kntg['banner_path'] != null ? 0.5 : 0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kntg['nama'].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            letterSpacing: 1.5,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                          onPressed: () => onEditBanner(kntg),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        InkWell(
                          onTap: onPilihKurs,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  mataUangAktif,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: hideSaldo
                                ? Text(
                                    "••••••••",
                                    style: TextStyle(
                                      color: warnaSaldoTxt,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : AnimatedCounter(
                                    value: CurrencyLogic.getConvertedSaldo(saldoAsli, mataUangAktif, allRates),
                                    prefix: mataUangAktif,
                                    style: TextStyle(
                                      color: warnaSaldoTxt,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 🌸 PANGGIL WIDGET ANIMASI MOOD DI SINI
                    MoodQuoteWidget(
                      idKantong: kntg['id'].toString(),
                      saldoSekarang: saldoAsli,
                      statusSekarang: status,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- CLASS ANIMASI MOOD TEXT (Punya Otak Sendiri) ---
class MoodQuoteWidget extends StatefulWidget {
  final String idKantong;
  final double saldoSekarang;
  final int statusSekarang;

  const MoodQuoteWidget({
    super.key,
    required this.idKantong,
    required this.saldoSekarang,
    required this.statusSekarang,
  });

  @override
  State<MoodQuoteWidget> createState() => _MoodQuoteWidgetState();
}

class _MoodQuoteWidgetState extends State<MoodQuoteWidget> {
  bool isShowingTemp = false;
  String tempMessage = "";
  // ignore: unused_field
  double _saldoSebelumnya = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _saldoSebelumnya = widget.saldoSekarang;
  }

  @override
  void didUpdateWidget(MoodQuoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kalau dompetnya sama tapi saldonya berubah, trigger animasi slide!
    if (oldWidget.idKantong == widget.idKantong && oldWidget.saldoSekarang != widget.saldoSekarang) {
      if (widget.saldoSekarang < oldWidget.saldoSekarang) {
        tempMessage = "💸 Waduh, uangnya keluar Senpai...";
      } else {
        tempMessage = "✨ Asik, dapet asupan dana!";
      }

      setState(() {
        isShowingTemp = true;
        _saldoSebelumnya = widget.saldoSekarang;
      });

      // Mulai hitung mundur 5 detik secara rahasia
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            isShowingTemp = false; // Kembalikan ke teks motivasi normal
          });
        }
      });
    } else if (oldWidget.idKantong != widget.idKantong) {
       // Reset kalau user geser ke kartu dompet lain
       _saldoSebelumnya = widget.saldoSekarang;
       isShowingTemp = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String fixedQuote = Temapp.getQuotes(widget.statusSekarang);
    IconData iconQuote = Temapp.getQuoteIcon(widget.statusSekarang);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Efek geser (slide) dari bawah ke atas lengkap sama efek pudar
        final slideAnim = Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(animation);
        return SlideTransition(position: slideAnim, child: FadeTransition(opacity: animation, child: child));
      },
      child: isShowingTemp
          ? _buildTextLayout(
              Key('temp_${widget.idKantong}'),
              Icons.notifications_active,
              tempMessage,
              Colors.orangeAccent,
            )
          : _buildTextLayout(
              Key('fixed_${widget.idKantong}'),
              iconQuote,
              fixedQuote,
              Colors.white,
            ),
    );
  }

  Widget _buildTextLayout(Key key, IconData icon, String text, Color color) {
    return Row(
      key: key,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

// --- CLASS ANIMASI ANGKA ---
class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.prefix = 'Rp',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutExpo,
      builder: (context, double val, child) {
        String formatAngka = NumberFormat.simpleCurrency(
          name: prefix,
          decimalDigits: (prefix == 'IDR' || prefix == 'JPY' || prefix == 'KRW') ? 0 : 2,
        ).format(val);
        return Text(formatAngka, style: style);
      },
    );
  }
}