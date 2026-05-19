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
    final harga2 = int.tryParse(widget.room['harga_2_orang'].toString()) ?? harga1;

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
            content: Text(
              data['message'] ?? 'Akun belum terverifikasi.',
            ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Booking Kamar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                Text(
                  roomName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.room['lantai'] ?? '-'} • Kamar mandi ${widget.room['kamar_mandi'] ?? '-'}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          section(
            title: 'Detail Booking',
            child: Column(
              children: [
                dateButton(),
                const SizedBox(height: 12),
                selectBox(
                  label: 'Durasi',
                  value: durasi,
                  items: const [1, 2, 3, 6, 12],
                  textBuilder: (value) => '$value Bulan',
                  onChanged: (value) {
                    setState(() {
                      durasi = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                selectBox(
                  label: 'Jumlah Orang',
                  value: orang,
                  items: const [1, 2],
                  textBuilder: (value) => '$value Orang',
                  onChanged: (value) {
                    setState(() {
                      orang = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          section(
            title: 'Data Penyewa',
            child: Column(
              children: [
                inputField(
                  label: 'Nama Lengkap',
                  controller: nameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                inputField(
                  label: 'No WhatsApp',
                  controller: phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                inputField(
                  label: 'Email',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                inputField(
                  label: 'Alamat',
                  controller: addressController,
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                inputField(
                  label: 'Catatan',
                  controller: noteController,
                  icon: Icons.notes_outlined,
                  maxLines: 2,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          section(
            title: 'Ringkasan Pembayaran',
            child: Column(
              children: [
                summaryRow('Harga per bulan', rupiah(hargaPerBulan)),
                summaryRow('Durasi', '$durasi Bulan'),
                summaryRow('Jumlah orang', '$orang Orang'),
                const Divider(height: 28),
                summaryRow(
                  'Total',
                  rupiah(totalHarga),
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: submitBooking,
              icon: const Icon(Icons.receipt_long),
              label: const Text(
                'Buat Invoice Booking',
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget section({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget dateButton() {
    return InkWell(
      onTap: pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tanggal Masuk: ${formatDate(tanggalMasuk)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget selectBox({
    required String label,
    required int value,
    required List<int> items,
    required String Function(int) textBuilder,
    required void Function(int) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: inputDecoration(label, Icons.arrow_drop_down_circle_outlined),
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
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: inputDecoration(label, icon),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  Widget summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}