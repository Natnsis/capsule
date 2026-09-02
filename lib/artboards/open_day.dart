import 'dart:io';

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../capsule_format.dart';
import '../nav.dart';
import '../rich_text.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'new_capsule.dart';

class OpenDayScreen extends StatelessWidget {
  const OpenDayScreen({super.key, this.title = 'To me, at 25', this.capsuleId});

  final String title;
  final int? capsuleId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final capsule = capsuleId == null ? null : store.byId(capsuleId!);

    final heading = capsule?.title ?? title;
    final note = capsule?.note ??
        "Hey. You're 25 now, which sounds impossible from here. I'm writing this "
            "from the small desk by the window, the one that wobbles.\n\nThings I "
            "hope are still true: you still call home on Sundays, you still keep "
            "the notebook. Things I hope changed: the fear of starting.";
    final images = capsule?.attachments.where((a) => a.isImage).toList() ?? const [];
    final files = capsule?.attachments.where((a) => !a.isImage).toList() ?? const [];

    final openedLine = capsule?.openedAt != null
        ? 'Opened ${fmtDay(capsule!.openedAt!)}'
        : 'Opened today · ${fmtDay(DateTime.now())}';
    final writtenLine = capsule != null
        ? 'Written ${fmtDay(capsule.createdAt)}'
        : 'Written 12 Sep 2024 · sealed for 2 years, 3 days';

    return Screen(
      color: C.paper,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => back(context),
                  child: IconChip(
                    size: 46,
                    radius: 23,
                    color: C.lav1,
                    child: Icon(Icons.arrow_back, size: 20, color: C.ink),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => showComingSoon(
                        context,
                        icon: Icons.share_outlined,
                        title: 'Sharing is on the way',
                        message:
                            'Capsules live only on this device for now. Sharing a capsule you’ve opened arrives in a later update.',
                      ),
                      child: IconChip(
                        size: 46,
                        radius: 23,
                        color: C.lav1,
                        child: Icon(Icons.share_outlined, size: 19, color: C.ink),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => showComingSoon(
                        context,
                        icon: Icons.download_outlined,
                        title: 'Export is on the way',
                        message:
                            'Your note and its files stay on this device for now. Saving them out arrives in a later update.',
                      ),
                      child: IconChip(
                        size: 46,
                        radius: 23,
                        color: C.lav1,
                        child: Icon(Icons.download_outlined, size: 19, color: C.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.greenBg, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LockGlyph(size: 13, color: C.greenInk, stroke: 2.1, open: true),
                  const SizedBox(width: 7),
                  Text(openedLine,
                      style: C.t(12.5, weight: FontWeight.w700, color: C.greenInk)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(heading,
                style: C.t(38, weight: FontWeight.w800, letterSpacing: -.035, height: 1.04)),
            const SizedBox(height: 8),
            Text(writtenLine, style: C.t(13.5, weight: FontWeight.w600, color: C.muted3)),
            const SizedBox(height: 20),
            if (images.isNotEmpty) ...[
              _ImageStrip(paths: images.map((a) => a.path).toList()),
              const SizedBox(height: 22),
            ] else if (capsule == null) ...[
              Row(
                children: [
                  _demoPhoto(const [Color(0xFFE9D3DB), Color(0xFFC3AEE0)],
                      const Alignment(0.9, 0.9), const [Color(0xFFFDF0F3), Color(0xFFB784C9)]),
                  const SizedBox(width: 10),
                  _demoPhoto(const [Color(0xFFD5E6DF), Color(0xFFB9C9E8)],
                      const Alignment(-0.9, -0.9), const [Colors.white, Color(0xFF8FA9D6)]),
                ],
              ),
              const SizedBox(height: 22),
            ],
            Markup(note, style: C.t(16.5, color: C.ink3, height: 1.75)),
            if (files.isNotEmpty) ...[
              const SizedBox(height: 22),
              for (final f in files) ...[
                _FileRow(name: f.name, kind: f.kind),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => go(context, const NewCapsuleScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(color: C.lav2, borderRadius: BorderRadius.circular(32)),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration:
                          BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: Icon(Icons.add, size: 20, color: C.onFill),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Write one back', style: C.t(16, weight: FontWeight.w700)),
                          Text('Reply to yourself, seal it for later',
                              style: C.t(13, weight: FontWeight.w500, color: C.muted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: C.ink),
                  ],
                ),
              ),
            ),
            if (capsule != null) ...[
              const SizedBox(height: 18),
              Center(child: _DeleteTile(capsule: capsule)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _demoPhoto(List<Color> base, Alignment blobAt, List<Color> blobColors) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 118,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: base),
          ),
          child: Stack(
            children: [
              Align(
                alignment: blobAt,
                child: Blob(size: 125, center: const Alignment(-0.3, -0.4), colors: blobColors),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.paths});
  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final file = File(paths[i]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 150,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : ColoredBox(
                      color: C.lav3,
                      child: Icon(Icons.broken_image_outlined, color: C.muted),
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// A quiet "delete this capsule" affordance at the foot of an opened capsule.
/// The weight of the decision lives in the confirmation, not this row.
class _DeleteTile extends StatefulWidget {
  const _DeleteTile({required this.capsule});
  final Capsule capsule;

  @override
  State<_DeleteTile> createState() => _DeleteTileState();
}

class _DeleteTileState extends State<_DeleteTile> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    final gone = await confirmAndDeleteCapsule(context, widget.capsule);
    if (!mounted) return;
    if (gone) {
      back(context);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _run,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 16, color: C.muted3),
            const SizedBox(width: 7),
            Text('Delete this capsule',
                style: C.t(13.5, weight: FontWeight.w700, color: C.muted3)),
          ],
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.name, required this.kind});
  final String name;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final playable = kind == 'audio' || kind == 'video';
    final leading = switch (kind) {
      'audio' => Icons.music_note_rounded,
      'video' => Icons.movie_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
    return GestureDetector(
      onTap: () => showComingSoon(
        context,
        icon: playable ? Icons.play_circle_outline_rounded : Icons.download_outlined,
        title: playable ? 'Playback is on the way' : 'Export is on the way',
        message: playable
            ? 'This clip is saved with the capsule on your device. In-app playback arrives in a later update.'
            : 'This file stays with the capsule on your device for now. Saving it out arrives in a later update.',
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: C.lav2, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(leading, size: 18, color: C.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: C.t(13.5, weight: FontWeight.w600, color: C.ink)),
            ),
            Icon(playable ? Icons.play_circle_fill_rounded : Icons.download_outlined,
                size: playable ? 22 : 17, color: C.muted3),
          ],
        ),
      ),
    );
  }
}
