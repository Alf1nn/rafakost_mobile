import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  static const blue = Color(0xFF0798E8);
  static const darkText = Color(0xFF111111);
  static const greyText = Color(0xFF8A8A8A);

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
          _buildTentangKamiSection(),
          _buildBenefitSection(),
          _buildFasilitasSection(),
          _buildTestimoniSection(),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: 296,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_utama.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.22),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(33, 70, 33, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _assetIcon(
                      'assets/images/logo.png',
                      width: 31,
                      height: 31,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Rafa Kost',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nyaman, Aman,\nTerjangkau',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 0.95,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 31,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFFB8B8B8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => submitSearch(),
              style: const TextStyle(
                fontSize: 11,
                color: darkText,
              ),
              decoration: const InputDecoration(
                hintText: 'Cari kamar berdasarkan tipe',
                hintStyle: TextStyle(
                  color: Color(0xFFB8B8B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 1),
              ),
            ),
          ),
          GestureDetector(
            onTap: submitSearch,
            child: Container(
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Cari',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTentangKamiSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(33, 32, 33, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('TENTANG KAMI'),
          const SizedBox(height: 11),
          const Text(
            'Kadang, tempat terbaik itu nggak perlu dicari jauh-jauh.',
            style: TextStyle(
              color: darkText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hunian nyaman bisa jadi lebih dekat dari yang kamu kira.',
            style: TextStyle(
              color: darkText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _assetImageBox(
                  'assets/images/tentangkami1.png',
                  height: 139,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _assetImageBox(
                  'assets/images/tentangkami2.png',
                  height: 139,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                color: greyText,
                fontSize: 11,
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: 'Rafa Kost ',
                  style: TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w500,
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

  Widget _buildBenefitSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(33, 24, 33, 0),
      child: Column(
        children: [
          _benefitItem(
            iconPath: 'assets/images/nyaman-logo.svg',
            title: 'Nyaman',
            subtitle: 'Kamar bersih, tenang, dan nyaman',
          ),
          const SizedBox(height: 15),
          _benefitItem(
            iconPath: 'assets/images/aman-logo.svg',
            title: 'Aman',
            subtitle: 'Lingkungan terjaga dengan baik 24/7',
          ),
          const SizedBox(height: 15),
          _benefitItem(
            iconPath: 'assets/images/terjangkau-logo.svg',
            title: 'Terjangkau',
            subtitle: 'Harga bersahabat sesuai kebutuhan',
          ),
        ],
      ),
    );
  }

  Widget _benefitItem({
    required String iconPath,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFD8F2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(9),
          child: _assetIcon(
            iconPath,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFC3C3C3),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFasilitasSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(33, 47, 33, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('FASILITAS'),
          const SizedBox(height: 13),
          const Text(
            'Beberapa fasilitas rafa kost',
            style: TextStyle(
              color: darkText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Nikmati berbagai fasilitas yang dirancang untuk\nmenunjang kenyamanan dan kebutuhan harian\nAnda.',
            style: TextStyle(
              color: darkText,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1
          SizedBox(
            height: 126,
            child: Row(
              children: [
                Expanded(
                  child: _fasilitasCard(
                    title: 'Bebas Listrik',
                    subtitle: '(Pemakaian Sewajarnya)',
                    imagePath: 'assets/images/bebaslistrik-fasilitas.png',
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _fasilitasCard(
                    title: 'Air',
                    subtitle: '(Pemakaian Sewajarnya)',
                    imagePath: 'assets/images/air-fasilitas.png',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // Row 2
          SizedBox(
            height: 126,
            child: Row(
              children: [
                Expanded(
                  child: _fasilitasCard(
                    title: 'Parkiran',
                    subtitle: '',
                    imagePath: 'assets/images/parkiran-fasilitas.png',
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _fasilitasCard(
                    title: 'Dapur\nBersama',
                    subtitle: '',
                    imagePath: 'assets/images/dapur-fasilitas.png',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // Row 3
          SizedBox(
            height: 126,
            child: Row(
              children: [
                Expanded(
                  child: _fasilitasCard(
                    title: 'Lokasi\nStrategis',
                    subtitle: '',
                    imagePath: 'assets/images/lokasi-fasilitas.png',
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _fasilitasCard(
                    title: 'Wifi',
                    subtitle: '',
                    imagePath: 'assets/images/wifi-fasilitas.png',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // CCTV full width
          SizedBox(
            width: double.infinity,
            height: 126,
            child: _fasilitasCard(
              title: 'CCTV',
              subtitle: '',
              imagePath: 'assets/images/cctv-fasilitas.png',
            ),
          ),
        ],
      ),
    );
  }

  Widget _fasilitasCard({
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.18),
          ),
          Positioned(
            left: 18,
            bottom: 17,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 0.95,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimoniSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(33, 44, 33, 0),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: 'Apa Kata ',
                  style: TextStyle(color: darkText),
                ),
                TextSpan(
                  text: '#Penghuni',
                  style: TextStyle(color: blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Setiap pengguna punya cerita. Inilah\npengalaman mereka menemukan kost yang\ntepat bersama Sekitar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: greyText,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            height: 239,
            padding: const EdgeInsets.fromLTRB(31, 28, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  child: Text(
                    '“',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 56,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 72,
                  child: Text(
                    'Kosan nyaman, view bagus depan\nlapangan enak buat piknik',
                    style: TextStyle(
                      color: Color(0xFF6D6D6D),
                      fontSize: 14,
                      height: 1.1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '-Khasanah Uswatun',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Mahasiswa',
                        style: TextStyle(
                          color: Color(0xFFC3C3C3),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      _circleArrow(Icons.arrow_back),
                      const SizedBox(width: 6),
                      _circleArrow(Icons.arrow_forward),
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

  Widget _circleArrow(IconData icon) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 12,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        const Icon(
          Icons.wb_sunny_outlined,
          size: 16,
          color: Colors.black,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _assetImageBox(
    String path, {
    required double height,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _assetIcon(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
    );
  }
}