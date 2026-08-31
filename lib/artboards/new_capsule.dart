import 'package:flutter/material.dart';
import '../nav.dart';
import '../app_state.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'pick_date.dart';
import 'biometric_seal.dart';

/// Compose screen. Starts in the empty state (04a); as soon as the writer adds
/// a title or note it becomes the filled state (04b). "Opens on" opens the date
/// picker sheet; "Seal capsule" is enabled once there's content and a date.
class NewCapsuleScreen extends StatefulWidget {
  const NewCapsuleScreen({super.key});

  @override
  State<NewCapsuleScreen> createState() => _NewCapsuleScreenState();
}

class _NewCapsuleScreenState extends State<NewCapsuleScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  DateTime? _openOn;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _hasContent => _title.text.trim().isNotEmpty || _note.text.trim().isNotEmpty;
  bool get _canSeal => _title.text.trim().isNotEmpty && _note.text.trim().isNotEmpty && _openOn != null;
  int get _words =>
      _note.text.trim().isEmpty ? 0 : _note.text.trim().split(RegExp(r'\s+')).length;

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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year} · 08:00';
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    final filled = _hasContent;
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
                  Text('New capsule',
                      style: C.t(13.5, weight: FontWeight.w700, color: C.muted2)),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: filled ? C.lav1 : C.lav2,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    alignment: Alignment.center,
                    child: Text('Save draft',
                        style: C.t(14, weight: FontWeight.w700, color: filled ? C.slate : C.faint)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text('Title',
                  style: C.t(13, weight: FontWeight.w700, color: C.muted3)),
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
                  Text(filled ? 'Draft · saved just now · only on this device' : 'Only you will ever read this',
                      style: C.t(12.5, weight: FontWeight.w600, color: filled ? C.muted3 : C.faint)),
                  Text('${_title.text.length} / 60',
                      style: C.t(12.5, weight: FontWeight.w600, color: C.faint)),
                ],
              ),
              const SizedBox(height: 26),
              Text('Your note',
                  style: C.t(13, weight: FontWeight.w700, color: C.muted3)),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(minHeight: 186),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 54),
                decoration: BoxDecoration(
                  color: C.lav3,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: C.lav4, width: 1.5),
                ),
                child: Stack(
                  children: [
                    TextField(
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
                            "Write it the way you'd say it out loud. Where you are, what you're afraid of, what you hope has changed by then…",
                        hintStyle: C.t(16.5, color: C.faint, height: 1.7),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _fmt(Text('B', style: C.t(15, weight: FontWeight.w800, color: C.muted))),
                              const SizedBox(width: 8),
                              _fmt(Text('I',
                                  style: C.t(15,
                                      weight: FontWeight.w700,
                                      color: C.muted,
                                      fontStyle: FontStyle.italic))),
                              const SizedBox(width: 8),
                              _fmt(Icon(Icons.notes, size: 17, color: C.muted)),
                            ],
                          ),
                          Text('$_words words',
                              style: C.t(12.5, weight: FontWeight.w700, color: C.faint)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Photos',
                      style: C.t(13, weight: FontWeight.w700, color: C.muted3)),
                  Text('Optional · up to 5',
                      style: C.t(12.5, weight: FontWeight.w700, color: C.faint)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _photoSlot(Icons.image_outlined, 'Gallery')),
                  const SizedBox(width: 12),
                  Expanded(child: _photoSlot(Icons.photo_camera_outlined, 'Camera')),
                  const SizedBox(width: 12),
                  Expanded(child: _photoSlot(Icons.upload_outlined, 'Files')),
                ],
              ),
              const SizedBox(height: 28),
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
                onTap: _canSeal
                    ? () => go(
                        context,
                        BiometricSealScreen(
                          title: _title.text.trim(),
                          note: _note.text.trim(),
                          openOn: _openOn!,
                        ))
                    : null,
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

  Widget _fmt(Widget child) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: C.glass, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: child,
      );

  Widget _photoSlot(IconData icon, String label) => DashedRRect(
        radius: 22,
        child: Container(
          height: 120,
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
      );
}
