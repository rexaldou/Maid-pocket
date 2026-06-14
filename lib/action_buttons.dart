import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final Color txtCol;
  final VoidCallback onMasuk;
  final VoidCallback onKeluar;

  const ActionButtons({
    super.key,
    required this.txtCol,
    required this.onMasuk,
    required this.onKeluar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _btnAction("Masuk", Icons.add, Colors.green, onMasuk, txtCol),
        _btnAction("Keluar", Icons.remove, Colors.red, onKeluar, txtCol),
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