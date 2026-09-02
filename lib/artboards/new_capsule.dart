import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import '../nav.dart';
import '../rich_note_controller.dart';
import '../services.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'pick_date.dart';
import 'biometric_seal.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// Keep attachments modest — this is a message capsule, not cloud storage.
const _maxAttachmentBytes = 25 * 1024 * 1024;

const _imageExt = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'bmp'};
const _audioExt = {'mp3', 'wav', 'm4a', 'aac', 'ogg', 'oga', 'flac', 'opus'};
const _videoExt = {'mp4', 'mov', 'webm', 'mkv', 'avi', 'm4v'};

String kindOf(String name, {String? fallback}) {
  final ext = p.extension(name).replaceFirst('.', '').toLowerCase();
  if (_imageExt.contains(ext)) return 'image';
  if (_audioExt.contains(ext)) return 'audio';
  if (_videoExt.contains(ext)) return 'video';
  return fallback ?? 'file';
}

class _Pending {
  _Pending(this.name, this.path, this.kind, {this.id});
  final String name;
  final String path;
  final String kind; // image | audio | video | file
  final int? id; // set when it's already saved to the db
}

/// Compose / edit screen. Pass a [draft] to edit an existing draft; set
/// [jumpToSeal] to head straight to sealing if the draft is already complete.
class NewCapsuleScreen extends StatefulWidget {
  const NewCapsuleScreen({super.key, this.draft, this.jumpToSeal = false});

  final Capsule? draft;
  final bool jumpToSeal;

  @override
  State<NewCapsuleScreen> createState() => _NewCapsuleScreenState();
}

class _NewCapsuleScreenState extends State<NewCapsuleScreen> {
  late final TextEditingController _title =
      TextEditingController(text: widget.draft?.title ?? '');
  late final RichNoteController _note =
      RichNoteController(markup: widget.draft?.note ?? '');
  late DateTime? _openOn = widget.draft?.openAt;
  late int? _draftId = widget.draft?.id;
  bool _bioSeal = false;
  bool _bioAvailable = false;
  final List<_Pending> _attachments = [];

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
    _note.addListener(() => setState(() {}));
    for (final a in widget.draft?.attachments ?? const []) {
      _attachments.add(_Pending(a.name, a.path, a.kind, id: a.id));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = AppScope.read(context);
      final avail = store.biometricEnabled && await Biometrics.instance.isAvailable;
      if (mounted) setState(() => _bioAvailable = avail);
      if (widget.jumpToSeal && _canSeal && mounted) _seal();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _hasContent => _title.text.trim().isNotEmpty || _note.text.trim().isNotEmpty;
  bool get _canSeal =>
      _title.text.trim().isNotEmpty && _note.text.trim().isNotEmpty && _openOn != null;
  int get _words =>
      _note.text.trim().isEmpty ? 0 : _note.text.trim().split(RegExp(r'\s+')).length;
  int get _imageCount => _attachments.where((a) => a.kind == 'image').length;

  // ---- attachments ----------------------------------------------
  Future<void> _addImage() async {
    const group = XTypeGroup(
        label: 'images', extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic']);
    await _pick(const [group], forcedKind: 'image');
  }

  Future<void> _addMedia() async {
    const group = XTypeGroup(label: 'audio & video', extensions: [
      'mp3', 'wav', 'm4a', 'aac', 'ogg', 'oga', 'flac', 'opus',
      'mp4', 'mov', 'webm', 'mkv', 'm4v',
    ]);
    await _pick(const [group]);
  }

  Future<void> _addFile() async => _pick(const []);

  Future<void> _pick(List<XTypeGroup> groups, {String? forcedKind}) async {
    try {
      final picked = await openFile(acceptedTypeGroups: groups);
      if (picked == null) return;
      final size = await File(picked.path).length();
      if (size > _maxAttachmentBytes) {
        _toast('That file is over 25 MB — pick something smaller.');
        return;
      }
      // Files with no extension that came through the media picker are audio.
      final kind = forcedKind ?? kindOf(picked.name, fallback: 'audio');
      setState(() => _attachments.add(_Pending(picked.name, picked.path, kind)));
    } catch (_) {
      _toast('Couldn’t open the picker on this device.');
    }
  }

  /// Copies a picked file into the app's own storage so it survives after the
  /// source is gone, and returns the stable path.
  Future<String> _stash(String srcPath, String name) async {
    try {
      final dir = Directory(p.join(
          (await getApplicationDocumentsDirectory()).path, 'attachments'));
      await dir.create(recursive: true);
      final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final dest = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_$safe');
      await File(srcPath).copy(dest);
      return dest;
    } catch (_) {
      return srcPath;
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickDateSheet(title: _title.text.trim(), note: _note.text.trim()),
    );
    if (picked != null) setState(() => _openOn = picked);
  }

  String get _openLabel {
    final d = _openOn;
    if (d == null) return _hasContent ? 'Pick a day →' : 'Not set yet';
    return '${d.day} ${_months[d.month - 1]} ${d.year} · '
        '${AppScope.read(context).openTimeLabel}';
  }

  /// The chosen open day stamped with the user's preferred open time.
  DateTime get _openAt {
    final t = AppScope.read(context).openTime;
    final base = _openOn ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, t.hour, t.minute);
  }

  /// Persists the current form as a draft (creating one if needed) and syncs
  /// its attachments. Returns the capsule id.
  Future<int> _persistDraft() async {
    final store = AppScope.read(context);
    final c = await store.saveDraft(
      id: _draftId,
      title: _title.text.trim(),
      note: _note.markup,
      openAt: _openAt,
      photoCount: _imageCount,
    );
    _draftId = c.id;
    for (var i = 0; i < _attachments.length; i++) {
      final a = _attachments[i];
      if (a.id != null) continue;
      final stored = await _stash(a.path, a.name);
      await store.addAttachment(c.id, a.name, stored, a.kind);
      _attachments[i] = _Pending(a.name, stored, a.kind, id: -1);
    }
    return c.id;
  }

  Future<void> _saveDraft() async {
    await _persistDraft();
    if (mounted) back(context);
  }

  Future<void> _seal() async {
    if (!_canSeal) return;
    final id = await _persistDraft();
    if (!mounted) return;
    go(
      context,
      BiometricSealScreen(
        title: _title.text.trim(),
        note: _note.markup,
        openOn: _openAt,
        bioSealed: _bioSeal,
        draftId: id,
        photoCount: _imageCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    final filled = _hasContent;
    final editing = widget.draft != null;
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
                    child: Icon(Icons.close, size: 20, color: C.ink),
                  ),
                ),
                Text(editing ? 'Edit draft' : 'New capsule',
                    style: C.t(13.5, weight: FontWeight.w700, color: C.muted2)),
                GestureDetector(
                  onTap: filled ? _saveDraft : null,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: filled ? C.lav1 : C.lav2,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    alignment: Alignment.center,
                    child: Text('Save draft',
                        style: C.t(14,
                            weight: FontWeight.w700, color: filled ? C.slate : C.faint)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text('Title', style: C.t(13, weight: FontWeight.w700, color: C.muted3)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: C.divider, width: 1.5)),
              ),
              child: TextField(
                controller: _title,
                maxLength: 60,
                cursorColor: C.ink,
                cursorWidth: 2,
                style: C.t(30, weight: FontWeight.w800, letterSpacing: -.03, color: C.ink),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'Name your capsule',
                  hintStyle:
                      C.t(30, weight: FontWeight.w800, letterSpacing: -.03, color: C.faint2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    filled
                        ? 'Draft · only on this device'
                        : 'Only you will ever read this',
                    style: C.t(12.5,
                        weight: FontWeight.w600, color: filled ? C.muted3 : C.faint)),
                Text('${_title.text.length} / 60',
                    style: C.t(12.5, weight: FontWeight.w600, color: C.faint)),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your note', style: C.t(13, weight: FontWeight.w700, color: C.muted3)),
                Text('$_words words',
                    style: C.t(12.5, weight: FontWeight.w700, color: C.faint)),
              ],
            ),
            const SizedBox(height: 10),
            _FormatBar(
              controller: _note,
              onBold: () => _note.toggle(RichNoteController.bold),
              onItalic: () => _note.toggle(RichNoteController.italic),
              onUnderline: () => _note.toggle(RichNoteController.underline),
              onBullet: () => _note.insertPlain('\n• '),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(minHeight: 170),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: C.lav3,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: C.lav4, width: 1.5),
              ),
              child: TextField(
                controller: _note,
                maxLines: null,
                cursorColor: C.ink,
                cursorWidth: 2,
                style: C.t(16.5, color: C.ink3, height: 1.7),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintMaxLines: 4,
                  hintText:
                      "Write it the way you'd say it out loud. Select text, then tap B, I or U.",
                  hintStyle: C.t(16.5, color: C.faint, height: 1.7),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attachments',
                    style: C.t(13, weight: FontWeight.w700, color: C.muted3)),
                Text('Shown when it opens',
                    style: C.t(12.5, weight: FontWeight.w700, color: C.faint)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _addTile(Icons.image_outlined, 'Photo', _addImage)),
                const SizedBox(width: 10),
                Expanded(child: _addTile(Icons.graphic_eq_rounded, 'Audio / video', _addMedia)),
                const SizedBox(width: 10),
                Expanded(child: _addTile(Icons.attach_file_rounded, 'File', _addFile)),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _attachments.length; i++)
                    _attachChip(_attachments[i], i),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (_bioAvailable)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: C.lav2, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    Icon(Icons.fingerprint, size: 20, color: C.ink),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seal with biometrics',
                              style: C.t(14.5, weight: FontWeight.w700)),
                          Text('Fingerprint or Face ID required to open',
                              style: C.t(12, weight: FontWeight.w500, color: C.muted)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _bioSeal = !_bioSeal),
                      child: Toggle(on: _bioSeal),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: C.lav2, borderRadius: BorderRadius.circular(32)),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: C.glass,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.calendar_today_outlined, size: 20, color: C.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Opens on',
                              style: C.t(12,
                                  weight: FontWeight.w700,
                                  color: _openOn != null ? C.muted3 : C.faint,
                                  letterSpacing: .1)),
                          Text(_openLabel,
                              style: C.t(17,
                                  weight: FontWeight.w700,
                                  color: _openOn != null || filled ? C.ink : C.faint,
                                  letterSpacing: -.01)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: _openOn != null ? C.ink : C.faint),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _canSeal ? _seal : null,
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: _canSeal ? C.fill : C.lav4,
                  borderRadius: BorderRadius.circular(31),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LockGlyph(size: 19, color: _canSeal ? C.onFill : C.faint, stroke: 1.9),
                    const SizedBox(width: 10),
                    Text('Seal capsule',
                        style: C.t(17,
                            weight: FontWeight.w700, color: _canSeal ? C.onFill : C.faint)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addTile(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: DashedRRect(
          radius: 22,
          child: Container(
            height: 96,
            decoration: BoxDecoration(color: C.lav3, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: C.dashPurple),
                const SizedBox(height: 8),
                Text(label, style: C.t(12, weight: FontWeight.w700, color: C.dashPurple)),
              ],
            ),
          ),
        ),
      );

  static IconData _attachIcon(String kind) => switch (kind) {
        'image' => Icons.image_outlined,
        'audio' => Icons.music_note_rounded,
        'video' => Icons.movie_outlined,
        _ => Icons.insert_drive_file_outlined,
      };

  Widget _attachChip(_Pending a, int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      decoration: BoxDecoration(
        color: C.lav1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.lav4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 34,
              height: 34,
              child: a.kind == 'image' && File(a.path).existsSync()
                  ? Image.file(File(a.path), fit: BoxFit.cover)
                  : ColoredBox(
                      color: C.lav4,
                      child: Icon(_attachIcon(a.kind), size: 16, color: C.muted),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(a.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: C.t(12.5, weight: FontWeight.w600, color: C.ink)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              if (a.id != null && _draftId != null) {
                await AppScope.read(context).removeAttachment(_draftId!, a.id!);
              }
              setState(() => _attachments.removeAt(index));
            },
            child: Icon(Icons.close, size: 15, color: C.muted),
          ),
        ],
      ),
    );
  }
}

class _FormatBar extends StatelessWidget {
  const _FormatBar({
    required this.controller,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onBullet,
  });
  final RichNoteController controller;
  final VoidCallback onBold, onItalic, onUnderline, onBullet;

  @override
  Widget build(BuildContext context) {
    // Rebuild the bar as the selection / active formats change.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        Widget btn(Widget child, VoidCallback onTap, {bool active = false}) =>
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Container(
                width: 40,
                height: 36,
                decoration: BoxDecoration(
                  color: active ? C.fill : C.lav2,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: child,
              ),
            );
        Color fg(bool a) => a ? C.onFill : C.ink;
        final b = controller.isActive(RichNoteController.bold);
        final i = controller.isActive(RichNoteController.italic);
        final u = controller.isActive(RichNoteController.underline);
        return Row(
          children: [
            btn(Text('B', style: C.t(15, weight: FontWeight.w800, color: fg(b))), onBold,
                active: b),
            const SizedBox(width: 8),
            btn(
                Text('I',
                    style: C.t(15,
                        weight: FontWeight.w700, color: fg(i), fontStyle: FontStyle.italic)),
                onItalic,
                active: i),
            const SizedBox(width: 8),
            btn(
                Text('U',
                    style: C.t(15, weight: FontWeight.w700, color: fg(u))
                        .copyWith(decoration: TextDecoration.underline)),
                onUnderline,
                active: u),
            const SizedBox(width: 8),
            btn(Icon(Icons.format_list_bulleted, size: 17, color: C.ink), onBullet),
          ],
        );
      },
    );
  }
}
