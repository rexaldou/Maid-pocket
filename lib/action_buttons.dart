import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final Color txtCol;
  final VoidCallback onMasuk;
  final VoidCallback onKeluar;
  final VoidCallback onTransfer; // 🌸 Tambahin colokan ini

  const ActionButtons({
    super.key,
    required this.txtCol,
    required this.onMasuk,
    required this.onKeluar,
    required this.onTransfer, // 🌸 Tambahin ini juga
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 🌸 Ini udah otomatis bikin jaraknya rapi
      children: [
        _btnAction("Masuk", Icons.add, Colors.green, onMasuk, txtCol),
        _btnAction("Keluar", Icons.remove, Colors.red, onKeluar, txtCol),
        _btnAction("Transfer", Icons.swap_horiz, Colors.blue, onTransfer, txtCol), // 🌸 Tombol transfer nyusul di sini
      ],
    );
  }

  Widget _btnAction(String t, IconData i, Color c, VoidCallback o, Color txtCol) {
    return InkWell(
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
  }
}