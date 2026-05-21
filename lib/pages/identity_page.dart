import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class IdentityPage extends StatefulWidget {
  const IdentityPage({super.key});

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  bool loading = true;
  bool submitting = false;

  Map<String, dynamic>? user;

  final ImagePicker picker = ImagePicker();

  File? ktpFile;
  File? selfieFile;
  File? selfieKtpFile;

  String? ktpBase64;
  String? selfieBase64;
  String? selfieKtpBase64;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  Future<void> fetchProfile() async {
    final token = await getToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      setState(() {
        user = data['user'];
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<String> fileToBase64DataUrl(File file) async {
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);

    return 'data:image/jpeg;base64,$base64String';
  }

  Future<void> pickKtp() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (picked == null) return;

    setState(() {
      ktpFile = File(picked.path);
    });
  }

  Future<void> takeSelfie() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final file = File(picked.path);
    final base64Data = await fileToBase64DataUrl(file);

    setState(() {
      selfieFile = file;
      selfieBase64 = base64Data;
    });
  }

  Future<void> takeSelfieKtp() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final file = File(picked.path);
    final base64Data = await fileToBase64DataUrl(file);

    setState(() {
      selfieKtpFile = file;
      selfieKtpBase64 = base64Data;
    });
  }

  Future<void> submitVerification() async {
    if (ktpFile == null) {
      showMessage('Silakan pilih foto KTP terlebih dahulu.');
      return;
    }

    if (selfieBase64 == null || selfieBase64!.isEmpty) {
      showMessage('Silakan ambil live selfie wajah terlebih dahulu.');
      return;
    }

    if (selfieKtpBase64 == null || selfieKtpBase64!.isEmpty) {
      showMessage('Silakan ambil selfie sambil pegang KTP terlebih dahulu.');
      return;
    }

    final token = await getToken();

    if (token == null || token.isEmpty) {
      showMessage('Token login tidak ditemukan. Silakan login ulang.');
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/identity/upload'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'ktp_photo',
          ktpFile!.path,
        ),
      );

      request.fields['selfie_base64'] = selfieBase64!;
      request.fields['selfie_ktp_base64'] = selfieKtpBase64!;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        showMessage(data['message'] ?? 'Data verifikasi berhasil dikirim.');

        setState(() {
          ktpFile = null;
          selfieFile = null;
          selfieKtpFile = null;
          ktpBase64 = null;
          selfieBase64 = null;
          selfieKtpBase64 = null;
        });

        await fetchProfile();
      } else {
        showMessage(data['message'] ?? 'Gagal mengirim verifikasi.');
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Tidak bisa terhubung ke server.');
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Color statusColor(String? status) {
    if (status == 'approved') return const Color(0xFF16A34A);
    if (status == 'pending') return const Color(0xFF2563EB);
    if (status == 'manual_review') return const Color(0xFFD97706);
    if (status == 'rejected') return const Color(0xFFDC2626);

    return const Color(0xFF2563EB);
  }

  String statusTitle(String? status) {
    if (status == 'approved') return 'Identitas Disetujui';
    if (status == 'pending') return 'Sedang Diproses';
    if (status == 'manual_review') return 'Perlu Review Admin';
    if (status == 'rejected') return 'Verifikasi Ditolak';

    return 'Belum Verifikasi';
  }

  String statusDescription(String? status) {
    if (status == 'approved') {
      return 'Akun kamu sudah bisa melakukan booking kamar.';
    }

    if (status == 'pending') {
      return 'Data identitas kamu sedang dikirim ke sistem verifikasi otomatis.';
    }

    if (status == 'manual_review') {
      return user?['identity_rejection_reason'] ??
          'Hasil verifikasi otomatis belum yakin, admin akan mengecek manual.';
    }

    if (status == 'rejected') {
      return user?['identity_rejection_reason'] ??
          'Silakan upload ulang foto KTP dan selfie yang lebih jelas.';
    }

    return 'Kamu harus verifikasi identitas sebelum bisa booking kamar.';
  }

  IconData statusIcon(String? status) {
    if (status == 'approved') return Icons.check_rounded;
    if (status == 'pending') return Icons.schedule_rounded;
    if (status == 'manual_review') return Icons.warning_amber_rounded;
    if (status == 'rejected') return Icons.close_rounded;

    return Icons.info_outline_rounded;
  }

  bool canUpload(String? status) {
    return status != 'approved' && status != 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final status = user?['identity_status'];
    final color = statusColor(status);
    final uploadAllowed = canUpload(status);

    return Scaffold(
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(45, 28, 45, 24),
                children: [
                  const Text(
                    'Verifikasi Identitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload foto KTP,live selfie wajah,dan selfie sambil\npegang KTP untuk mengaktifkan fitur booking\nkamar.',
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (status == 'approved')
                    approvedSuccessBanner()
                  else ...[
                    statusBanner(color, status),
                    const SizedBox(height: 16),
                    if (status == 'pending')
                      pendingCard()
                    else
                      uploadCard(uploadAllowed),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget approvedSuccessBanner() {
    return Container(
      width: double.infinity,
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFC9F8D3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: const BoxDecoration(
              color: Color(0xFF00C928),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_box_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 18),
          const Text(
            'Identitas disetujui',
            style: TextStyle(
              color: Color(0xFF00A824),
              fontSize: 19,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget statusBanner(Color color, String? status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon(status),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription(status),
                  style: TextStyle(
                    color: color,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pendingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: Color(0xFF2563EB),
            size: 64,
          ),
          const SizedBox(height: 14),
          const Text(
            'Data sedang diproses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sistem ML sedang mengecek foto KTP dan live selfie wajah. Silakan refresh beberapa saat lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: fetchProfile,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Refresh Status',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget uploadCard(bool uploadAllowed) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stepsInfo(),
          const SizedBox(height: 22),
          uploadBox(
            title: 'Foto KTP',
            subtitle: 'Pilih foto KTP dari galeri. JPG, PNG, WEBP — maks 4MB.',
            icon: Icons.badge_outlined,
            file: ktpFile,
            onTap: pickKtp,
            buttonText: 'Pilih Foto KTP',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: uploadBox(
                  title: 'Live Selfie Wajah',
                  subtitle: 'Ambil foto wajah saja, tanpa KTP.',
                  icon: Icons.face_retouching_natural,
                  file: selfieFile,
                  onTap: takeSelfie,
                  buttonText: 'Ambil Selfie',
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: uploadBox(
                  title: 'Selfie + KTP',
                  subtitle: 'Ambil foto wajah sambil pegang KTP.',
                  icon: Icons.switch_account_outlined,
                  file: selfieKtpFile,
                  onTap: takeSelfieKtp,
                  buttonText: 'Selfie KTP',
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          infoNote(
            color: const Color(0xFFF8FAFC),
            borderColor: const Color(0xFFE2E8F0),
            iconColor: const Color(0xFF64748B),
            textColor: const Color(0xFF64748B),
            text:
                'Sistem ML akan mengecek foto KTP dan live selfie wajah. Selfie sambil pegang KTP disimpan sebagai bukti tambahan untuk admin jika hasil masuk review manual.',
          ),
          const SizedBox(height: 12),
          infoNote(
            color: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            iconColor: const Color(0xFFDC2626),
            textColor: const Color(0xFF991B1B),
            text:
                'Rafa Kost khusus perempuan. Jika sistem mendeteksi laki-laki dengan confidence tinggi, verifikasi akan ditolak otomatis.',
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: submitting || !uploadAllowed ? null : submitVerification,
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                submitting ? 'Mengirim...' : 'Kirim Verifikasi',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget stepsInfo() {
    return Row(
      children: [
        Expanded(
          child: stepItem('1', 'Foto KTP', 'KTP jelas'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: stepItem('2', 'Live Selfie', 'Wajah jelas'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: stepItem('3', 'Selfie + KTP', 'Bukti admin'),
        ),
      ],
    );
  }

  Widget stepItem(String number, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget uploadBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    required String buttonText,
    bool compact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file == null
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF2563EB),
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file,
                  height: compact ? 120 : 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: compact ? 90 : 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  icon,
                  size: compact ? 38 : 48,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              file == null ? subtitle : '✓ Foto sudah dipilih',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: file == null
                    ? const Color(0xFF64748B)
                    : const Color(0xFF2563EB),
                fontSize: compact ? 11 : 12,
                fontWeight: file == null ? FontWeight.w500 : FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoNote({
    required Color color,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}