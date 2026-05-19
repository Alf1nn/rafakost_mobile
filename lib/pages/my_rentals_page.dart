import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'renew_rental_page.dart';

class MyRentalsPage extends StatefulWidget {
  const MyRentalsPage({super.key});

  @override
  State<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage> {
  bool loading = true;
  bool hasError = false;
  List rentals = [];

  @override
  void initState() {
    super.initState();
    fetchRentals();
  }

  Future<void> fetchRentals() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/my-rentals'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          rentals = data['data'] ?? [];
          loading = false;
          hasError = false;
        });
      } else {
        setState(() {
          rentals = [];
          loading = false;
          hasError = true;
        });

        showMessage(data['message'] ?? 'Gagal mengambil data sewa.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        rentals = [];
        loading = false;
        hasError = true;
      });

      showMessage('Tidak bisa terhubung ke server: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color statusColor(String status) {
    if (status == 'expired') return const Color(0xFFDC2626);
    if (status == 'ends_today') return const Color(0xFFD97706);
    if (status == 'ending_soon') return const Color(0xFFF59E0B);
    if (status == 'active') return const Color(0xFF16A34A);

    return const Color(0xFF64748B);
  }

  String statusText(String status) {
    if (status == 'expired') return 'Telat Bayar';
    if (status == 'ends_today') return 'Habis Hari Ini';
    if (status == 'ending_soon') return 'Hampir Habis';
    if (status == 'active') return 'Aktif';

    return '-';
  }

  String daysLeftText(dynamic daysLeft) {
    if (daysLeft == null) {
      return 'Data masa sewa belum lengkap.';
    }

    final days = int.tryParse(daysLeft.toString()) ?? 0;

    if (days < 0) {
      return 'Masa sewa lewat ${days.abs()} hari.';
    }

    if (days == 0) {
      return 'Masa sewa berakhir hari ini.';
    }

    return 'Sisa masa sewa $days hari lagi.';
  }

  bool shouldShowRenewButton(String status) {
    return status == 'expired' ||
        status == 'ends_today' ||
        status == 'ending_soon' ||
        status == 'active';
  }

  String renewButtonText(String status) {
    if (status == 'expired') {
      return 'Perpanjang & Bayar Denda';
    }

    return 'Perpanjang Sewa';
  }

  void openRenewPage(Map rental) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RenewRentalPage(rental: rental),
      ),
    );

    if (!mounted) return;
    fetchRentals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRentals,
              child: buildContent(),
            ),
    );
  }

  Widget buildContent() {
    if (hasError) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.wifi_off_rounded,
            size: 80,
            color: Color(0xFFD97706),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Gagal memuat kamar saya',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Periksa koneksi internet atau server Rafa Kost.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: fetchRentals,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      );
    }

    if (rentals.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Belum ada kamar aktif',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Kamar yang sudah dibayar akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = Map<String, dynamic>.from(rentals[index]);
        return rentalCard(rental);
      },
    );
  }

  Widget rentalCard(Map<String, dynamic> rental) {
    final kamar = rental['kamar'];
    final status = rental['status_masa_sewa'] ?? 'unknown';
    final color = statusColor(status);
    final daysLeft = rental['days_left'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kamar?['nama'] ?? 'Kamar',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Invoice: ${rental['invoice'] ?? '-'}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          infoRow('Tanggal Masuk', rental['tanggal_masuk'] ?? '-'),
          infoRow('Tanggal Habis', rental['tanggal_habis'] ?? '-'),
          infoRow('Durasi', '${rental['durasi'] ?? '-'} Bulan'),
          infoRow('Jumlah Orang', '${rental['orang'] ?? '-'} Orang'),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              daysLeftText(daysLeft),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          if (status == 'expired') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Denda akan dihitung otomatis saat membuat invoice perpanjangan.',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],

          if (shouldShowRenewButton(status)) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  openRenewPage(rental);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  renewButtonText(status),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}