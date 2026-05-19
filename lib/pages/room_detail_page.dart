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

  // Fungsi untuk menggabungkan gambar utama dan galeri seperti di web (PHP)
  List<String> _getGalleryImages() {
    List<String> gallery = [];

    if (room['images'] is List) {
      gallery.addAll((room['images'] as List).map((e) => e.toString()));
    }

    String mainImage = room['image']?.toString() ?? '';

    if (mainImage.isNotEmpty && !gallery.contains(mainImage)) {
      gallery.insert(0, mainImage);
    }

    return gallery;
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _getGalleryImages();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          room['nama'] ?? 'Detail Kamar',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 1. GALLERY PAGER + ZOOM ---
          _buildGallery(galleryImages),

          const SizedBox(height: 20),

          // --- 2. HEADER KAMAR ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['nama'] ?? 'Kamar',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room['address'] ?? 'Rafa Kost / Purwokerto',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Harga
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga Sewa',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            rupiah(room['harga_1_orang'] ?? room['harga']),
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 3, left: 4),
                            child: Text(
                              '/ bulan (1 Orang)',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Untuk 2 orang: ${rupiah(room['harga_2_orang'] ?? room['harga'])} / bulan',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Specs Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildSpecChip(
                        Icons.bed_outlined,
                        'KASUR',
                        room['bed_type'] ?? 'Single Bed',
                      ),
                      const SizedBox(width: 10),
                      _buildSpecChip(
                        Icons.bathroom_outlined,
                        'KAMAR MANDI',
                        (room['bathroom_type'] ?? 'Luar')
                            .toString()
                            .toUpperCase(),
                      ),
                      const SizedBox(width: 10),
                      _buildSpecChip(
                        Icons.inventory_2_outlined,
                        'PENYIMPANAN',
                        room['size'] ?? 'Lemari',
                      ),
                      const SizedBox(width: 10),
                      _buildSpecChip(
                        Icons.electrical_services_outlined,
                        'LISTRIK',
                        room['electricity'] ?? 'Bebas(Normal)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- 3. DESKRIPSI ---
          _buildSectionCard(
            title: 'Deskripsi',
            child: Text(
              room['description'] ??
                  'Kamar ini cocok untuk kamu yang membutuhkan tempat tinggal yang nyaman dan praktis. Kondisi kamar bersih dan cukup untuk aktivitas sehari-hari, dilengkapi dengan fasilitas yang memadai.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- 4. FASILITAS UMUM ---
          _buildSectionCard(
            title: 'Fasilitas Umum',
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _buildFacilities(room['facilities']),
            ),
          ),

          // --- 5. PERATURAN KOST ---
          if (room['rules'] != null &&
              room['rules'] is List &&
              (room['rules'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Peraturan Kost',
              child: Column(
                children: (room['rules'] as List).map((rule) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            rule.toString(),
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // --- 6. TOMBOL BOOKING ---
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(room: room),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text(
                'Sewa Sekarang',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
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

  // WIDGET GALERI PAGER + PINCH TO ZOOM
  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 50,
            color: Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: PageView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                ApiConfig.imageUrl(images[index]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,

                // Loading image
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return Container(
                    color: const Color(0xFFE5E7EB),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },

                // Jika gambar gagal dimuat
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE5E7EB),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // WIDGET KOTAK SPESIFIKASI KECIL
  Widget _buildSpecChip(IconData icon, String label, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4B5563),
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET CARD UNTUK DESKRIPSI & FASILITAS
  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // DAFTAR FASILITAS FALLBACK
  List<Widget> _buildFacilities(dynamic rawFacilities) {
    final List<String> fasilitasList = [];

    if (rawFacilities is List && rawFacilities.isNotEmpty) {
      fasilitasList.addAll(rawFacilities.map((e) => e.toString()));
    } else {
      fasilitasList.addAll([
        'Wifi Gratis',
        'Air Bersih',
        'Listrik',
        'Dapur Bersama',
        'Parkir',
        'Kulkas Bersama',
      ]);
    }

    return fasilitasList.map((fasilitas) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Text(
          fasilitas,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }).toList();
  }
}