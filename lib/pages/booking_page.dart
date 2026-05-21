import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'invoice_page.dart';

import '../config/api_config.dart';

class BookingPage extends StatefulWidget {
  final Map room;

  const BookingPage({
    super.key,
    required this.room,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int durasi = 1;
  int orang = 1;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final noteController = TextEditingController();

  DateTime tanggalMasuk = DateTime.now();

  int get hargaPerBulan {
    final harga1 = int.tryParse(widget.room['harga_1_orang'].toString()) ?? 0;
    final harga2 =
        int.tryParse(widget.room['harga_2_orang'].toString()) ?? harga1;

    return orang >= 2 ? harga2 : harga1;
  }

  int get totalHarga {
    return hargaPerBulan * durasi;
  }

  String rupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String apiDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$year-$month-$day';
  }

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: tanggalMasuk,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result != null) {
      setState(() {
        tanggalMasuk = result;
      });
    }
  }

  Future<void> submitBooking() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final note = noteController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan nomor WhatsApp wajib diisi.'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token login tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/bookings'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'kamar_id': widget.room['id'],
          'tanggal_masuk': apiDate(tanggalMasuk),
          'durasi': durasi,
          'orang': orang,
          'customer_name': name,
          'customer_phone': phone,
          'customer_email': email,
          'customer_address': address,
          'customer_note': note,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 403) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Akun belum terverifikasi.'),
          ),
        );

        return;
      }

      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('api_token');
        await prefs.remove('user_name');
        await prefs.remove('user_email');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login habis. Silakan login ulang.'),
          ),
        );

        return;
      }

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice berhasil dibuat: ${data['invoice']}'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InvoicePage(
              booking: data['booking'],
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal membuat invoice.'),
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
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomName = widget.room['nama'] ?? 'Kamar';
    final lantai = widget.room['lantai'] ?? '-';
    final kamarMandi = widget.room['kamar_mandi'] ?? '-';
    final status = widget.room['status'] ?? 'tersedia';

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
          'Booking Kamar',
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
            roomHeaderCard(
              roomName: roomName.toString(),
              lantai: lantai.toString(),
              kamarMandi: kamarMandi.toString(),
              status: status.toString(),
            ),

            const SizedBox(height: 24),

            sectionTitle(
              icon: Icons.calendar_month_outlined,
              title: 'Detail Booking',
            ),

            const SizedBox(height: 16),

            formLabel('TANGGAL MASUK'),
            dateField(),

            const SizedBox(height: 16),

            formLabel('DURASI SEWA'),
            selectBox(
              value: durasi,
              items: const [1, 2, 3, 6, 12],
              textBuilder: (value) => '$value Bulan',
              onChanged: (value) {
                setState(() {
                  durasi = value;
                });
              },
            ),

            const SizedBox(height: 16),

            formLabel('Orang'),
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

            const SizedBox(height: 26),

            sectionTitle(
              icon: Icons.person_outline_rounded,
              title: 'Data Penyewa',
            ),

            const SizedBox(height: 16),

            formLabel('NAMA LENGKAP'),
            inputField(
              controller: nameController,
              hint: 'Masukkan nama lengkap',
              keyboardType: TextInputType.name,
            ),

            const SizedBox(height: 16),

            formLabel('NO WHATSAPP'),
            inputField(
              controller: phoneController,
              hint: 'Contoh: 081234567890',
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            formLabel('EMAIL'),
            inputField(
              controller: emailController,
              hint: 'nama@email.com',
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            formLabel('ALAMAT'),
            inputField(
              controller: addressController,
              hint: 'Masukkan alamat lengkap',
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            formLabel('CATATAN'),
            inputField(
              controller: noteController,
              hint: 'Opsional',
              maxLines: 2,
            ),

            const SizedBox(height: 26),

            sectionTitle(
              icon: Icons.receipt_long_outlined,
              title: 'Ringkasan Pembayaran',
            ),

            const SizedBox(height: 14),

            summaryCard(),
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
              onPressed: submitBooking,
              icon: const Icon(
                Icons.receipt_long_rounded,
                size: 18,
              ),
              label: const Text(
                'Buat Invoice Booking',
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

  Widget roomHeaderCard({
    required String roomName,
    required String lantai,
    required String kamarMandi,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 24, 16, 24),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$lantai - Kamar mandi $kamarMandi',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          statusBadge(status),
        ],
      ),
    );
  }

  Widget statusBadge(String status) {
    final isAvailable = status.toLowerCase() == 'tersedia';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF7DD3FC)
            : const Color(0xFFFCA5A5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.bed_rounded : Icons.close_rounded,
            size: 14,
            color: Colors.black87,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Tersedia' : 'Terisi',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w800,
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

  Widget dateField() {
    return InkWell(
      onTap: pickDate,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(
            color: const Color(0xFFDADDE1),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatDate(tanggalMasuk),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.black87,
            ),
          ],
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

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: fieldDecoration(hint: hint),
    );
  }

  InputDecoration fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB6B6B6),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
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
    );
  }

  Widget summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          summaryRow('Harga per bulan', rupiah(hargaPerBulan)),
          summaryRow('Durasi', '$durasi Bulan'),
          summaryRow('Jumlah orang', '$orang Orang'),
          const Divider(height: 24),
          summaryRow(
            'Total',
            rupiah(totalHarga),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? Colors.black : const Color(0xFF64748B),
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                fontSize: isTotal ? 15 : 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF0EA5E9) : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: isTotal ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}