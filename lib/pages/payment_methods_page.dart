import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'payment_page.dart';

class PaymentMethodsPage extends StatefulWidget {
  final String invoice;

  const PaymentMethodsPage({
    super.key,
    required this.invoice,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  bool loading = true;
  bool submitting = false;
  List methods = [];
  Map? booking;

  @override
  void initState() {
    super.initState();
    fetchMethods();
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

  Future<void> fetchMethods() async {
    final token = await getToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/invoices/${widget.invoice}/methods'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        methods = data['data'] ?? [];
        booking = data['booking'];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa mengambil metode pembayaran.'),
        ),
      );
    }
  }

  Future<void> chooseMethod(dynamic method) async {
    if (submitting) return;

    setState(() {
      submitting = true;
    });

    final token = await getToken();

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/invoices/${widget.invoice}/choose-method',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payment_method_id': method['id'],
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              payment: data['payment'],
              booking: data['booking'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Gagal memilih metode pembayaran.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa terhubung ke server.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = safe(booking?['invoice'] ?? widget.invoice);
    final total = booking?['payment_total'] ?? booking?['total_harga'] ?? 0;

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
          'Pilih Pembayaran',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0EA5E9),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchMethods,
              color: const Color(0xFF0EA5E9),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  invoiceHeaderCard(
                    invoice: invoice,
                    total: total,
                  ),

                  const SizedBox(height: 24),

                  sectionTitle(
                    icon: Icons.payment_rounded,
                    title: 'Metode Pembayaran',
                  ),

                  const SizedBox(height: 14),

                  if (methods.isEmpty)
                    emptyPaymentCard()
                  else
                    ...methods.map((method) {
                      return paymentMethodCard(method);
                    }),
                ],
              ),
            ),
    );
  }

  Widget invoiceHeaderCard({
    required String invoice,
    required dynamic total,
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

                const SizedBox(height: 8),

                Text(
                  'Tagihan awal: ${rupiah(total)}',
                  style: const TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: Color(0xFFEA580C),
                ),
                SizedBox(width: 4),
                Text(
                  'Pending',
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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

  Widget emptyPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum ada metode pembayaran aktif.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentMethodCard(dynamic method) {
    final name = safe(method['name']);
    final code = safe(method['code'] ?? method['method_code']);
    final fee = method['fee'] ?? 0;
    final total = method['payment_total'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: InkWell(
        onTap: submitting ? null : () => chooseMethod(method),
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          child: Row(
            children: [
              paymentIcon(name),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      code == '-' ? 'Metode pembayaran' : code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        smallInfoChip('Fee ${rupiah(fee)}'),
                        const SizedBox(width: 6),
                        Expanded(
                          child: smallInfoChip(
                            'Total ${rupiah(total)}',
                            blue: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0EA5E9),
                      ),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 26,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paymentIcon(String name) {
    final lower = name.toLowerCase();

    IconData icon = Icons.payment_rounded;

    if (lower.contains('qris')) {
      icon = Icons.qr_code_2_rounded;
    } else if (lower.contains('ovo') ||
        lower.contains('dana') ||
        lower.contains('gopay') ||
        lower.contains('shopee')) {
      icon = Icons.account_balance_wallet_rounded;
    } else if (lower.contains('bank') ||
        lower.contains('va') ||
        lower.contains('virtual')) {
      icon = Icons.account_balance_rounded;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBAE6FD),
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF0284C7),
        size: 25,
      ),
    );
  }

  Widget smallInfoChip(String text, {bool blue = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: blue ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: blue ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: blue ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
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
}