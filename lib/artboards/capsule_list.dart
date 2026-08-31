import 'package:flutter/material.dart';
import '../app_state.dart';
import '../capsule_format.dart';
import '../nav.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'sealed_detail.dart';
import 'open_day.dart';

/// Every capsule on the device. A segmented toggle switches the list between
/// the sealed capsules and the ones that have already opened.
class CapsuleListScreen extends StatefulWidget {
  const CapsuleListScreen({super.key});

  @override
  State<CapsuleListScreen> createState() => _CapsuleListScreenState();
}

class _CapsuleListScreenState extends State<CapsuleListScreen> {
  /// 0 = sealed, 1 = opened.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final sealed = store.sealedCapsules;
    final opened = store.openedCapsules;
    final list = _tab == 0 ? sealed : opened;

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
              left: ('Sealed', sealed.length),
              right: ('Opened', opened.length),
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48, left: 8),
                child: Text(
                  _tab == 0 ? 'No sealed capsules yet.' : 'Nothing has opened yet.',
                  style: C.t(14, weight: FontWeight.w600, color: C.muted),
                ),
              )
            else
              for (int i = 0; i < list.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _CapsuleRow(
                  capsule: list[i],
                  onTap: () => go(
                    context,
                    list[i].sealed
                        ? SealedDetailScreen(title: list[i].title, openOn: list[i].openAt)
                        : OpenDayScreen(title: list[i].title),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

/// A sliding pill segmented control.
class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.index,
    required this.left,
    required this.right,
    required this.onChanged,
  });

  final int index;
  final (String, int) left;
  final (String, int) right;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.glass,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: C.glassLine),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
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
          ),
          Row(
            children: [
              Expanded(child: _segment(left.$1, left.$2, index == 0, () => onChanged(0))),
              Expanded(child: _segment(right.$1, right.$2, index == 1, () => onChanged(1))),
            ],
          ),
        ],
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
          style: C.t(14, weight: FontWeight.w700, color: fg),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: label),
              TextSpan(
                text: '  $count',
                style: TextStyle(
                    color: fg.withValues(alpha: .5), fontWeight: FontWeight.w800),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CapsuleRow extends StatelessWidget {
  const _CapsuleRow({required this.capsule, required this.onTap});
  final Capsule capsule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = capsule.sealed ? capsule.openAt : (capsule.openedAt ?? capsule.openAt);
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
              child: LockGlyph(size: 20, color: C.plum, stroke: 1.8, open: !capsule.sealed),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(capsule.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: C.t(16, weight: FontWeight.w700, letterSpacing: -.01)),
                  const SizedBox(height: 2),
                  Text(capsuleSubtitle(capsule),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: C.t(13, weight: FontWeight.w500, color: C.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${target.year}', style: C.t(12, weight: FontWeight.w700, color: C.muted)),
          ],
        ),
      ),
    );
  }
}
