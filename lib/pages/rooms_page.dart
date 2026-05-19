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

  String rupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;

    return 'Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
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

  @override
  Widget build(BuildContext context) {
    final filtered = filteredRooms;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: fetchRooms,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Daftar Kamar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih kamar yang tersedia di Rafa Kost.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 16),

                  searchBox(),

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Cari nama kamar, lantai, kamar mandi...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            IconButton(
              onPressed: clearSearch,
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  Widget roomCard(dynamic room) {
    final image = room['image'];
    final imageUrl = roomImageUrl(image);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomDetailPage(room: room),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return placeholderImage(height: 180);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return placeholderImage(height: 180);
                        },
                      )
                    : placeholderImage(height: 180),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room['nama'] ?? 'Kamar',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        statusBadge(room['status']),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.layers_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            room['lantai'] ?? '-',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.bathroom_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Kamar mandi ${room['kamar_mandi'] ?? '-'}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          priceRow(
                            label: '1 orang',
                            value: '${rupiah(room['harga_1_orang'])} / bulan',
                            strong: true,
                          ),
                          const SizedBox(height: 6),
                          priceRow(
                            label: '2 orang',
                            value: '${rupiah(room['harga_2_orang'])} / bulan',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      height: 42,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailPage(room: room),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget priceRow({
    required String label,
    required String value,
    bool strong = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: strong ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            fontWeight: FontWeight.w900,
            fontSize: strong ? 14 : 13,
          ),
        ),
      ],
    );
  }

  Widget statusBadge(dynamic status) {
    final value = (status ?? '').toString().toLowerCase();

    final isAvailable = value == 'tersedia';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAvailable ? 'Tersedia' : 'Terisi',
        style: TextStyle(
          color: isAvailable ? const Color(0xFF15803D) : const Color(0xFFDC2626),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget placeholderImage({double height = 180}) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
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