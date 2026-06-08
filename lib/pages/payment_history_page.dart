import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'payment_methods_page.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  bool loading = true;
  List invoices = [];

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  String rupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;

    return 'Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'canceled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String statusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Lunas';
      case 'pending':
        return 'Pending';
      case 'canceled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  Future<void> fetchInvoices() async {
    setState(() {
      loading = true;
    });

    final token = await getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token login tidak ditemukan. Silakan login ulang.'),
        ),
      );

      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment-history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          invoices = data['data'] ?? [];
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal memuat riwayat invoice.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa terhubung ke server.'),
        ),
      );
    }
  }

  Future<void> cancelInvoice(Map invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Batalkan Invoice',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Yakin ingin membatalkan invoice ${invoice['invoice']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final token = await getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token login tidak ditemukan. Silakan login ulang.'),
        ),
      );

      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/payment-history/${invoice['id']}/cancel',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Invoice diproses.'),
        ),
      );

      if (response.statusCode == 200 && data['success'] == true) {
        fetchInvoices();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa terhubung ke server.'),
        ),
      );
    }
  }

void continuePayment(Map invoice) {
  final status = (invoice['payment_status'] ?? '').toString().toLowerCase();
  final identityStatus =
      (invoice['identity_status'] ?? '').toString().toLowerCase();

  if (identityStatus != 'approved') {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          invoice['pay_blocked_message']?.toString() ??
              'Akun kamu belum terverifikasi. Silakan verifikasi dokumen terlebih dahulu sebelum melakukan pembayaran.',
        ),
      ),
    );
    return;
  }

  if (status != 'pending') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice ini tidak bisa dilanjutkan pembayaran.'),
      ),
    );
    return;
  }

  if (invoice['can_pay'] != true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          invoice['pay_blocked_message']?.toString() ??
              'Invoice ini tidak bisa dilanjutkan pembayaran.',
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentMethodsPage(
        invoice: invoice['invoice'].toString(),
      ),
    ),
  ).then((_) => fetchInvoices());
}

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchInvoices,
      child: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : invoices.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 160),
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 54,
                      color: Color(0xFFCBD5E1),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada invoice',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Invoice booking dan perpanjangan akan tampil di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final invoice = Map<String, dynamic>.from(invoices[index]);
                    final kamar = invoice['kamar'] is Map
                        ? Map<String, dynamic>.from(invoice['kamar'])
                        : null;

                    final status =
                        (invoice['payment_status'] ?? '').toString();

                    return invoiceCard(
                      invoice: invoice,
                      kamar: kamar,
                      status: status,
                    );
                  },
                ),
    );
  }

  Widget invoiceCard({
    required Map<String, dynamic> invoice,
    required Map<String, dynamic>? kamar,
    required String status,
  }) {
    final invoiceNumber = invoice['invoice']?.toString() ?? '-';

    final kamarName = kamar != null
        ? kamar['nama']?.toString() ?? 'Kamar'
        : 'Kamar';

    final durasi = invoice['durasi']?.toString() ?? '-';
    final orang = invoice['orang']?.toString() ?? '-';
    final method = invoice['payment_method_name']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF0EA5E9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  invoiceNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText(status),
                  style: TextStyle(
                    color: statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            kamarName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$durasi bulan • $orang orang',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          if (method != null && method.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Metode: $method',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Bayar',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                rupiah(invoice['payment_total']),
                style: const TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cancelInvoice(invoice),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(
                        color: Color(0xFFDC2626),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batalkan',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => continuePayment(invoice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Lanjut Bayar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}