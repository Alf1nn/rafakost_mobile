import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'payment_methods_page.dart';

class InvoicePage extends StatefulWidget {
  final Map booking;

  const InvoicePage({
    super.key,
    required this.booking,
  });

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool checkingPayment = false;

  Map get booking => widget.booking;

  String rupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;

    return 'Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  String safe(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.isEmpty || text == 'null') {
      return '-';
    }

    return text;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  Future<void> continuePayment(BuildContext context) async {
    if (checkingPayment) return;

    final invoice = safe(booking['invoice']);
    final paymentStatus = safe(booking['payment_status']).toLowerCase();

    if (invoice == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice tidak valid.'),
        ),
      );
      return;
    }

    if (paymentStatus != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice ini tidak bisa dilanjutkan pembayaran.'),
        ),
      );
      return;
    }

    final identityStatus = safe(booking['identity_status']).toLowerCase();

    if (identityStatus != '-' && identityStatus != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            booking['pay_blocked_message']?.toString() ??
                'Akun kamu belum terverifikasi. Silakan verifikasi dokumen terlebih dahulu sebelum melakukan pembayaran.',
          ),
        ),
      );
      return;
    }

    if (booking.containsKey('can_pay') && booking['can_pay'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            booking['pay_blocked_message']?.toString() ??
                'Invoice ini tidak bisa dilanjutkan pembayaran.',
          ),
        ),
      );
      return;
    }

    setState(() {
      checkingPayment = true;
    });

    final token = await getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        checkingPayment = false;
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
        Uri.parse('${ApiConfig.baseUrl}/invoices/$invoice'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 403) {
        setState(() {
          checkingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Akun kamu belum terverifikasi. Silakan verifikasi dokumen terlebih dahulu sebelum melakukan pembayaran.',
            ),
          ),
        );

        return;
      }

      if (response.statusCode != 200 || data['success'] != true) {
        setState(() {
          checkingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Invoice tidak bisa diproses.'),
          ),
        );

        return;
      }

      setState(() {
        checkingPayment = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentMethodsPage(
            invoice: invoice,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        checkingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa terhubung ke server.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = safe(booking['invoice']);
    final paymentStatus = safe(booking['payment_status']).toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Invoice Booking',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            invoiceHeaderCard(
              invoice: invoice,
              status: paymentStatus,
            ),

            const SizedBox(height: 24),

            sectionTitle(
              icon: Icons.receipt_long_outlined,
              title: 'Detail Invoice',
            ),

            const SizedBox(height: 14),

            detailCard(),

            const SizedBox(height: 24),

            sectionTitle(
              icon: Icons.payments_outlined,
              title: 'Ringkasan Pembayaran',
            ),

            const SizedBox(height: 14),

            paymentSummaryCard(),

            const SizedBox(height: 18),

            infoBox(),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => continuePayment(context),
              icon: const Icon(
                Icons.payment_rounded,
                size: 18,
              ),
              label: const Text(
                'Lanjut Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget invoiceHeaderCard({
    required String invoice,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Image.asset(
              'assets/images/logo1.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rafa Kost',
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'INV: $invoice',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          statusBadge(status),
        ],
      ),
    );
  }

  Widget statusBadge(String status) {
    final paid = status == 'paid';
    final pending = status == 'pending';

    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (paid) {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      label = 'Lunas';
      icon = Icons.check_circle_rounded;
    } else if (pending) {
      bgColor = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFEA580C);
      label = 'Pending';
      icon = Icons.schedule_rounded;
    } else {
      bgColor = const Color(0xFFE5E7EB);
      textColor = const Color(0xFF64748B);
      label = status.isEmpty || status == '-' ? '-' : status;
      icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.black,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget detailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: cardDecoration(),
      child: Column(
        children: [
          infoRow('Tanggal Masuk', safe(booking['tanggal_masuk'])),
          infoRow('Durasi Sewa', '${safe(booking['durasi'])} Bulan'),
          infoRow('Jumlah Orang', '${safe(booking['orang'])} Orang'),
          infoRow('Status Pembayaran', safe(booking['payment_status'])),
        ],
      ),
    );
  }

  Widget paymentSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: cardDecoration(),
      child: Column(
        children: [
          infoRow(
            'Total Harga',
            rupiah(booking['total_harga'] ?? booking['payment_total']),
          ),
          infoRow(
            'Biaya Admin',
            rupiah(booking['payment_fee'] ?? 0),
          ),
          const Divider(
            height: 22,
            color: Color(0xFFE5E7EB),
          ),
          infoRow(
            'Total Pembayaran',
            rupiah(booking['payment_total']),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF92400E),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Invoice berhasil dibuat. Silakan lanjutkan pembayaran melalui metode pembayaran yang tersedia.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w700,
                height: 1.45,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget infoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? Colors.black : const Color(0xFF8E8E8E),
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isTotal
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF8E8E8E),
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}