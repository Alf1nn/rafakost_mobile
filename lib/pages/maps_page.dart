
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  static const double latitude = -7.40618758966827;
  static const double longitude = 109.23281022798868;

  static const LatLng rafaKostLocation = LatLng(latitude, longitude);

  final MapController mapController = MapController();

  Future<void> openGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps?q=$latitude,$longitude',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildMapWithCard(),
          _buildLocationInfo(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMapWithCard() {
    return SizedBox(
      height: 500,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 390,
            width: double.infinity,
            child: FlutterMap(
              key: const ValueKey('rafa-kost-map-close-zoom'),
              mapController: mapController,
              options: MapOptions(
                initialCenter: rafaKostLocation,
                initialZoom: 18.3,
                minZoom: 5,
                maxZoom: 19,
                onMapReady: () {
                  mapController.move(rafaKostLocation, 18.3);
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.rafakost_mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: rafaKostLocation,
                      width: 250, // Diperlebar dari 150 ke 250 agar muat teks dan ikon
                      height: 80,
                      child: OverflowBox(
                        maxWidth: 250,
                        maxHeight: 80,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFFE53935),
                              size: 58,
                            ),
                            Transform.translate(
                              offset: const Offset(-7, 0),
                              child: const Text(
                                'RAFA KOST',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            left: 39,
            right: 39,
            top: 320,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 22, 32, 23),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rafa Kost',
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Brigjend encung, Purwokerto Utara,\nBanyumas, Jawa Tengah',
                    style: TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 27,
                    child: OutlinedButton(
                      onPressed: openGoogleMaps,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0798E8),
                        side: const BorderSide(
                          color: Color(0xFFBDBDBD),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Buka di google maps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(39, 8, 39, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi Strategis',
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _infoItem('Dekat kampus'),
          const SizedBox(height: 14),
          _infoItem('Akses mudah'),
          const SizedBox(height: 14),
          _infoItem('Lingkungan aman dan nyaman'),
          const SizedBox(height: 14),
          _infoItem('Dekat fasilitas umum'),
        ],
      ),
    );
  }

  Widget _infoItem(String text) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF0798E8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wb_sunny_outlined,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
