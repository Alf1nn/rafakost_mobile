import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

import 'beranda_page.dart';
import 'my_rentals_page.dart';
import 'rooms_page.dart';
import 'maps_page.dart';
import 'identity_page.dart';
import 'login_page.dart';
import 'payment_history_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int currentIndex = 0;

  String userName = 'User';
  String userEmail = '';
  String kamarSearchKeyword = '';

  final List<String> pageTitles = const [
    'Beranda',
    'Kamar saya',
    'Kamar',
    'Maps',
    'Verifikasi',
    'Riwayat Invoice',
  ];

  @override
  void initState() {
    super.initState();
    loadUser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate();
      checkTestimonialPopup();
    });
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      userEmail = prefs.getString('user_email') ?? '';
    });
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('Yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('api_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void goToTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void searchKamar(String keyword) {
    setState(() {
      kamarSearchKeyword = keyword;
      currentIndex = 2;
    });
  }

  Future<void> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/app-version'),
        headers: {
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode != 200 || data['success'] != true) {
        return;
      }

      final latestBuild = int.tryParse(data['latest_build'].toString()) ?? 0;

      if (latestBuild > currentBuild) {
        showUpdateDialog(data);
      }
    } catch (_) {
      // Diamkan saja agar tidak mengganggu user saat buka aplikasi.
    }
  }

  void showUpdateDialog(Map data) {
    final forceUpdate = data['force_update'] == true;
    final message = data['message']?.toString() ??
        'Versi baru tersedia. Silakan update aplikasi.';
    final apkUrl = data['apk_url']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Update tersedia',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(message),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti'),
              ),
            ElevatedButton(
              onPressed: () async {
                if (apkUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link update belum tersedia.'),
                    ),
                  );
                  return;
                }

                final url = Uri.parse(apkUrl);

                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkTestimonialPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/testimonial/popup'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true &&
          data['show_popup'] == true) {
        showTestimonialPopup(data['booking']);
      }
    } catch (_) {
      // Tidak perlu munculkan error agar user tidak terganggu saat buka app.
    }
  }

  Future<void> submitTestimonial({
    required int rating,
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token login tidak ditemukan. Silakan login ulang.'),
        ),
      );

      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/testimonials'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rating': rating,
          'message': message,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Testimoni berhasil dikirim.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal mengirim testimoni.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa terhubung ke server.'),
        ),
      );
    }
  }

  void showTestimonialPopup(dynamic booking) {
    final messageController = TextEditingController();
    int rating = 5;

    final invoice =
        booking is Map ? booking['invoice']?.toString() ?? '-' : '-';

    final kamar = booking is Map && booking['kamar'] is Map
        ? booking['kamar']['nama']?.toString() ?? '-'
        : '-';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bagaimana kesan kamu tinggal di Rafa Kost?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Ceritakan pengalaman kamu selama menyewa kamar di Rafa Kost.',
                            style: TextStyle(
                              color: Color(0xFFE0F2FE),
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Invoice sewa',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  invoice,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Kamar',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  kamar,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rating',
                              style: TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: rating,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 5,
                                child: Text('⭐⭐⭐⭐⭐ Sangat puas'),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text('⭐⭐⭐⭐ Puas'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('⭐⭐⭐ Cukup'),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text('⭐⭐ Kurang'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('⭐ Tidak puas'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                rating = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Kesan / Testimoni',
                              style: TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: messageController,
                            minLines: 3,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText:
                                  'Contoh: Kostnya nyaman, fasilitas lengkap, lingkungan aman...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Testimoni kamu akan langsung tampil di bagian Apa Kata Penghuni.',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF64748B),
                                    side: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Nanti saja',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final message =
                                        messageController.text.trim();

                                    if (message.length < 10) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Kesan minimal 10 karakter.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    submitTestimonial(
                                      rating: rating,
                                      message: message,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0EA5E9),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Kirim',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    final pages = [
      BerandaPage(
        onSearchKamar: searchKamar,
        onOpenKamar: () => goToTab(2),
        onOpenMaps: () => goToTab(3),
        onOpenVerifikasi: () => goToTab(4),
      ),
      const MyRentalsPage(),
      RoomsPage(
        initialSearch: kamarSearchKeyword,
      ),
      const MapsPage(),
      const IdentityPage(),
      const PaymentHistoryPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(42),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 0.6,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/iconnav.png',
                        width: 15,
                        height: 15,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.circle_outlined,
                            size: 15,
                            color: Colors.black,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pageTitles[currentIndex],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  offset: const Offset(0, 34),
                  color: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'payment_history') {
                      goToTab(5);
                    }

                    if (value == 'logout') {
                      logout();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: SizedBox(
                        width: 210,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFBDEBFF),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Color(0xFF1677A8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (userEmail.isNotEmpty)
                                    Text(
                                      userEmail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'payment_history',
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF111827),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Riwayat Invoice',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: const Color(0xFFBDEBFF),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Color(0xFF1677A8),
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF111827),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: pages[currentIndex],
      bottomNavigationBar: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.noScaling,
        ),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 46,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  bottomNavItem(
                    index: 0,
                    label: 'Beranda',
                    iconPath: 'assets/icons/home.svg',
                  ),
                  bottomNavItem(
                    index: 1,
                    label: 'Kamar saya',
                    iconPath: 'assets/icons/door.svg',
                  ),
                  bottomNavItem(
                    index: 2,
                    label: 'Kamar',
                    iconPath: 'assets/icons/bed.svg',
                  ),
                  bottomNavItem(
                    index: 3,
                    label: 'Maps',
                    iconPath: 'assets/icons/maps.svg',
                  ),
                  bottomNavItem(
                    index: 4,
                    label: 'Verifikasi',
                    iconPath: 'assets/icons/profile.svg',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomNavItem({
    required int index,
    required String label,
    required String iconPath,
  }) {
    final active = currentIndex == index;

    const activeColor = Color(0xFF0798E8);
    const inactiveColor = Color(0xFFBCBEC0);

    final color = active ? activeColor : inactiveColor;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                currentIndex = index;
              });
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: SizedBox(
              height: 46,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 21,
                    height: 21,
                    colorFilter: ColorFilter.mode(
                      color,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      height: 1,
                      letterSpacing: -0.25,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}