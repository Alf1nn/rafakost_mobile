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
      showMessage('Tidak bisa terhubung ke server.');
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
    final lateDays = isLate ? daysLeft.abs() : 0;
    final estimatedFine = lateDays * 10000;

    final roomName = safe(kamar?['nama'] ?? 'Kamar');
    final lantai = safe(kamar?['lantai']);
    final kamarMandi = safe(kamar?['kamar_mandi']);

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
          'Perpanjang Sewa',
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
          children: [
            rentalHeaderCard(
              roomName: roomName,
              lantai: lantai,
              kamarMandi: kamarMandi,
              status: status,
              daysLeft: daysLeft,
            ),

            const SizedBox(height: 24),

            sectionTitle(
              icon: Icons.receipt_long_outlined,
              title: 'Data Sewa Lama',
            ),

            const SizedBox(height: 14),

            oldRentalCard(),

            if (isLate) ...[
              const SizedBox(height: 18),
              lateWarningCard(
                lateDays: lateDays,
                estimatedFine: estimatedFine,
              ),
            ],

            const SizedBox(height: 24),

            sectionTitle(
              icon: Icons.refresh_rounded,
              title: 'Perpanjangan Sewa',
            ),

            const SizedBox(height: 16),

            formLabel('DURASI SEWA'),
            selectBox(
              value: durasi,
              items: List.generate(12, (index) => index + 1),
              textBuilder: (value) => '$value Bulan',
              onChanged: (value) {
                setState(() {
                  durasi = value;
                });
              },
            ),

            const SizedBox(height: 16),

            formLabel('JUMLAH ORANG'),
            selectBox(
              value: orang,
              items: const [1, 2],
              textBuilder: (value) => '$value Orang',
              onChanged: (value) {
                setState(() {
                  orang = value;
                });
              },
            ),

            const SizedBox(height: 18),

            noticeCard(),
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
              onPressed: loading ? null : submitRenew,
              icon: loading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                    ),
              label: Text(
                loading ? 'Membuat Invoice...' : 'Buat Invoice Perpanjangan',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
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

  Widget rentalHeaderCard({
    required String roomName,
    required String lantai,
    required String kamarMandi,
    required dynamic status,
    required dynamic daysLeft,
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
                Text(
                  roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$lantai - Kamar mandi $kamarMandi',
                  maxLines: 2,
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

          statusBadge(status, daysLeft),
        ],
      ),
    );
  }

  Widget statusBadge(dynamic status, dynamic daysLeft) {
    final text = statusText(status, daysLeft);
    final isExpired = status == 'expired';
    final isEnding = status == 'ends_today' || status == 'ending_soon';

    Color bgColor;
    Color textColor;
    IconData icon;

    if (isExpired) {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      icon = Icons.warning_amber_rounded;
    } else if (isEnding) {
      bgColor = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFEA580C);
      icon = Icons.schedule_rounded;
    } else {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
            text,
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

  Widget oldRentalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: cardDecoration(),
      child: Column(
        children: [
          infoRow('Invoice Lama', safe(widget.rental['invoice'])),
          infoRow('Tanggal Masuk', safe(widget.rental['tanggal_masuk'])),
          infoRow('Tanggal Habis', safe(widget.rental['tanggal_habis'])),
          infoRow(
            'Status',
            statusText(
              widget.rental['status_masa_sewa'],
              widget.rental['days_left'],
            ),
          ),
        ],
      ),
    );
  }

  Widget lateWarningCard({
    required int lateDays,
    required int estimatedFine,
  }) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFF92400E),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Masa sewa sudah telat $lateDays hari. Estimasi denda: ${rupiah(estimatedFine)}. Denda final akan dihitung server saat invoice dibuat.',
              style: const TextStyle(
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

  Widget noticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFBAE6FD),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF0284C7),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Invoice perpanjangan akan dibuat sesuai durasi dan jumlah orang yang dipilih.',
              style: TextStyle(
                color: Color(0xFF0284C7),
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

  Widget formLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFB6B6B6),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget selectBox({
    required int value,
    required List<int> items,
    required String Function(int) textBuilder,
    required void Function(int) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFFB6B6B6),
      ),
      decoration: fieldDecoration(),
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: item,
              child: Text(textBuilder(item)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  InputDecoration fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: Color(0xFFDADDE1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: Color(0xFF0EA5E9),
          width: 1.3,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: Color(0xFFDADDE1),
        ),
      ),
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

  String statusText(dynamic status, dynamic daysLeft) {
    if (status == 'expired') {
      final late = daysLeft == null ? 0 : daysLeft.abs();
      return 'Telat $late hari';
    }

    if (status == 'ends_today') {
      return 'Hari ini';
    }

    if (status == 'ending_soon') {
      return '$daysLeft hari lagi';
    }

    if (status == 'active') {
      return 'Aktif';
    }

    return '-';
  }
}