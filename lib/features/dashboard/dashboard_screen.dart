import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show AppLogo, kFieldBorder;
import '../auth/app_router.dart';
import '../auth/guest_gate.dart';
import '../../widgets/placeholder_tab.dart';
import 'dashboard_right_panel.dart';
import 'dashboard_sidebar.dart';
import 'guest_home_tab.dart';
import 'home_tab.dart';
import 'messages_tab.dart';
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

  void _openSchedule() {
    if (_guest) {
      promptLogin(context, message: 'Masuk untuk memakai jadwal.');
      return;
    }
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openNotifications() {
    if (_guest) {
      promptLogin(context, message: 'Masuk untuk melihat notifikasi.');
      return;
    }
    showNotificationsDialog(context, _events);
  }

  /// HP: Pesan dibuka sebagai halaman sendiri dari ikon di bar atas.
  void _openMessages() {
    if (_guest) {
      promptLogin(context, message: 'Masuk untuk memakai pesan.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: const Text(
              'Pesan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          body: const MessagesTab(),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_index) {
      case 0:
        if (_guest) {
          return GuestHomeTab(onOpenTab: (i) => setState(() => _index = i));
        }
        return HomeTab(
          username: widget.username,
          onOpenServers: () => setState(() => _index = 6),
        );
      case 1:
        if (_guest) {
          return const GuestPrompt(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Pesan',
            message: 'Masuk untuk mengirim dan menerima pesan.',
          );
        }
        return const MessagesTab();
      case 2:
        return const PlaceholderTab(
          icon: Icons.work_outline_rounded,
          title: 'Lowongan',
          description:
              'Lihat company yang sedang merekrut, pilih yang cocok, '
              'lalu apply. CV dari profilmu terkirim otomatis ke boss.',
        );
      case 3:
        return const PlaceholderTab(
          icon: Icons.business_rounded,
          title: 'Perusahaan & Tim',
          description:
              'Temukan perusahaan dan tim yang sedang membuka '
              'kesempatan, lengkap dengan profilnya.',
        );
      case 4:
        return const PlaceholderTab(
          icon: Icons.handshake_outlined,
          title: 'Freelance',
          description:
              'Papan iklan jasa dari orang ke orang, tanpa harus '
              'masuk company. Iklan berbayar tampil di urutan atas.',
        );
      case 5:
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
    return DashboardRightPanel(
      events: _events,
      onAddEvent: (event) => setState(() => _events.add(event)),
      onRemoveEvent: (event) => setState(() => _events.remove(event)),
    );
  }

  Widget _panelButtons({bool chat = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chat)
          IconButton(
            tooltip: 'Pesan',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: _openMessages,
          ),
        IconButton(
          tooltip: 'Notifikasi',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: _openNotifications,
        ),
        IconButton(
          tooltip: 'Jadwal',
          icon: const Icon(Icons.event_outlined),
          onPressed: _openSchedule,
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
                  leading: _guest
                      ? null
                      : IconButton(
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
                  actions: [
                    if (_guest)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: GuestAuthButtons(expand: false),
                      )
                    else
                      _panelButtons(),
                  ],
                ),
          endDrawer: wide || _guest
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
                  // Pesan tidak ada di navigasi bawah, jadi indeksnya digeser.
                  selectedIndex: _index > kMessagesTabIndex ? _index - 1 : 0,
                  onDestinationSelected: (i) => setState(
                    () => _index = i >= kMessagesTabIndex ? i + 1 : i,
                  ),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (var t = 0; t < kDashboardTabs.length; t++)
                      if (t != kMessagesTabIndex)
                        NavigationDestination(
                          icon: Icon(kDashboardTabs[t].icon),
                          label: kDashboardTabs[t].shortLabel,
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
                          if (!wide && !_guest)
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
                                children: [_panelButtons(chat: false)],
                              ),
                            ),
                          Expanded(child: _content()),
                        ],
                      ),
                    ),
                    if (wide && !_guest) _rightPanel(),
                  ],
                )
              : _content(),
        );
      },
    );
  }
}
