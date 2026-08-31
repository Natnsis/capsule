import 'package:flutter/material.dart';
import '../app_state.dart';
import '../capsule_format.dart';
import '../nav.dart';
import '../services.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'sealed_detail.dart';
import 'open_day.dart';
import 'new_capsule.dart';

const _danger = Color(0xFFE5484D);

/// Every capsule on the device, split by Sealed / Opened / Drafts.
class CapsuleListScreen extends StatefulWidget {
  const CapsuleListScreen({super.key});

  @override
  State<CapsuleListScreen> createState() => _CapsuleListScreenState();
}

class _CapsuleListScreenState extends State<CapsuleListScreen> {
  int _tab = 0; // 0 sealed, 1 opened, 2 drafts

  Future<bool> _needsBio(AppStore store, Capsule c) async =>
      c.bioSealed && store.biometricEnabled && await Biometrics.instance.isAvailable;

  Future<void> _confirmDelete(AppStore store, Capsule c) async {
    final needsBio = await _needsBio(store, c);
    if (!mounted) return;
    if (needsBio) {
      final ok = await Biometrics.instance
          .authenticate(context, 'Verify to delete “${c.title}”');
      if (!ok || !mounted) return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.isDark ? C.lav1 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete “${c.title}”?',
            style: C.t(18, weight: FontWeight.w800, color: C.ink)),
        content: Text(
          c.sealed
              ? 'This sealed capsule and its contents are gone for good.'
              : 'This capsule will be permanently removed.',
          style: C.t(14, color: C.bodyInk, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep', style: C.t(14, weight: FontWeight.w700, color: C.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: C.t(14, weight: FontWeight.w800, color: _danger)),
          ),
        ],
      ),
    );
    if (yes == true) await store.deleteCapsule(c.id);
  }

  Future<void> _open(AppStore store, Capsule c) async {
    final needsBio = await _needsBio(store, c);
    if (!mounted) return;
    if (needsBio) {
      final ok = await Biometrics.instance
          .authenticate(context, 'Unlock “${c.title}” with your fingerprint');
      if (!ok || !mounted) return;
    }
    final opened = await store.openCapsule(c);
    if (mounted) go(context, OpenDayScreen(title: opened.title, capsuleId: opened.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final sealed = store.sealedCapsules;
    final opened = store.openedCapsules;
    final drafts = store.draftCapsules;
    final list = [sealed, opened, drafts][_tab];

    return Screen(
      decoration: BoxDecoration(gradient: C.screenGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: width * 2 / 3,
                child: Text('Everything on this device',
                    style: C.t(32, weight: FontWeight.w800, letterSpacing: -.035, height: 1.08)),
              ),
            ),
            const SizedBox(height: 22),
            _SegmentedToggle(
              index: _tab,
              segments: [
                ('Sealed', sealed.length),
                ('Opened', opened.length),
                ('Drafts', drafts.length),
              ],
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48, left: 8),
                child: Text(
                  const ['No sealed capsules yet.', 'Nothing has opened yet.', 'No drafts.'][_tab],
                  style: C.t(14, weight: FontWeight.w600, color: C.muted),
                ),
              )
            else
              for (int i = 0; i < list.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _CapsuleRow(
                  capsule: list[i],
                  onTap: () => _rowTap(store, list[i]),
                  trailing: _trailing(store, list[i]),
                ),
              ],
          ],
        ),
      ),
    );
  }

  void _rowTap(AppStore store, Capsule c) {
    if (c.isDraft) {
      go(context, NewCapsuleScreen(draft: c));
    } else if (c.opened) {
      go(context, OpenDayScreen(title: c.title, capsuleId: c.id));
    } else {
      go(context, SealedDetailScreen(title: c.title, openOn: c.openAt));
    }
  }

  Widget _trailing(AppStore store, Capsule c) {
    if (c.isDraft) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillButton('Edit', filled: false,
              onTap: () => go(context, NewCapsuleScreen(draft: c))),
          const SizedBox(width: 6),
          _pillButton('Activate', filled: true,
              onTap: () => go(context, NewCapsuleScreen(draft: c, jumpToSeal: true))),
        ],
      );
    }
    if (c.due) {
      return _iconButton(Icons.lock_open_rounded, onTap: () => _open(store, c), accent: true);
    }
    return _iconButton(Icons.delete_outline, onTap: () => _confirmDelete(store, c));
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap, bool accent = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: accent ? C.fill : C.glass,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: accent ? C.onFill : C.muted),
      ),
    );
  }

  Widget _pillButton(String label, {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? C.fill : C.glass,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: C.t(12, weight: FontWeight.w800, color: filled ? C.onFill : C.ink)),
      ),
    );
  }
}

/// A sliding pill segmented control (2 or 3 segments).
class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({required this.index, required this.segments, required this.onChanged});

  final int index;
  final List<(String, int)> segments;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = segments.length;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.glass,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: C.glassLine),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final segW = box.maxWidth / n;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: segW * index,
                top: 0,
                bottom: 0,
                width: segW,
                child: Container(
                  decoration: BoxDecoration(
                    color: C.fill,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF321E50).withValues(alpha: .18),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < n; i++)
                    SizedBox(
                      width: segW,
                      height: double.infinity,
                      child: _segment(segments[i].$1, segments[i].$2, i == index,
                          () => onChanged(i)),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(String label, int count, bool active, VoidCallback onTap) {
    final fg = active ? C.onFill : C.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: C.t(13.5, weight: FontWeight.w700, color: fg),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: label),
              TextSpan(
                text: ' $count',
                style: TextStyle(color: fg.withValues(alpha: .5), fontWeight: FontWeight.w800),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CapsuleRow extends StatelessWidget {
  const _CapsuleRow({required this.capsule, required this.onTap, required this.trailing});
  final Capsule capsule;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final target = capsule.opened ? (capsule.openedAt ?? capsule.openAt) : capsule.openAt;
    final sub = capsule.isDraft
        ? 'Draft · last edited ${fmtDay(capsule.createdAt)}'
        : capsuleSubtitle(capsule);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: C.glassSoft, borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: capsuleGradient(capsule.id),
                ),
              ),
              alignment: Alignment.center,
              child: capsule.isDraft
                  ? Icon(Icons.edit_note_rounded, size: 22, color: C.plum)
                  : LockGlyph(size: 20, color: C.plum, stroke: 1.8, open: capsule.opened),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(capsule.title.isEmpty ? 'Untitled' : capsule.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: C.t(16, weight: FontWeight.w700, letterSpacing: -.01)),
                      ),
                      if (capsule.bioSealed) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.fingerprint, size: 14, color: C.muted3),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: C.t(13, weight: FontWeight.w500, color: C.muted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (capsule.isDraft)
              trailing
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${target.year}', style: C.t(12, weight: FontWeight.w700, color: C.muted)),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
          ],
        ),
      ),
    );
  }
}
