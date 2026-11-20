import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/project.dart';
import 'app_feedback.dart';

const _maxBytes = 5 * 1024 * 1024;
const _maxItems = 10;

/// Memilih gambar blueprint dari perangkat. Gambar > 5 MB dilewati.
Future<List<Blueprint>> pickBlueprints(
  BuildContext context, {
  int already = 0,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: true,
    withData: true,
  );
  if (result == null) return const [];

  final picked = <Blueprint>[];
  var skipped = 0;
  for (final file in result.files) {
    final bytes = file.bytes;
    if (bytes == null ||
        bytes.length > _maxBytes ||
        already + picked.length >= _maxItems) {
      skipped++;
      continue;
    }
    picked.add(Blueprint(name: file.name, bytes: bytes));
  }
  if (skipped > 0 && context.mounted) {
    showToast(
      context,
      '$skipped gambar dilewati (maks 5 MB per gambar, '
      '$_maxItems gambar per project).',
    );
  }
  return picked;
}

void previewBlueprint(BuildContext context, Blueprint item) =>
    const BlueprintGallery(items: <Blueprint>[])._preview(context, item);

/// Galeri besar yang bisa digeser ke samping (tampilan di kartu project).
class BlueprintCarousel extends StatelessWidget {
  const BlueprintCarousel({super.key, required this.items, this.height = 170});

  final List<Blueprint> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    final multi = items.length > 1;
    return SizedBox(
      height: height,
      child: Center(
        child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AspectRatio(
          aspectRatio: 1.3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: () => previewBlueprint(context, items[i]),
                  child: Image.memory(items[i].bytes, fit: BoxFit.cover),
                ),
                if (multi)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}/${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
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

/// Galeri kecil blueprint. Ketuk gambar untuk memperbesar; kalau [onRemove]
/// diisi (admin), tiap gambar punya tombol hapus.
class BlueprintGallery extends StatelessWidget {
  const BlueprintGallery({super.key, required this.items, this.onRemove});

  final List<Blueprint> items;
  final void Function(int index)? onRemove;

  void _preview(BuildContext context, Blueprint item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 6,
                child: Center(
                  child: Image.memory(item.bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _preview(context, items[i]),
                      child: Image.memory(
                        items[i].bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onRemove!(i),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
