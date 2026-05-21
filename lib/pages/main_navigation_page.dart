import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'beranda_page.dart';
import 'my_rentals_page.dart';
import 'rooms_page.dart';
import 'maps_page.dart';
import 'identity_page.dart';
import 'login_page.dart';

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
  ];

  @override
  void initState() {
    super.initState();
    loadUser();
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
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      // TOP NAVBAR
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

      // BOTTOM NAVBAR
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