// Merapikan folder lib/ menjadi struktur per fitur.
//
// Cara pakai (jalankan dari folder utama project, sejajar pubspec.yaml):
//   dart run tool/reorganize.dart            -> hanya menampilkan rencana
//   dart run tool/reorganize.dart --apply    -> memindahkan file + memperbarui import
//
// Sebelum --apply, commit dulu pekerjaanmu supaya gampang dibatalkan
// (git checkout . ). File yang tidak ada di daftar dibiarkan di tempatnya.
import 'dart:io';

/// lama -> baru (relatif terhadap lib/). Nilai '' = hapus kalau tidak
/// dipakai file lain.
const moves = <String, String>{
  // widgets umum
  'screens/server/placeholder_tab.dart': 'widgets/placeholder_tab.dart',

  // auth
  'screens/login_screen.dart': 'features/auth/login_screen.dart',
  'screens/register_screen.dart': 'features/auth/register_screen.dart',
  'screens/splash_screen.dart': 'features/auth/splash_screen.dart',
  'screens/guest_gate.dart': 'features/auth/guest_gate.dart',
  'screens/app_router.dart': 'features/auth/app_router.dart',
  'data/mock_auth_store.dart': 'features/auth/mock_auth_store.dart',
  'data/supabase_auth_store.dart': 'features/auth/supabase_auth_store.dart',

  // dashboard
  'screens/dashboard/dashboard_screen.dart':
      'features/dashboard/dashboard_screen.dart',
  'screens/dashboard/dashboard_sidebar.dart':
      'features/dashboard/dashboard_sidebar.dart',
  'screens/dashboard/dashboard_right_panel.dart':
      'features/dashboard/dashboard_right_panel.dart',
  'screens/dashboard/home_tab.dart': 'features/dashboard/home_tab.dart',
  'screens/dashboard/guest_home_tab.dart':
      'features/dashboard/guest_home_tab.dart',
  'screens/dashboard/messages_tab.dart':
      'features/dashboard/messages_tab.dart',
  'screens/dashboard/profile_screen.dart':
      'features/dashboard/profile_screen.dart',

  // cv
  'screens/dashboard/cv_screen.dart': 'features/cv/cv_screen.dart',
  'data/cv_store.dart': 'features/cv/cv_store.dart',
  'models/cv.dart': 'features/cv/cv.dart',

  // server: layar
  'screens/create_server_screen.dart':
      'features/server/screens/create_server_screen.dart',
  'screens/join_server_screen.dart':
      'features/server/screens/join_server_screen.dart',
  'screens/server/server_home_screen.dart':
      'features/server/screens/server_home_screen.dart',
  'screens/server/server_switcher.dart':
      'features/server/screens/server_switcher.dart',
  'screens/server/overview_tab.dart':
      'features/server/screens/overview_tab.dart',
  'screens/server/announcement_screen.dart':
      'features/server/screens/announcement_screen.dart',
  'screens/server/sop_screen.dart': 'features/server/screens/sop_screen.dart',
  'screens/server/members_tab.dart':
      'features/server/screens/members_tab.dart',
  'screens/server/members_sidebar.dart':
      'features/server/screens/members_sidebar.dart',
  'screens/server/more_tab.dart': 'features/server/screens/more_tab.dart',
  'screens/server/projects_tab.dart':
      'features/server/screens/projects_tab.dart',
  'screens/server/project_detail_screen.dart':
      'features/server/screens/project_detail_screen.dart',
  'screens/server/project_form_screen.dart':
      'features/server/screens/project_form_screen.dart',
  'screens/server/payroll_tab.dart':
      'features/server/screens/payroll_tab.dart',

  // server: data
  'data/mock_server_store.dart': 'features/server/data/mock_server_store.dart',
  'data/supabase_server_store.dart':
      'features/server/data/supabase_server_store.dart',
  'data/mock_project_store.dart':
      'features/server/data/mock_project_store.dart',
  'data/supabase_project_store.dart':
      'features/server/data/supabase_project_store.dart',
  'data/mock_payroll_store.dart':
      'features/server/data/mock_payroll_store.dart',
  'data/supabase_payroll_store.dart':
      'features/server/data/supabase_payroll_store.dart',
  'data/mock_announcement_store.dart':
      'features/server/data/mock_announcement_store.dart',

  // server: model
  'models/server.dart': 'features/server/models/server.dart',
  'models/server_content.dart': 'features/server/models/server_content.dart',
  'models/project.dart': 'features/server/models/project.dart',
  'models/payroll.dart': 'features/server/models/payroll.dart',

  // server: widget
  'widgets/server_avatar.dart': 'features/server/widgets/server_avatar.dart',
  'widgets/blueprint_gallery.dart':
      'features/server/widgets/blueprint_gallery.dart',
  'widgets/payslip_card.dart': 'features/server/widgets/payslip_card.dart',
  'widgets/project_chips.dart': 'features/server/widgets/project_chips.dart',
  'widgets/money_input.dart': 'features/server/widgets/money_input.dart',

  // halaman lama yang sudah tidak dipakai
  'screens/home_screen.dart': '',
};

final _directive = RegExp(r'''(import|export|part)(\s+)(['"])([^'"]+)\3''');

/// Gabungkan [rel] ke folder milik [fromFile], selesaikan '.' dan '..'.
String resolve(String fromFile, String rel) {
  final parts = fromFile.split('/')..removeLast();
  for (final seg in rel.split('/')) {
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (seg != '.' && seg.isNotEmpty) {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

/// Path [to] relatif terhadap folder tempat [fromFile] berada.
String relative(String fromFile, String to) {
  final from = fromFile.split('/')..removeLast();
  final target = to.split('/');
  var common = 0;
  while (common < from.length &&
      common < target.length - 1 &&
      from[common] == target[common]) {
    common++;
  }
  final ups = List.filled(from.length - common, '..');
  return [...ups, ...target.sublist(common)].join('/');
}

bool _isProjectImport(String path) =>
    !path.startsWith('package:') && !path.startsWith('dart:');

void main(List<String> args) {
  final apply = args.contains('--apply');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Folder lib/ tidak ditemukan. Jalankan dari folder utama '
        'project (yang ada pubspec.yaml).');
    exit(1);
  }

  final files = <String, String>{}; // path relatif lib/ -> isi
  for (final e in libDir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) {
      final rel = e.path.replaceAll('\\', '/').replaceFirst(RegExp(r'^lib/'), '');
      files[rel] = e.readAsStringSync();
    }
  }

  // Rencana pemindahan hanya untuk file yang benar-benar ada.
  final plan = <String, String>{
    for (final e in moves.entries)
      if (files.containsKey(e.key)) e.key: e.value,
  };
  final missing = [for (final k in moves.keys) if (!files.containsKey(k)) k];
  final unmapped = [for (final k in files.keys) if (!moves.containsKey(k)) k];

  String finalPath(String old) => plan[old] ?? old;

  // Hapus halaman lama hanya kalau tidak ada yang mengimpornya.
  final deletable = <String>{};
  for (final e in plan.entries) {
    if (e.value.isNotEmpty) continue;
    var used = false;
    for (final f in files.entries) {
      if (f.key == e.key) continue;
      for (final m in _directive.allMatches(f.value)) {
        final p = m.group(4)!;
        if (_isProjectImport(p) && resolve(f.key, p) == e.key) used = true;
      }
    }
    if (used) {
      stdout.writeln('! ${e.key} masih dipakai, TIDAK dihapus.');
      plan[e.key] = e.key;
    } else {
      deletable.add(e.key);
    }
  }

  // Tulis ulang semua import.
  final rewritten = <String, String>{}; // path baru -> isi baru
  var changedImports = 0;
  for (final f in files.entries) {
    if (deletable.contains(f.key)) continue;
    final newPath = finalPath(f.key);
    final out = f.value.replaceAllMapped(_directive, (m) {
      final p = m.group(4)!;
      if (!_isProjectImport(p)) return m.group(0)!;
      final target = resolve(f.key, p);
      if (!files.containsKey(target)) return m.group(0)!;
      final newRel = relative(newPath, finalPath(target));
      if (newRel != p) changedImports++;
      return '${m.group(1)}${m.group(2)}${m.group(3)}$newRel${m.group(3)}';
    });
    rewritten[newPath] = out;
  }

  // Cek: semua import proyek harus menunjuk file yang ada.
  final broken = <String>[];
  rewritten.forEach((path, content) {
    for (final m in _directive.allMatches(content)) {
      final p = m.group(4)!;
      if (!_isProjectImport(p)) continue;
      if (!rewritten.containsKey(resolve(path, p))) broken.add('$path -> $p');
    }
  });

  final moved = plan.entries.where((e) => e.value.isNotEmpty && e.value != e.key);
  stdout.writeln('Dipindah : ${moved.length} file');
  stdout.writeln('Dihapus  : ${deletable.length} file ${deletable.toList()}');
  stdout.writeln('Import diperbarui: $changedImports');
  if (missing.isNotEmpty) {
    stdout.writeln('Tidak ada di project-mu (dilewati): ${missing.length}');
    for (final m in missing) {
      stdout.writeln('   $m');
    }
  }
  if (unmapped.isNotEmpty) {
    stdout.writeln('Tetap di tempatnya: ${unmapped.length}');
    for (final u in unmapped) {
      stdout.writeln('   $u');
    }
  }
  if (broken.isNotEmpty) {
    stderr.writeln('\nADA IMPORT YANG TIDAK DITEMUKAN, dibatalkan:');
    for (final b in broken) {
      stderr.writeln('   $b');
    }
    exit(2);
  }

  if (!apply) {
    stdout.writeln('\nIni baru rencana. Jalankan lagi dengan --apply untuk '
        'melakukannya.');
    return;
  }

  // Terapkan: hapus yang lama, tulis yang baru.
  for (final old in files.keys) {
    final f = File('lib/$old');
    if (f.existsSync()) f.deleteSync();
  }
  rewritten.forEach((path, content) {
    final f = File('lib/$path');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  });

  // Bersihkan folder kosong.
  final dirs = libDir
      .listSync(recursive: true)
      .whereType<Directory>()
      .toList()
    ..sort((a, b) => b.path.length.compareTo(a.path.length));
  for (final d in dirs) {
    if (d.listSync().isEmpty) d.deleteSync();
  }

  stdout.writeln('\nSelesai. Jalankan "flutter analyze" untuk memastikan.');
}
