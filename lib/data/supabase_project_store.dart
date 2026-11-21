import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';
import 'mock_server_store.dart' show ServerException;

/// Implementasi manajemen project builder menggunakan Supabase Database & Storage.
class SupabaseProjectStore {
  SupabaseProjectStore._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Mengambil daftar semua project di sebuah server.
  static Future<List<Project>> list(String serverId) async {
    try {
      final res = await _client
          .from('projects')
          .select('''
            id,
            title,
            from_client,
            payment_amount,
            payment_note,
            detail,
            deadline,
            max_workers,
            author_name,
            created_at,
            status,
            tags,
            project_workers(worker_name),
            project_updates(id, author_name, text, sent_at),
            project_blueprints(name, file_url)
          ''')
          .eq('server_id', serverId)
          .order('created_at', ascending: false);

      final list = <Project>[];
      for (final row in (res as List)) {
        final workersList = (row['project_workers'] as List? ?? [])
            .map((w) => w['worker_name'] as String? ?? '')
            .where((w) => w.isNotEmpty)
            .toList();

        final updatesList = (row['project_updates'] as List? ?? [])
            .map((u) {
              return ProjectUpdate(
                author: u['author_name'] as String? ?? '',
                text: u['text'] as String? ?? '',
                sentAt: DateTime.tryParse(u['sent_at'] as String? ?? '') ??
                    DateTime.now(),
              );
            })
            .toList()
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

        final blueprintsList = (row['project_blueprints'] as List? ?? [])
            .map((b) {
              return Blueprint(
                name: b['name'] as String? ?? '',
                bytes: Uint8List(0),
                url: b['file_url'] as String?,
              );
            })
            .toList();

        final statusStr = row['status'] as String? ?? 'available';
        final status = switch (statusStr) {
          'onProgress' => ProjectStatus.onProgress,
          'review' => ProjectStatus.review,
          'finished' => ProjectStatus.finished,
          _ => ProjectStatus.available,
        };

        final tags = (row['tags'] as List? ?? [])
            .map((t) => t.toString())
            .toList();

        list.add(
          Project(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
            from: row['from_client'] as String? ?? '',
            paymentAmount: (row['payment_amount'] as num?)?.toInt() ?? 0,
            paymentNote: row['payment_note'] as String? ?? '',
            detail: row['detail'] as String? ?? '',
            deadline: DateTime.tryParse(row['deadline'] as String? ?? '') ??
                DateTime.now(),
            maxWorkers: (row['max_workers'] as num?)?.toInt() ?? 1,
            author: row['author_name'] as String? ?? '',
            createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
                DateTime.now(),
            tags: tags,
            status: status,
            workers: workersList,
            updates: updatesList,
            blueprints: blueprintsList,
          ),
        );
      }
      return list;
    } catch (e) {
      debugPrint('Error listing projects: $e');
      return const [];
    }
  }

  /// Membuat project baru oleh Admin.
  static Future<Project> create({
    required String serverId,
    required String author,
    required String title,
    required String from,
    required int paymentAmount,
    String paymentNote = '',
    required String detail,
    required DateTime deadline,
    required int maxWorkers,
    List<String> tags = const [],
    List<Blueprint> blueprints = const [],
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    try {
      final insertRes = await _client.from('projects').insert({
        'server_id': serverId,
        'title': title.trim(),
        'from_client': from.trim(),
        'payment_amount': paymentAmount,
        'payment_note': paymentNote.trim(),
        'detail': detail.trim(),
        'deadline': deadline.toIso8601String(),
        'max_workers': maxWorkers,
        'author_id': user?.id,
        'author_name': author,
        'status': 'available',
        'tags': tags,
        'created_at': now.toIso8601String(),
      }).select().single();

      final projectId = insertRes['id'] as String;

      // Upload blueprints jika ada
      final uploadedBlueprints = <Blueprint>[];
      if (blueprints.isNotEmpty) {
        for (var i = 0; i < blueprints.length; i++) {
          final b = blueprints[i];
          try {
            final fileName = '$projectId/${DateTime.now().millisecondsSinceEpoch}_${b.name}';
            await _client.storage.from('blueprints').uploadBinary(
              fileName,
              b.bytes,
            );
            final fileUrl = _client.storage.from('blueprints').getPublicUrl(fileName);

            await _client.from('project_blueprints').insert({
              'project_id': projectId,
              'name': b.name,
              'file_path': fileName,
              'file_url': fileUrl,
            });

            uploadedBlueprints.add(Blueprint(
              name: b.name,
              bytes: b.bytes,
              url: fileUrl,
            ));
          } catch (storageErr) {
            debugPrint('Failed to upload blueprint: $storageErr');
            uploadedBlueprints.add(b);
          }
        }
      }

      return Project(
        id: projectId,
        title: title.trim(),
        from: from.trim(),
        paymentAmount: paymentAmount,
        paymentNote: paymentNote.trim(),
        detail: detail.trim(),
        deadline: deadline,
        maxWorkers: maxWorkers,
        author: author,
        createdAt: now,
        tags: tags,
        status: ProjectStatus.available,
        workers: const [],
        updates: const [],
        blueprints: uploadedBlueprints.isNotEmpty ? uploadedBlueprints : blueprints,
      );
    } catch (e) {
      throw ServerException('Gagal membuat project: ${e.toString()}');
    }
  }

  /// Builder mengambil project (Claim).
  static Future<Project> claim({
    required String serverId,
    required String projectId,
    required String username,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ServerException('Sesi masuk berakhir. Silakan login kembali.');
    }

    try {
      // Ambil data project saat ini
      final projRes = await _client
          .from('projects')
          .select('status, max_workers, project_workers(worker_name)')
          .eq('id', projectId)
          .single();

      final currentWorkers = (projRes['project_workers'] as List? ?? [])
          .map((w) => w['worker_name'] as String? ?? '')
          .toList();

      if (currentWorkers.any((w) => w.toLowerCase() == username.toLowerCase())) {
        throw const ServerException('Kamu sudah mengambil project ini.');
      }

      final statusStr = projRes['status'] as String? ?? 'available';
      if (statusStr != 'available' && statusStr != 'onProgress') {
        throw const ServerException('Project ini sudah tidak bisa diambil.');
      }

      final maxWorkers = (projRes['max_workers'] as num?)?.toInt() ?? 1;
      if (currentWorkers.length >= maxWorkers) {
        throw const ServerException('Slot worker sudah penuh.');
      }

      // Masukkan ke project_workers
      await _client.from('project_workers').insert({
        'project_id': projectId,
        'user_id': user.id,
        'worker_name': username,
      });

      // Update status ke onProgress
      await _client
          .from('projects')
          .update({'status': 'onProgress'})
          .eq('id', projectId);

      // Ambil daftar project terbaru
      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Gagal mengambil project: ${e.toString()}');
    }
  }

  /// Mengirim update progress ke project.
  static Future<Project> addUpdate({
    required String serverId,
    required String projectId,
    required String author,
    required String text,
    List<Blueprint> photos = const [],
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    try {
      await _client.from('project_updates').insert({
        'project_id': projectId,
        'user_id': user?.id,
        'author_name': author,
        'text': text.trim(),
        'sent_at': now.toIso8601String(),
      });

      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      throw ServerException('Gagal mengirim update: ${e.toString()}');
    }
  }

  /// Menandai project selesai untuk review admin.
  static Future<Project> markDone({
    required String serverId,
    required String projectId,
    required String username,
  }) async {
    try {
      await _client
          .from('projects')
          .update({'status': 'review'})
          .eq('id', projectId);

      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      throw ServerException('Gagal menandai selesai: ${e.toString()}');
    }
  }

  /// Admin menerima hasil review (Finished).
  static Future<Project> accept({
    required String serverId,
    required String projectId,
  }) async {
    try {
      await _client
          .from('projects')
          .update({'status': 'finished'})
          .eq('id', projectId);

      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      throw ServerException('Gagal menyetujui project: ${e.toString()}');
    }
  }

  /// Admin menolak hasil review, kembali ke onProgress dengan alasan.
  static Future<Project> decline({
    required String serverId,
    required String projectId,
    required String reviewer,
    String reason = '',
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    try {
      await _client
          .from('projects')
          .update({'status': 'onProgress'})
          .eq('id', projectId);

      if (reason.trim().isNotEmpty) {
        await _client.from('project_updates').insert({
          'project_id': projectId,
          'user_id': user?.id,
          'author_name': reviewer,
          'text': 'Decline: ${reason.trim()}',
          'sent_at': now.toIso8601String(),
        });
      }

      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      throw ServerException('Gagal menolak review: ${e.toString()}');
    }
  }

  /// Mengatur tags pada project.
  static Future<Project> setTags({
    required String serverId,
    required String projectId,
    required List<String> tags,
  }) async {
    try {
      await _client
          .from('projects')
          .update({'tags': tags})
          .eq('id', projectId);

      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      throw ServerException('Gagal mengubah tag: ${e.toString()}');
    }
  }

  /// Menambah blueprint ke project yang sudah ada.
  static Future<Project> addBlueprints({
    required String serverId,
    required String projectId,
    required List<Blueprint> items,
  }) async {
    try {
      for (final b in items) {
        final fileName = '$projectId/${DateTime.now().millisecondsSinceEpoch}_${b.name}';
        await _client.storage.from('blueprints').uploadBinary(fileName, b.bytes);
        final fileUrl = _client.storage.from('blueprints').getPublicUrl(fileName);

        await _client.from('project_blueprints').insert({
          'project_id': projectId,
          'name': b.name,
          'file_path': fileName,
          'file_url': fileUrl,
        });
      }

      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      throw ServerException('Gagal mengupload blueprint: ${e.toString()}');
    }
  }

  /// Menghapus blueprint dari project.
  static Future<Project> removeBlueprint({
    required String serverId,
    required String projectId,
    required int index,
  }) async {
    try {
      final res = await _client
          .from('project_blueprints')
          .select('id, file_path')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);

      if (index >= 0 && index < (res as List).length) {
        final item = res[index];
        final id = item['id'] as String;
        final path = item['file_path'] as String;

        await _client.storage.from('blueprints').remove([path]);
        await _client.from('project_blueprints').delete().eq('id', id);
      }

      final listUpdated = await list(serverId);
      return listUpdated.firstWhere((p) => p.id == projectId);
    } catch (e) {
      throw ServerException('Gagal menghapus blueprint: ${e.toString()}');
    }
  }
}
