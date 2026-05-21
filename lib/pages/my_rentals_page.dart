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

      showMessage('Tidak bisa terhubung ke server.');
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
    if (status == 'ending_soon') return const Color(0xFF16A34A);
    if (status == 'active') return const Color(0xFF16A34A);

    return const Color(0xFF64748B);
  }

  Color statusBgColor(String status) {
    if (status == 'expired') return const Color(0xFFFEE2E2);
    if (status == 'ends_today') return const Color(0xFFFFF7ED);
    if (status == 'ending_soon') return const Color(0xFFDCFCE7);
    if (status == 'active') return const Color(0xFFDCFCE7);

    return const Color(0xFFE2E8F0);
  }

  String statusBadgeText(String status, dynamic daysLeft) {
    final days = int.tryParse(daysLeft?.toString() ?? '');

    if (status == 'expired') {
      if (days != null && days < 0) {
        return '• Telat ${days.abs()} hari';
      }
      return '• Telat bayar';
    }

    if (status == 'ends_today') {
      return '• Hari ini';
    }

    if (days != null && days > 0) {
      return '• $days hari lagi';
    }

    if (status == 'active') {
      return '• Aktif';
    }

    return '• -';
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
      backgroundColor: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 26),
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
    final daysLeft = rental['days_left'];

    final color = statusColor(status);
    final bgColor = statusBgColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(28, 26, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kamar?['nama'] ?? 'Kamar',
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Rafa Kost,Purwokerto',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusBadgeText(status, daysLeft),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // INVOICE BADGE
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'INV: ${rental['invoice'] ?? '-'}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 22),

          infoRow('Tanggal Masuk', rental['tanggal_masuk'] ?? '-'),
          infoRow('Tanggal Habis', rental['tanggal_habis'] ?? '-'),
          infoRow('Durasi', '${rental['durasi'] ?? '-'} Bulan'),
          infoRow('Jumlah orang', '${rental['orang'] ?? '-'} Orang'),

          if (status == 'expired') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Denda akan dihitung otomatis saat membuat invoice perpanjangan.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  fontSize: 12,
                ),
              ),
            ),
          ],

          if (shouldShowRenewButton(status)) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  openRenewPage(rental);
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(
                  renewButtonText(status),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
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
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8F8F8F),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF8F8F8F),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}