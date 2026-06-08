import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

class AppUpdateService {
  static bool _shown = false;

  static Future<void> check(BuildContext context) async {
    if (_shown) return;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 1;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/app-version'),
        headers: {
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        return;
      }

      final latestBuild = int.tryParse(data['latest_build'].toString()) ?? 1;
      final forceUpdate = data['force_update'] == true;
      final apkUrl = data['apk_url']?.toString() ?? '';
      final message = data['message']?.toString() ??
          'Versi baru tersedia. Silakan update aplikasi.';

      if (latestBuild <= currentBuild || apkUrl.isEmpty) {
        return;
      }

      _shown = true;

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (_) {
          return WillPopScope(
            onWillPop: () async => !forceUpdate,
            child: AlertDialog(
              title: const Text(
                'Update Aplikasi',
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
                    final uri = Uri.parse(apkUrl);
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: const Text('Update Sekarang'),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      return;
    }
  }
}