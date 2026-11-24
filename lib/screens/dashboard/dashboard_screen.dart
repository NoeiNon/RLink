import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show AppLogo, kFieldBorder;
import '../app_router.dart';
import '../guest_gate.dart';
import '../server/placeholder_tab.dart';
import 'dashboard_right_panel.dart';
import 'dashboard_sidebar.dart';
import 'guest_home_tab.dart';
import 'home_tab.dart';
import 'profile_screen.dart';

/// Beranda utama aplikasi. Layar lebar: sidebar kiri (navigasi + profil),
/// konten di tengah, sidebar kanan (pesan, notifikasi, jadwal). Layar
/// sedang: sidebar kanan dibuka lewat ikon. HP: navigasi bawah dan ikon
/// di atas.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.username});

  final String username;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _wideBreakpoint = 1100;
  static const double _mediumBreakpoint = 760;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  int _rightTab = 0;
  final List<ScheduleItem> _events = [];

  bool get _guest => widget.username.isEmpty;

  void _openProfile() {
    if (_guest) {
      promptLogin(
        context,
        message: 'Masuk untuk melihat dan mengisi profilmu.',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(username: widget.username),
      ),
    );
  }

  void _openRightPanel(int tab) {
    if (_guest) {
      promptLogin(
        context,
        message: 'Masuk untuk memakai pesan, notifikasi, dan jadwal.',
      );
      return;
    }
    setState(() => _rightTab = tab);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Widget _content() {
    switch (_index) {
      case 0:
        if (_guest) {
          return GuestHomeTab(onOpenTab: (i) => setState(() => _index = i));
        }
        return HomeTab(
          username: widget.username,
          onOpenServers: () => setState(() => _index = 5),
        );
      case 1:
        return const PlaceholderTab(
          icon: Icons.work_outline_rounded,
          title: 'Lowongan',
          description:
              'Lihat company yang sedang merekrut, pilih yang cocok, '
              'lalu apply. CV dari profilmu terkirim otomatis ke boss.',
        );
      case 2:
        return const PlaceholderTab(
          icon: Icons.business_rounded,
          title: 'Perusahaan & Tim',
          description:
              'Temukan perusahaan dan tim yang sedang membuka '
              'kesempatan, lengkap dengan profilnya.',
        );
      case 3:
        return const PlaceholderTab(
          icon: Icons.handshake_outlined,
          title: 'Freelance',
          description:
              'Papan iklan jasa dari orang ke orang, tanpa harus '
              'masuk company. Iklan berbayar tampil di urutan atas.',
        );
      case 4:
        return const PlaceholderTab(
          icon: Icons.storefront_rounded,
          title: 'Store',
          description:
              'Jual barangmu atau jadi supplier, dan cari barang '
              'dari penjual lain.',
        );
      default:
        if (_guest) {
          return const GuestPrompt(
            icon: Icons.dns_rounded,
            title: 'Server milikmu',
            message:
                'Masuk untuk membuat server atau melihat server yang '
                'kamu ikuti.',
          );
        }
        return ServersTab(username: widget.username);
    }
  }

  Widget _rightPanel() {
    if (_guest) {
      return Container(
        width: 300,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(left: BorderSide(color: kFieldBorder)),
        ),
        child: const GuestPrompt(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Pesan, notifikasi, jadwal',
          message: 'Masuk untuk mulai memakainya.',
        ),
      );
    }
    return DashboardRightPanel(
      key: ValueKey(_rightTab),
      initialTab: _rightTab,
      events: _events,
      onAddEvent: (event) => setState(() => _events.add(event)),
      onRemoveEvent: (event) => setState(() => _events.remove(event)),
    );
  }

  Widget _panelButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Pesan',
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          onPressed: () => _openRightPanel(0),
        ),
        IconButton(
          tooltip: 'Notifikasi',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => _openRightPanel(1),
        ),
        IconButton(
          tooltip: 'Jadwal',
          icon: const Icon(Icons.event_outlined),
          onPressed: () => _openRightPanel(2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= _wideBreakpoint;
        final medium = width >= _mediumBreakpoint;

        final sidebar = DashboardSidebar(
          index: _index,
          onSelect: (i) => setState(() => _index = i),
          username: widget.username,
          onProfile: _openProfile,
          onLogout: () => logoutToLogin(context),
          onLogin: () => openLoginFromGuest(context),
          onRegister: () => openRegisterFromGuest(context),
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          appBar: medium
              ? null
              : AppBar(
                  backgroundColor: AppColors.surface,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    tooltip: 'Profil',
                    icon: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        widget.username.isEmpty
                            ? '?'
                            : widget.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onPressed: _openProfile,
                  ),
                  title: const AppLogo(width: 36),
                  actions: [_panelButtons()],
                ),
          endDrawer: wide
              ? null
              : Drawer(
                  width: 300,
                  backgroundColor: AppColors.surface,
                  child: _rightPanel(),
                ),
          bottomNavigationBar: medium
              ? null
              : NavigationBar(
                  backgroundColor: AppColors.surface,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final tab in kDashboardTabs)
                      NavigationDestination(
                        icon: Icon(tab.icon),
                        label: tab.shortLabel,
                      ),
                  ],
                ),
          body: medium
              ? Row(
                  children: [
                    sidebar,
                    Expanded(
                      child: Column(
                        children: [
                          if (!wide)
                            Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: kFieldBorder),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [_panelButtons()],
                              ),
                            ),
                          Expanded(child: _content()),
                        ],
                      ),
                    ),
                    if (wide) _rightPanel(),
                  ],
                )
              : _content(),
        );
      },
    );
  }
}
