import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/server.dart';
import '../../widgets/server_avatar.dart';
import '../home_screen.dart';
import '../login_screen.dart';
import 'more_tab.dart';
import 'overview_tab.dart';
import 'placeholder_tab.dart';

class _Destination {
  const _Destination({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String title;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
}

/// Template homepage server. Tab navigasi bawah dibedakan menurut peran:
/// admin mengelola, builder mengerjakan. Isi tiap tab (selain Beranda)
/// masih placeholder dan dikerjakan satu per satu di tahap berikutnya.
class ServerHomeScreen extends StatefulWidget {
  const ServerHomeScreen({
    super.key,
    required this.username,
    required this.server,
    required this.role,
  });

  final String username;
  final ServerInfo server;
  final ServerRole role;

  @override
  State<ServerHomeScreen> createState() => _ServerHomeScreenState();
}

class _ServerHomeScreenState extends State<ServerHomeScreen> {
  int _index = 0;

  bool get _isAdmin => widget.role == ServerRole.admin;

  static const _beranda = _Destination(
    label: 'Beranda',
    title: 'Beranda',
    description: '',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  );

  static const _lainnya = _Destination(
    label: 'Lainnya',
    title: 'Lainnya',
    description: '',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  );

  static const _adminDestinations = [
    _beranda,
    _Destination(
      label: 'Project',
      title: 'Project',
      description: 'Buat dan publish project, atur judul, deskripsi, blueprint '
          'dan tags. Cek progress builder, lalu Accept atau Decline hasilnya.',
      icon: Icons.hardware_outlined,
      selectedIcon: Icons.hardware_rounded,
    ),
    _Destination(
      label: 'Blueprint',
      title: 'Blueprint',
      description: 'Kelola blueprint dan referensi bangunan untuk project.',
      icon: Icons.architecture_outlined,
      selectedIcon: Icons.architecture_rounded,
    ),
    _Destination(
      label: 'Anggota',
      title: 'Anggota',
      description: 'Daftar builder di servermu, status aktif atau libur, '
          'dan progress yang sedang mereka kerjakan.',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
    ),
    _lainnya,
  ];

  static const _builderDestinations = [
    _beranda,
    _Destination(
      label: 'Project',
      title: 'Project',
      description: 'Lihat project yang tersedia, claim, upload progress '
          'tiap saat, lalu mark as done kalau sudah selesai.',
      icon: Icons.hardware_outlined,
      selectedIcon: Icons.hardware_rounded,
    ),
    _Destination(
      label: 'Blueprint',
      title: 'Blueprint',
      description: 'Lihat rencana dan blueprint bangunan. Kamu juga bisa '
          'menambahkan referensi untuk project yang kamu ambil.',
      icon: Icons.architecture_outlined,
      selectedIcon: Icons.architecture_rounded,
    ),
    _Destination(
      label: 'Gaji',
      title: 'Gaji',
      description: 'Saldo dan riwayat gaji dari project yang sudah '
          'disetujui admin.',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
    ),
    _lainnya,
  ];

  List<_Destination> get _destinations =>
      _isAdmin ? _adminDestinations : _builderDestinations;

  // TODO: setelah ada daftar server, "Keluar dari server" kembali ke daftar
  // server, bukan ke halaman "belum punya server". Di data contoh, keanggotaan
  // juga belum benar-benar dihapus.
  void _leaveServer() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(username: widget.username),
      ),
      (route) => false,
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildPage() {
    if (_index == 0) {
      return OverviewTab(
        username: widget.username,
        server: widget.server,
        role: widget.role,
      );
    }

    if (_index == _destinations.length - 1) {
      return MoreTab(
        role: widget.role,
        onLeaveServer: _leaveServer,
        onLogout: _logout,
      );
    }

    final destination = _destinations[_index];
    return PlaceholderTab(
      // Kunci per tab supaya posisi scroll tab lain tidak terbawa.
      key: ValueKey('${widget.role.name}-$_index'),
      icon: destination.selectedIcon,
      title: destination.title,
      description: destination.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            ServerAvatar(
              colorIndex: widget.server.colorIndex,
              iconIndex: widget.server.iconIndex,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.server.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _RoleBadge(isAdmin: _isAdmin),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: AppColors.surface,
        indicatorColor: const Color(0x335865F2),
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

/// Lencana peran di pojok kanan atas.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final background =
        isAdmin ? const Color(0x335865F2) : const Color(0x333BA55D);
    final foreground =
        isAdmin ? const Color(0xFFB5BCFF) : const Color(0xFF6FD08C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Builder',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
