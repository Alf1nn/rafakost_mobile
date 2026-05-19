import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import 'main_navigation_page.dart';

class PaymentPage extends StatefulWidget {
  final Map payment;
  final Map booking;

  const PaymentPage({
    super.key,
    required this.payment,
    required this.booking,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool checking = false;
  late Map payment;
  late Map booking;

  @override
  void initState() {
    super.initState();
    payment = Map.from(widget.payment);
    booking = Map.from(widget.booking);
  }

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

  Future<void> openPaymentUrl() async {
    final paymentUrl = payment['payment_url'] ?? booking['payment_url'];

    if (paymentUrl == null || paymentUrl.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link pembayaran tidak tersedia.'),
        ),
      );
      return;
    }

    final url = Uri.parse(paymentUrl.toString());

    if (!await canLaunchUrl(url)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membuka link pembayaran.'),
        ),
      );
      return;
    }

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> checkStatus() async {
    setState(() {
      checking = true;
    });

    final token = await getToken();
    final invoice = booking['invoice'] ?? payment['invoice'];

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/invoices/$invoice/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          booking = Map.from(data['booking']);
          payment = {
            ...payment,
            ...data['booking'],
          };
        });

        final status = data['booking']['payment_status'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'paid'
                  ? 'Pembayaran berhasil dikonfirmasi.'
                  : 'Status pembayaran masih pending.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal cek status pembayaran.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa cek status pembayaran.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['payment_status'] ?? payment['payment_status'] ?? 'pending';
    final isPaid = status == 'paid';

    final paymentUrl = payment['payment_url'] ?? booking['payment_url'];
    final qrString = payment['qr_string'] ?? booking['qr_string'];

    final hasPaymentUrl = paymentUrl != null && paymentUrl.toString().isNotEmpty;
    final hasQrString = qrString != null && qrString.toString().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPaid
                    ? const [Color(0xFF16A34A), Color(0xFF22C55E)]
                    : const [Color(0xFF2563EB), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rafa Kost',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'NO. INVOICE',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  booking['invoice'] ?? payment['invoice'] ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      color: isPaid
                          ? const Color(0xFF15803D)
                          : const Color(0xFFEA580C),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
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
                row(
                  'Metode',
                  payment['payment_method_name'] ??
                      booking['payment_method_name'] ??
                      '-',
                ),
                row(
                  'Gateway',
                  payment['payment_gateway'] ??
                      booking['payment_gateway'] ??
                      '-',
                ),
                row(
                  'Transaction ID',
                  payment['transaction_id'] ??
                      booking['transaction_id'] ??
                      '-',
                ),
                row(
                  'Biaya layanan',
                  rupiah(payment['payment_fee'] ?? booking['payment_fee']),
                ),
                const Divider(height: 28),
                row(
                  'Total Pembayaran',
                  rupiah(payment['payment_total'] ?? booking['payment_total']),
                  isTotal: true,
                ),
              ],
            ),
          ),

          if (!isPaid && hasQrString) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan QRIS untuk Membayar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: QrImageView(
                      data: qrString.toString(),
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Buka aplikasi e-wallet atau mobile banking, lalu scan QRIS ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          if (!isPaid && hasPaymentUrl && !hasQrString)
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: openPaymentUrl,
                icon: const Icon(Icons.payment),
                label: const Text(
                  'Bayar Sekarang',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          if (!isPaid && hasQrString)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Untuk metode QRIS, silakan scan QR Code di atas untuk melakukan pembayaran.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),

          if (!isPaid && !hasPaymentUrl && !hasQrString)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Data pembayaran belum tersedia. Coba pilih metode pembayaran ulang atau hubungi admin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),

          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: checking ? null : checkStatus,
              icon: checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text(
                'Cek Status Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget row(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isTotal
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF0F172A),
                fontSize: isTotal ? 18 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}