import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class Walletcard extends StatelessWidget {
  final List<Map<String, dynamic>> daftarKantong;
  final bool isDarkMode;
  final PageController pageController;
  final String mataUangAktif;
  final bool hideSaldo;

  const Walletcard({
    super.key,
    required this.daftarKantong,
    required this.isDarkMode,
    required this.pageController,
    required this.mataUangAktif,
    required this.hideSaldo;
  });
  

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
          name: prefix, // prefix di sini isinya 'IDR', 'USD', dll
          decimalDigits: (prefix == 'IDR' || prefix == 'JPY' || prefix == 'KRW')
              ? 0
              : 2,
        ).format(val);
        return Text(formatAngka, style: style);
      },
    );
  }
}

  Widget buildWalletSlider() => SizedBox(
    height: 250,
    child: PageView.builder(
      controller: _pageController,
      itemCount: daftarKantong.length,
      onPageChanged: (i) => setState(() {
        indexTerpilih = i;
        _refresh();
      }),
      itemBuilder: (ctx, i) {
        var kntg = daftarKantong[i];
        int status = Temapp.getStatus(
          (kntg['saldo'] ?? 0).toDouble(),
          (kntg['limit_kuning'] ?? 50000).toDouble(),
          (kntg['limit_hijau'] ?? 500000).toDouble(),
        );
        List<Color> grad = Temapp.getAdaptiveGradient(status, kntg['tema_id'] ?? 0);

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
                color: Colors.black.withValues(
                  alpha: kntg['banner_path'] != null ? 0.5 : 0.1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 1. INI JUDUL & TOMBOL EDIT (Sudah dikembalikan!)
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
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => tampilkanPilihanBanner(kntg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 🔥 2. INI TOMBOL DROPDOWN NEGARA & SALDO (160+ Mata Uang)
                  Row(
                    children: [
                      InkWell(
                        onTap: () => tampilkanPilihanKurs(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                mataUangAktif,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 20,
                              ),
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
                              ? const Text(
                                  "••••••••",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : AnimatedCounter(
                                  value: getConvertedSaldo(
                                    (kntg['saldo'] ?? 0).toDouble(),
                                  ),
                                  prefix: mataUangAktif,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 🔥 3. INI QUOTES
                  Row(
                    children: [
                      Icon(
                        Temapp.getQuoteIcon(status),
                        color: const Color.fromARGB(255, 122, 24, 24),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          Temapp.getQuotes(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
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