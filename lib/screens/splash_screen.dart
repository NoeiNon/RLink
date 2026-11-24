import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../core/session_manager.dart';
import 'app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    _timer = Timer(AppConstants.splashDuration, _goNext);
  }

  Future<void> _goNext() async {
    if (!mounted) return;

    final loggedInUsername = await SessionManager.checkSession();
    if (!mounted) return;

    if (loggedInUsername != null && loggedInUsername.isNotEmpty) {
      await openStartScreen(context, loggedInUsername);
    } else {
      // Belum login: boleh melihat-lihat dulu sebagai tamu.
      await openStartScreen(context, '');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gaya sama seperti login/register: latar gradient + isi kecil dan rapi di tengah.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2250), Color(0xFF5865F2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: const SizedBox(
                  width: 260,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LogoMark(),
                      SizedBox(height: 10),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        AppConstants.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: Colors.white,
                          backgroundColor: Color(0x33FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo animasi (WebP): assets/images/logo.webp
/// Flutter memutar WebP/GIF beranimasi otomatis lewat Image.asset.
/// Kalau file tidak ditemukan, tampil ikon sementara.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.webp',
      width: 120,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.construction_rounded,
        size: 56,
        color: AppColors.accent,
      ),
    );
  }
}
