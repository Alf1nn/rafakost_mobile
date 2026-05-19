import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'payment_methods_page.dart';

class RenewRentalPage extends StatefulWidget {
  final Map rental;

  const RenewRentalPage({
    super.key,
    required this.rental,
  });

  @override
  State<RenewRentalPage> createState() => _RenewRentalPageState();
}

class _RenewRentalPageState extends State<RenewRentalPage> {
  bool loading = false;

  int durasi = 1;
  int orang = 1;

  String rupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;

    return 'Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  Future<void> submitRenew() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      showMessage('Token tidak ditemukan. Silakan login ulang.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final rentalId = widget.rental['id'];

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/my-rentals/$rentalId/renew'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'durasi': durasi,
              'orang': orang,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final invoice = data['booking']['invoice'];

        showMessage(data['message'] ?? 'Invoice perpanjangan berhasil dibuat.');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentMethodsPage(invoice: invoice),
          ),
        );
      } else {
        showMessage(data['message'] ?? 'Gagal membuat invoice perpanjangan.');
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Tidak bisa terhubung ke server: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kamar = widget.rental['kamar'];
    final daysLeft = widget.rental['days_left'];
    final status = widget.rental['status_masa_sewa'];

    final isLate = daysLeft != null && daysLeft < 0;
    final lateDays = isLate ? (daysLeft.abs()) : 0;
    final estimatedFine = lateDays * 10000;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Perpanjang Sewa',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kamar',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kamar?['nama'] ?? 'Kamar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${kamar?['lantai'] ?? '-'} • Kamar mandi ${kamar?['kamar_mandi'] ?? '-'}',
                  style: const TextStyle(
                    color: Color(0xFFDBEAFE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                row('Invoice lama', widget.rental['invoice'] ?? '-'),
                row('Tanggal masuk', widget.rental['tanggal_masuk'] ?? '-'),
                row('Tanggal habis', widget.rental['tanggal_habis'] ?? '-'),
                row('Status', statusText(status, daysLeft)),
              ],
            ),
          ),

          if (isLate) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Masa sewa sudah telat $lateDays hari. Estimasi denda: ${rupiah(estimatedFine)}. Denda final akan dihitung oleh server saat invoice dibuat.',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Durasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: durasi,
                  decoration: inputDecoration(),
                  items: List.generate(12, (index) {
                    final value = index + 1;
                    return DropdownMenuItem(
                      value: value,
                      child: Text('$value Bulan'),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      durasi = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                const Text(
                  'Jumlah Orang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: orang,
                  decoration: inputDecoration(),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('1 Orang'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('2 Orang'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      orang = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: loading ? null : submitRenew,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.receipt_long_rounded),
              label: Text(
                loading ? 'Membuat Invoice...' : 'Buat Invoice Perpanjangan',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
      ),
    );
  }

  Widget row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String statusText(dynamic status, dynamic daysLeft) {
    if (status == 'expired') {
      return 'Telat ${daysLeft.abs()} hari';
    }

    if (status == 'ends_today') {
      return 'Berakhir hari ini';
    }

    if (status == 'ending_soon') {
      return 'Sisa $daysLeft hari';
    }

    if (status == 'active') {
      return 'Aktif';
    }

    return '-';
  }
}