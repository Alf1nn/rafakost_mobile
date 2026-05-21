import 'package:flutter/material.dart';
import 'booking_page.dart';
import '../config/api_config.dart';

class RoomDetailPage extends StatelessWidget {
  final Map room;

  const RoomDetailPage({
    super.key,
    required this.room,
  });

  String rupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;
    return 'Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  List<String> _getGalleryImages() {
    final List<String> gallery = [];

    if (room['images'] is List) {
      gallery.addAll((room['images'] as List).map((e) => e.toString()));
    }

    final mainImage = room['image']?.toString() ?? '';

    if (mainImage.isNotEmpty && !gallery.contains(mainImage)) {
      gallery.insert(0, mainImage);
    }

    return gallery;
  }

  String get _description {
    final desc = room['description']?.toString().trim();

    if (desc != null && desc.isNotEmpty && desc != 'null') {
      return desc;
    }

    return 'Kamar A1 cocok untuk kamu yang membutuhkan tempat tinggal yang nyaman dan praktis. Kondisi kamar bersih dan cukup untuk aktivitas sehari-hari, dilengkapi dengan kasur ukuran single bed, meja, dan kursi. Penghuni juga mendapatkan akses ke kamar mandi luar digunakan bersama. Lingkungan kost yang tenang dan aman membuat kamar ini cocok untuk mahasiswa atau pekerja yang mencari hunian sederhana namun tetap nyaman.';
  }

  String get _bathroomType {
    final value = room['kamar_mandi'] ??
        room['bathroom_type'] ??
        room['kamarMandi'] ??
        'luar';

    return value.toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _getGalleryImages();
    final harga1 = room['harga_1_orang'] ?? room['harga'];
    final harga2 = room['harga_2_orang'] ?? room['harga'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHero(context, galleryImages),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    _buildTitleCard(),
                    const SizedBox(height: 14),
                    _buildPriceCard(harga1, harga2),
                    const SizedBox(height: 14),
                    _buildSpecGrid(),
                    const SizedBox(height: 14),
                    _buildDescriptionCard(),
                    const SizedBox(height: 14),
                    _buildFacilitiesCard(),
                    const SizedBox(height: 20),
                    _buildBookingButton(context),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, List<String> images) {
    return Stack(
      children: [
        SizedBox(
          height: 230,
          width: double.infinity,
          child: images.isEmpty
              ? Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 46,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
              : PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      ApiConfig.imageUrl(images[index]),
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 46,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),

        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.25),
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 12,
          left: 12,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              room['nama']?.toString() ?? 'Kamar',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              room['status']?.toString() ?? 'tersedia',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(dynamic harga1, dynamic harga2) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Harga Sewa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      rupiah(harga1),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      '/bulan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 8),
                Text(
                  '${rupiah(harga2)}/bulan (Untuk 2 orang)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildSpecBox(
            icon: Icons.bathroom_outlined,
            label: 'KAMAR MANDI',
            value: _bathroomType,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSpecBox(
            icon: Icons.inventory_2_outlined,
            label: 'PENYIMPANAN',
            value: room['size']?.toString() ?? 'LEMARI',
          ),
        ),
      ],
    );
  }

  Widget _buildSpecBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: Colors.black,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF334155),
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fasilitas Umum',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildFacilities(room['facilities']),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingPage(room: room),
            ),
          );
        },
        icon: const Icon(Icons.payment_rounded, size: 18),
        label: const Text(
          'Lanjutkan Pembayaran',
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
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  List<Widget> _buildFacilities(dynamic rawFacilities) {
    final List<String> list = [];

    if (rawFacilities is List && rawFacilities.isNotEmpty) {
      list.addAll(rawFacilities.map((e) => e.toString()));
    } else if (rawFacilities is String && rawFacilities.trim().isNotEmpty) {
      list.addAll(
        rawFacilities
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    } else {
      list.addAll([
        'Wifi Gratis',
        'Listrik',
        'Dapur Bersama',
        'Dapur Bersama',
        'Kulkas Bersama',
      ]);
    }

    return list.map((item) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_box_outline_blank_rounded,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              item,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}