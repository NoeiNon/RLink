import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/server.dart';
import '../../widgets/app_feedback.dart';
import '../../data/mock_server_store.dart';
import '../app_router.dart';
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
      description:
          'Buat dan publish project, atur judul, deskripsi, blueprint '
          'dan tags. Cek progress builder, lalu Accept atau Decline hasilnya.',
      icon: Icons.hardware_outlined,
      selectedIcon: Icons.hardware_rounded,
    ),
    _Destination(
      label: 'Gaji',
      title: 'Gaji',
      description:
          'Rekap gaji builder dari project yang sudah disetujui. '
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
      description:
          'Lihat project yang tersedia, claim, upload progress '
          'tiap saat, lalu mark as done kalau sudah selesai.',
      icon: Icons.hardware_outlined,
      selectedIcon: Icons.hardware_rounded,
    ),
    _Destination(
      label: 'Gaji',
      title: 'Gaji',
      description:
          'Saldo dan riwayat gaji dari project yang sudah '
          'disetujui boss.',
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
      message:
          'Kamu akan keluar dari ${widget.server.name}. Kamu bisa '
          'bergabung lagi nanti dengan token dari boss.',
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

  /// Hapus server permanen (khusus boss), dikonfirmasi 3 langkah:
  /// 1) tekan "Hapus server", 2) setujui peringatan, 3) ketik ulang nama
  /// server lalu konfirmasi "Hapus permanen".
  Future<void> _deleteServer() async {
    final serverName = widget.server.name;

    final first = await showConfirmDialog(
      context,
      icon: Icons.delete_forever_rounded,
      color: kErrorColor,
      title: 'Hapus server?',
      message:
          'Kamu akan menghapus $serverName. Semua anggota, project, '
          'SOP, dan obrolan di server ini ikut hilang.',
      confirmLabel: 'Lanjutkan',
    );
    if (first != true || !mounted) return;

    final controller = TextEditingController();
    final matches = ValueNotifier<bool>(false);
    controller.addListener(() {
      matches.value = controller.text.trim() == serverName;
    });

    final second = await showConfirmDialog(
      context,
      icon: Icons.warning_amber_rounded,
      color: kErrorColor,
      title: 'Hapus permanen?',
      message:
          'Tindakan ini tidak bisa dibatalkan. Ketik nama server '
          '"$serverName" persis seperti tertulis untuk memastikan.',
      confirmLabel: 'Hapus permanen',
      body: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: serverName,
          isDense: true,
          filled: true,
        ),
      ),
      confirmEnabled: matches,
    );

    // Tunggu animasi dialog selesai sebelum membuang controller.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      controller.dispose();
      matches.dispose();
    });

    if (second != true || !mounted) return;

    try {
      await MockServerStore.deleteServer(
        serverId: widget.server.id,
        username: widget.username,
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      showToast(context, e.message);
      return;
    }
    if (!mounted) return;
    showToast(context, 'Server "$serverName" sudah dihapus.');
    await openStartScreen(context, widget.username);
  }

  void _logout() => logoutToLogin(context);

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
              MembersSidebar(server: widget.server, username: widget.username),
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
        onDeleteServer: _deleteServer,
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

  void _backToDashboard() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      openStartScreen(context, widget.username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 760;
        final content = _CompactScope(child: _buildPage());

        // HP: navigasi bawah, dropdown server dan lencana peran di atas.
        if (!wide) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              scrolledUnderElevation: 0,
              toolbarHeight: 52,
              leading: IconButton(
                tooltip: 'Kembali ke beranda',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _backToDashboard,
              ),
              titleSpacing: 0,
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
                const SizedBox(width: 12),
              ],
            ),
            body: SafeArea(child: content),
            bottomNavigationBar: NavigationBar(
              backgroundColor: AppColors.surface,
              height: 62,
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );
        }

        // Layar lebar: sidebar kiri bergaya sama seperti beranda utama.
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                _ServerSidebar(
                  destinations: _destinations,
                  selectedIndex: _index,
                  onSelected: (value) => setState(() => _index = value),
                  onBack: _backToDashboard,
                ),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        scrolledUnderElevation: 0,
                        toolbarHeight: 52,
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
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Memadatkan isi tab server: teks sedikit lebih kecil, kepadatan komponen
/// rapat, tombol dan kolom isian lebih pendek.
class _CompactScope extends StatelessWidget {
  const _CompactScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final base = Theme.of(context);
    // Hormati ukuran teks sistem (aksesibilitas), lalu kecilkan sedikit.
    final factor = media.textScaler.scale(14) / 14 * 0.92;

    ButtonStyle compact(ButtonStyle? style) =>
        (style ?? const ButtonStyle()).copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(factor)),
      child: Theme(
        data: base.copyWith(
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: base.inputDecorationTheme.copyWith(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: compact(base.filledButtonTheme.style),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: compact(base.outlinedButtonTheme.style),
          ),
          textButtonTheme: TextButtonThemeData(
            style: compact(base.textButtonTheme.style),
          ),
          listTileTheme: base.listTileTheme.copyWith(dense: true),
        ),
        child: child,
      ),
    );
  }
}

/// Sidebar kiri layar server: tombol kembali ke beranda dan tab server.
class _ServerSidebar extends StatelessWidget {
  const _ServerSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onBack,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: Color(0xFF2E2942))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Beranda',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Text(
              'SERVER',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _ServerNavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerNavItem extends StatelessWidget {
  const _ServerNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0x335865F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 18,
                  color: selected ? AppColors.accent : color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
    final background = isAdmin
        ? const Color(0x335865F2)
        : const Color(0x333BA55D);
    final foreground = isAdmin
        ? const Color(0xFFB5BCFF)
        : const Color(0xFF6FD08C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? 'Boss' : 'Builder',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
