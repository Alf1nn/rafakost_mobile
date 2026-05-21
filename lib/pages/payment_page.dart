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

  bool get isQris {
    final methodName =
        payment['payment_method_name'] ?? booking['payment_method_name'] ?? '';
    final methodCode =
        payment['payment_method_code'] ?? booking['payment_method_code'] ?? '';

    final text = '$methodName $methodCode'.toLowerCase();

    return text.contains('qris') || text.contains('qr');
  }

  @override
  Widget build(BuildContext context) {
    final status =
        booking['payment_status'] ?? payment['payment_status'] ?? 'pending';
    final isPaid = status == 'paid';

    final invoice = safe(booking['invoice'] ?? payment['invoice']);
    final paymentUrl = payment['payment_url'] ?? booking['payment_url'];
    final qrString = payment['qr_string'] ?? booking['qr_string'];

    final hasPaymentUrl =
        paymentUrl != null && paymentUrl.toString().trim().isNotEmpty;
    final hasQrString =
        qrString != null && qrString.toString().trim().isNotEmpty;

    final showPayButton = !isPaid && hasPaymentUrl && !hasQrString;

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
          'Pembayaran',
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            paymentHeaderCard(
              invoice: invoice,
              status: status.toString(),
              isPaid: isPaid,
            ),

            const SizedBox(height: 24),

            sectionTitle(
              icon: Icons.payment_rounded,
              title: 'Detail Pembayaran',
            ),

            const SizedBox(height: 14),

            detailPaymentCard(),

            if (!isPaid && hasQrString) ...[
              const SizedBox(height: 24),
              sectionTitle(
                icon: Icons.qr_code_2_rounded,
                title: 'QRIS Pembayaran',
              ),
              const SizedBox(height: 14),
              qrisCard(qrString.toString()),
            ],

            const SizedBox(height: 18),

            noticeCard(
              isPaid: isPaid,
              hasPaymentUrl: hasPaymentUrl,
              hasQrString: hasQrString,
            ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPayButton) ...[
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: openPaymentUrl,
                    icon: const Icon(
                      Icons.payment_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Bayar Sekarang',
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
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 46,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: checking ? null : checkStatus,
                  icon: checking
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0EA5E9),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                        ),
                  label: const Text(
                    'Cek Status Pembayaran',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    side: const BorderSide(
                      color: Color(0xFF0EA5E9),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainNavigationPage(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paymentHeaderCard({
    required String invoice,
    required String status,
    required bool isPaid,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      decoration: cardDecoration(
        shadowOpacity: 0.12,
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
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.home_work_rounded,
                  color: Color(0xFF0EA5E9),
                );
              },
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

          statusBadge(status, isPaid),
        ],
      ),
    );
  }

  Widget statusBadge(String status, bool isPaid) {
    final lower = status.toLowerCase();

    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (isPaid || lower == 'paid') {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      label = 'Lunas';
      icon = Icons.check_circle_rounded;
    } else {
      bgColor = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFEA580C);
      label = 'Pending';
      icon = Icons.schedule_rounded;
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

  Widget detailPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: cardDecoration(),
      child: Column(
        children: [
          infoRow(
            'Metode',
            safe(
              payment['payment_method_name'] ??
                  booking['payment_method_name'],
            ),
          ),
          infoRow(
            'Gateway',
            safe(
              payment['payment_gateway'] ??
                  booking['payment_gateway'],
            ),
          ),
          infoRow(
            'Transaction ID',
            safe(
              payment['transaction_id'] ??
                  booking['transaction_id'],
            ),
          ),
          infoRow(
            'Biaya Layanan',
            rupiah(payment['payment_fee'] ?? booking['payment_fee']),
          ),
          const Divider(
            height: 22,
            color: Color(0xFFE5E7EB),
          ),
          infoRow(
            'Total Pembayaran',
            rupiah(payment['payment_total'] ?? booking['payment_total']),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget qrisCard(String qrString) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: cardDecoration(),
      child: Column(
        children: [
          const Text(
            'Scan QRIS untuk Membayar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: QrImageView(
              data: qrString,
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
              color: Color(0xFF8E8E8E),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget noticeCard({
    required bool isPaid,
    required bool hasPaymentUrl,
    required bool hasQrString,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String text;

    if (isPaid) {
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF15803D);
      icon = Icons.check_circle_outline_rounded;
      text = 'Pembayaran sudah berhasil dikonfirmasi.';
    } else if (hasQrString) {
      bgColor = const Color(0xFFE0F2FE);
      borderColor = const Color(0xFFBAE6FD);
      textColor = const Color(0xFF0284C7);
      icon = Icons.qr_code_2_rounded;
      text =
          'Untuk metode QRIS, silakan scan QR Code di atas untuk melakukan pembayaran.';
    } else if (hasPaymentUrl) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFF92400E);
      icon = Icons.info_outline_rounded;
      text =
          'Klik Bayar Sekarang untuk membuka halaman pembayaran atau aplikasi pembayaran.';
    } else {
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFF991B1B);
      icon = Icons.error_outline_rounded;
      text =
          'Data pembayaran belum tersedia. Coba pilih metode pembayaran ulang atau hubungi admin.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
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

  BoxDecoration cardDecoration({
    double shadowOpacity = 0.06,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(shadowOpacity),
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
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}