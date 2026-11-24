import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../cv/cv_store.dart';
import '../cv/cv.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../cv/cv_screen.dart';

/// Profil pengguna. Pengaturan akun menyusul.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.username});

  final String username;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CvData? _cv;
  bool _cvLoading = true;

  String get username => widget.username;

  @override
  void initState() {
    super.initState();
    _loadCv();
  }

  Future<void> _loadCv() async {
    CvData? cv;
    try {
      cv = await CvStore.load(username);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _cv = cv;
      _cvLoading = false;
    });
  }

  Future<void> _openCv() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => CvScreen(username: username)),
    );
    if (mounted) await _loadCv();
  }

  String _cvStatus() {
    if (_cvLoading) return 'Memuat...';
    final cv = _cv;
    if (cv == null) {
      return 'Belum ada CV. Isi dulu supaya bisa langsung apply ke company.';
    }
    final t = cv.updatedAt;
    String two(int v) => v.toString().padLeft(2, '0');
    final when = t == null
        ? ''
        : ' Diperbarui ${two(t.day)}/${two(t.month)}/${t.year}.';
    return 'CV sudah terisi.$when';
  }

  @override
  Widget build(BuildContext context) {
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kFieldBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CV',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _cvStatus(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CV hanya terlihat olehmu. Saat kamu apply ke '
                          'sebuah company, salinannya terkirim ke boss '
                          'company itu saja.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _cvLoading ? null : _openCv,
                          child: Text(_cv == null ? 'Isi CV' : 'Edit CV'),
                        ),
                      ],
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
