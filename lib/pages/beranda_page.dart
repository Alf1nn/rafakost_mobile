import 'package:flutter/material.dart';

class BerandaPage extends StatefulWidget {
  final void Function(String keyword)? onSearchKamar;
  final VoidCallback? onOpenKamar;
  final VoidCallback? onOpenMaps;
  final VoidCallback? onOpenVerifikasi;

  const BerandaPage({
    super.key,
    this.onSearchKamar,
    this.onOpenKamar,
    this.onOpenMaps,
    this.onOpenVerifikasi,
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void submitSearch() {
    final keyword = searchController.text.trim();

    if (keyword.isEmpty) {
      widget.onOpenKamar?.call();
      return;
    }

    widget.onSearchKamar?.call(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeroSection(),
          _buildQuickActions(),
          _buildTentangKamiSection(),
          _buildFasilitasSection(),
          _buildTestimoniSection(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: 450,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=800',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1E293B),
              );
            },
          ),
          Container(
            color: Colors.black.withOpacity(0.35),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_work, color: Colors.white, size: 36),
                    SizedBox(width: 12),
                    Text(
                      'Rafa Kost',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nyaman, Aman, Terjangkau',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Temukan hunian nyaman dengan fasilitas lengkap dan lokasi strategis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.search, color: Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => submitSearch(),
                          decoration: const InputDecoration(
                            hintText: 'Cari kamar mandi luar...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: submitSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cari',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _quickButton(
              icon: Icons.bed_rounded,
              title: 'Lihat Kamar',
              subtitle: 'Kamar tersedia',
              onTap: widget.onOpenKamar,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _quickButton(
              icon: Icons.location_on_rounded,
              title: 'Lokasi',
              subtitle: 'Alamat kos',
              onTap: widget.onOpenMaps,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTentangKamiSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TENTANG KAMI'),
          const SizedBox(height: 12),
          const Text(
            'Kadang, tempat terbaik itu nggak perlu dicari jauh-jauh.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hunian nyaman bisa jadi lebih dekat dari yang kamu kira.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '#RAFAKOST',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _roundedImage(
                  'https://images.unsplash.com/photo-1554995207-c18c203602cb?fit=crop&w=400',
                  height: 180,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _roundedImage(
                  'https://images.unsplash.com/photo-1502672260266-1c1de2d9d0cb?fit=crop&w=400',
                  height: 180,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.black54,
                height: 1.6,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: 'Rafa Kost ',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      'hadir dengan fasilitas lengkap, lingkungan aman, dan lokasi strategis untuk hunian nyaman tanpa ribet—cocok untuk mahasiswa maupun pekerja.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFasilitasSection() {
    final fasilitas = [
      {
        'title': 'Bebas Listrik',
        'img':
            'https://images.unsplash.com/photo-1544724569-5f546fd6f2b6?fit=crop&w=300',
      },
      {
        'title': 'Air',
        'img':
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?fit=crop&w=300',
      },
      {
        'title': 'Dapur Bersama',
        'img':
            'https://images.unsplash.com/photo-1556910103-1c02745aae4d?fit=crop&w=300',
      },
      {
        'title': 'Parkiran',
        'img':
            'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?fit=crop&w=300',
      },
      {
        'title': 'Lokasi Strategis',
        'img':
            'https://images.unsplash.com/photo-1524661135-423995f22d0b?fit=crop&w=300',
      },
      {
        'title': 'Wifi',
        'img':
            'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?fit=crop&w=300',
      },
      {
        'title': 'CCTV',
        'img':
            'https://images.unsplash.com/photo-1557800636-894a64c1696f?fit=crop&w=300',
      },
    ];

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _FasilitasHeader(),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: fasilitas.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildCardFasilitas(
                  fasilitas[index]['title']!,
                  fasilitas[index]['img']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFasilitas(String title, String imageUrl) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.42),
            BlendMode.darken,
          ),
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTestimoniSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: 'Apa Kata ',
                  style: TextStyle(color: Colors.black87),
                ),
                TextSpan(
                  text: '#Penghuni',
                  style: TextStyle(color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setiap penghuni punya cerita pengalaman mereka menemukan kost terbaik',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 36,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '"Kosan nyaman, view bagus depan lapangan enak buat piknik"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Khasanah Uswatun',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Mahasiswa',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _roundedImage(String imageUrl, {required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        color: Colors.grey.shade300,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FasilitasHeader extends StatelessWidget {
  const _FasilitasHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'FASILITAS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Beberapa Fasilitas Rafa Kost',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nikmati berbagai fasilitas yang dirancang untuk menunjang kenyamanan dan kebutuhan harian Anda.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}