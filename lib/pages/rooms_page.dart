import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'room_detail_page.dart';

class RoomsPage extends StatefulWidget {
  final String initialSearch;

  const RoomsPage({
    super.key,
    this.initialSearch = '',
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  bool loading = true;
  bool hasError = false;

  List rooms = [];

  final TextEditingController searchController = TextEditingController();

  static const blue = Color(0xFF0798E8);
  static const darkText = Color(0xFF111111);
  static const greyText = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();

    searchController.text = widget.initialSearch;
    searchController.addListener(() {
      setState(() {});
    });

    fetchRooms();
  }

  @override
  void didUpdateWidget(covariant RoomsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSearch != widget.initialSearch) {
      searchController.text = widget.initialSearch;
      setState(() {});
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchRooms() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/kamars'),
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          rooms = data['data'] ?? [];
          loading = false;
          hasError = false;
        });
      } else {
        setState(() {
          rooms = [];
          loading = false;
          hasError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        rooms = [];
        loading = false;
        hasError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak bisa mengambil data kamar: $e'),
        ),
      );
    }
  }

  List get filteredRooms {
    final keyword = searchController.text.toLowerCase().trim();

    if (keyword.isEmpty) {
      return rooms;
    }

    return rooms.where((room) {
      final nama = (room['nama'] ?? '').toString().toLowerCase();
      final lantai = (room['lantai'] ?? '').toString().toLowerCase();
      final kamarMandi = (room['kamar_mandi'] ?? '').toString().toLowerCase();
      final status = (room['status'] ?? '').toString().toLowerCase();
      final harga = (room['harga'] ?? '').toString().toLowerCase();
      final harga1 = (room['harga_1_orang'] ?? '').toString().toLowerCase();
      final harga2 = (room['harga_2_orang'] ?? '').toString().toLowerCase();

      return nama.contains(keyword) ||
          lantai.contains(keyword) ||
          kamarMandi.contains(keyword) ||
          status.contains(keyword) ||
          harga.contains(keyword) ||
          harga1.contains(keyword) ||
          harga2.contains(keyword);
    }).toList();
  }

  int get totalKamar {
    return rooms.length;
  }

  int get totalKamarMandiDalam {
    return rooms.where((room) {
      final value = (room['kamar_mandi'] ?? '').toString().toLowerCase();
      return value.contains('dalam');
    }).length;
  }

  int get totalKamarMandiLuar {
    return rooms.where((room) {
      final value = (room['kamar_mandi'] ?? '').toString().toLowerCase();
      return value.contains('luar');
    }).length;
  }

  String shortRupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;

    if (number >= 1000000) {
      final juta = number / 1000000;
      final text = juta % 1 == 0 ? juta.toStringAsFixed(0) : juta.toStringAsFixed(1);
      return 'Rp ${text}Jt';
    }

    if (number >= 1000) {
      final ribu = number ~/ 1000;
      return 'Rp ${ribu}Ribu';
    }

    return 'Rp $number';
  }

  String roomImageUrl(dynamic image) {
    if (image == null || image.toString().isEmpty) {
      return '';
    }

    return ApiConfig.imageUrl(image.toString());
  }

  void clearSearch() {
    searchController.clear();
    setState(() {});
  }

  void openDetail(dynamic room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(room: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredRooms;

    return Scaffold(
      backgroundColor: Colors.white,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: fetchRooms,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                children: [
                  Text(
                    'Ada $totalKamar Kamar di Rafa Kost',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rafa Kost menyediakan total $totalKamar kamar dengan\n'
                    'pembagian $totalKamarMandiDalam kamar mandi dalam dan $totalKamarMandiLuar kamar\n'
                    'mandi luar, memberikan kenyamanan serta privasi\n'
                    'bagi setiap penghuni.',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  if (widget.initialSearch.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    searchBox(),
                  ],

                  const SizedBox(height: 16),

                  if (hasError)
                    errorBox()
                  else if (rooms.isEmpty)
                    emptyBox(
                      title: 'Belum ada kamar',
                      subtitle: 'Data kamar belum tersedia.',
                    )
                  else if (filtered.isEmpty)
                    emptyBox(
                      title: 'Kamar tidak ditemukan',
                      subtitle:
                          'Tidak ada kamar yang cocok dengan pencarian "${searchController.text}".',
                    )
                  else
                    ...filtered.map((room) {
                      return roomCard(room);
                    }),
                ],
              ),
            ),
    );
  }

  Widget searchBox() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF94A3B8),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 12,
                color: darkText,
              ),
              decoration: const InputDecoration(
                hintText: 'Cari kamar...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: clearSearch,
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF64748B),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget roomCard(dynamic room) {
    final imageUrl = roomImageUrl(room['image']);
    final status = (room['status'] ?? '').toString().toLowerCase();
    final isAvailable = status == 'tersedia';

    final price1 = shortRupiah(room['harga_1_orang']);
    final price2 = shortRupiah(room['harga_2_orang']);

    return Container(
      height: 205,
      margin: const EdgeInsets.only(bottom: 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                height: 105,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return placeholderImage(height: 105);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return placeholderImage(height: 105);
                        },
                      )
                    : placeholderImage(height: 105),
              ),
            ),
          ),

          Positioned(
            left: 8,
            top: 10,
            child: _topBadge(
              icon: Icons.bed_rounded,
              text: 'km, mandi ${room['kamar_mandi'] ?? '-'}',
              background: Colors.white,
              textColor: darkText,
            ),
          ),

          Positioned(
            right: 13,
            top: 10,
            child: _topBadge(
              icon: Icons.bed_rounded,
              text: isAvailable ? 'Tersedia' : 'Terisi',
              background: isAvailable
                  ? const Color(0xFFC9F8D3)
                  : const Color(0xFFFF9CA3),
              textColor: isAvailable
                  ? const Color(0xFF0B8F29)
                  : const Color(0xFF8A1118),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 73,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => openDetail(room),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.fromLTRB(13, 15, 13, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room['nama'] ?? 'Kamar',
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF9E9E9E),
                                  size: 17,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  room['lantai'] ?? '-',
                                  style: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F7FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$price1 – $price2',
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => openDetail(room),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBadge({
    required IconData icon,
    required String text,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 11,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget placeholderImage({double height = 105}) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 34,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget errorBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFD97706),
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Gagal mengambil data kamar',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Periksa koneksi internet atau server Rafa Kost.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF92400E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: fetchRooms,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyBox({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFF94A3B8),
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}