import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/session_manager.dart';
import '../../models/server.dart';
import '../../widgets/app_feedback.dart';
import '../../data/mock_server_store.dart';
import '../app_router.dart';
import '../login_screen.dart';
import 'more_tab.dart';
import 'members_sidebar.dart';
import 'overview_tab.dart';
import 'placeholder_tab.dart';
import 'payroll_tab.dart';
import 'projects_tab.dart';
import 'server_switcher.dart';

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
  List<ServerMembership> _memberships = const [];

  bool get _isAdmin => widget.role == ServerRole.admin;

  @override
  void initState() {
    super.initState();
    // Isi awal: hanya server ini. Daftar lengkap dimuat sesudahnya.
    _memberships = [ServerMembership(server: widget.server, role: widget.role)];
    MockServerStore.setLastServer(widget.username, widget.server.id);
    _loadMemberships();
  }

  Future<void> _loadMemberships() async {
    final memberships = await MockServerStore.getMemberships(widget.username);
    if (!mounted || memberships.isEmpty) return;
    setState(() => _memberships = memberships);
  }

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
      label: 'Gaji',
      title: 'Gaji',
      description: 'Rekap gaji builder dari project yang sudah disetujui. '
          'Fungsinya menyusul.',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
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

  /// Tinggalkan server (khusus builder): keanggotaan dihapus dan kuota
  /// gabung bertambah. Setelah itu pindah ke server lain, atau ke halaman
  /// "belum punya server" kalau tidak ada.
  Future<void> _leaveServer() async {
    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.logout_rounded,
      color: kErrorColor,
      title: 'Tinggalkan server?',
      message: 'Kamu akan keluar dari ${widget.server.name}. Kamu bisa '
          'bergabung lagi nanti dengan token dari admin.',
      confirmLabel: 'Tinggalkan',
    );
    if (confirmed != true || !mounted) return;

    try {
      await MockServerStore.leave(
        serverId: widget.server.id,
        username: widget.username,
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      showToast(context, e.message);
      return;
    }
    if (!mounted) return;
    await openStartScreen(context, widget.username);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildPage() {
    if (_index == 0) {
      final overview = OverviewTab(
        username: widget.username,
        server: widget.server,
        role: widget.role,
      );
      // Daftar anggota di kanan, hanya di Beranda dan hanya di layar lebar.
      return LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth < 900) return overview;
          return Row(
            children: [
              Expanded(child: overview),
              MembersSidebar(
                server: widget.server,
                username: widget.username,
              ),
            ],
          );
        },
      );
    }

    if (_index == 1) {
      return ProjectsTab(
        server: widget.server,
        username: widget.username,
        role: widget.role,
      );
    }
    if (_index == _destinations.length - 1) {
      return MoreTab(
        role: widget.role,
        server: widget.server,
        onLeaveServer: _leaveServer,
        onLogout: _logout,
      );
    }

    final destination = _destinations[_index];
    if (destination.label == 'Gaji') {
      return PayrollTab(
        key: ValueKey('gaji-${widget.role.name}'),
        server: widget.server,
        username: widget.username,
        role: widget.role,
        onOpenProjects: () => setState(() => _index = 1),
      );
    }
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
    // Navigasi di samping penuh dari atas ke bawah; dropdown server dan
    // lencana peran berada di sebelah kanan navigasi.
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _SideNav(
              destinations: _destinations,
              selectedIndex: _index,
              onSelected: (value) => setState(() => _index = value),
            ),
            Expanded(
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    titleSpacing: 16,
                    centerTitle: false,
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: ServerSwitcher(
                        username: widget.username,
                        current: widget.server,
                        memberships: _memberships,
                      ),
                    ),
                    actions: [
                      _RoleBadge(isAdmin: _isAdmin),
                      const SizedBox(width: 16),
                    ],
                  ),
                  Expanded(child: _buildPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigasi samping untuk semua tab (admin dan builder).
class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: Color(0xFF2E2942))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                minWidth: 60,
                selectedIndex: selectedIndex,
                backgroundColor: Colors.transparent,
                indicatorColor: const Color(0x335865F2),
                labelType: NavigationRailLabelType.all,
                selectedLabelTextStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
                onDestinationSelected: onSelected,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(
                        d.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
