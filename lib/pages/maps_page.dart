import 'package:flutter/material.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: Icon(
              Icons.map_outlined,
              size: 80,
              color: Color(0xFF64748B),
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Lokasi Rafa Kost',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Alamat kos akan ditampilkan di sini. Nanti bisa disambungkan ke Google Maps.',
          style: TextStyle(
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}