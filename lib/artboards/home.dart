import 'package:flutter/material.dart';
import '../app_state.dart';
import '../capsule_format.dart';
import '../nav.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'sealed_detail.dart';
import 'open_day.dart';
import 'search.dart';
import 'notifications.dart';
import 'new_capsule.dart';

String _fmtDate(DateTime d) => fmtDay(d);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context); // repaint on theme / wipe / capsule change
    final sealed = store.sealedCapsules;
    final opened = store.openedCapsules;
    final featured = store.spotlight;
    final rows = [...sealed, ...opened]
        .where((c) => c.id != featured?.id)
        .take(3)
        .toList();
    return Screen(
      decoration: BoxDecoration(gradient: C.screenGradient),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Avatar(size: 52),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => go(context, const SearchScreen()),
                            child: IconChip(
                              size: 48,
                              radius: 24,
                              color: C.glass,
                              child: Icon(Icons.search, size: 20, color: C.ink),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _HomeMenu(wipePending: store.wipePending),
                        ],
                      ),
                    ],
                  ),
                ),
                if (store.wipePending) _WipeBanner(store: store),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                  child: Text('Hello, Bereket',
                      style: C.t(15, weight: FontWeight.w600, color: C.muted2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width * 2 / 3,
                    child: Text('Future you is listening.',
                        style:
                            C.t(38, weight: FontWeight.w800, letterSpacing: -.035, height: 1.06)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                  child: Row(
                    children: [
                      Pill(
                        background: C.fill,
                        child: Text('Sealed · ${sealed.length}',
                            style: C.t(14, weight: FontWeight.w700, color: C.onFill)),
                      ),
                      const SizedBox(width: 10),
                      Pill(
                        background: C.glass,
                        child: Text('Opened · ${opened.length}',
                            style: C.t(14, weight: FontWeight.w600, color: C.slate)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (featured != null)
                  GestureDetector(
                    onTap: () => go(
                      context,
                      featured.opened
                          ? OpenDayScreen(title: featured.title, capsuleId: featured.id)
                          : SealedDetailScreen(title: featured.title, openOn: featured.openAt),
                    ),
                    child: _featuredCard(featured),
                  )
                else
                  _emptyCard(context),
                for (final c in rows) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => go(
                      context,
                      c.opened
                          ? OpenDayScreen(title: c.title, capsuleId: c.id)
                          : SealedDetailScreen(title: c.title, openOn: c.openAt),
                    ),
                    child: _capsuleRow(c),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [C.bgBottom, C.bgBottom.withValues(alpha: 0)],
                    stops: const [.3, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => go(context, const NewCapsuleScreen()),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: C.glassSoft,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: C.glassLine),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 22, color: C.onFill),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No upcoming capsules',
                      style: C.t(16, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Write something for future you.',
                      style: C.t(13, weight: FontWeight.w500, color: C.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredCard(Capsule c) {
    final daysLeft = c.openAt.difference(DateTime.now()).inDays;
    final opensBadge = c.opened
        ? 'Opened ${fmtDay(c.openedAt ?? c.openAt)}'
        : c.due
            ? 'Ready to open'
            : daysLeft <= 0
                ? 'Opens today'
                : daysLeft == 1
                    ? 'Opens tomorrow'
                    : daysLeft < 45
                        ? 'Opens in $daysLeft days'
                        : 'Opens ${fmtDay(c.openAt)}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [C.card1, C.card2],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -60,
              child: Blob(
                size: 220,
                opacity: C.isDark ? .5 : .95,
                center: const Alignment(-0.3, -0.4),
                colors: const [Color(0xFFF6DCE2), Color(0xFFC79BD9), Color(0xFF6B3E9C)],
                stops: const [0, .45, 1],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: C.glassSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LockGlyph(size: 13, color: C.plum, stroke: 2),
                                  const SizedBox(width: 6),
                                  Text(opensBadge,
                                      style: C.t(12, weight: FontWeight.w700, color: C.plum)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(c.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: C.t(24, weight: FontWeight.w800, letterSpacing: -.02, color: C.ink2)),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 190,
                              child: Text(
                                  'Sealed ${fmtDay(c.createdAt)} · ${c.photoCount} photo${c.photoCount == 1 ? '' : 's'}',
                                  style: C.t(13.5, color: C.plum, height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                      IconChip(
                        size: 44,
                        radius: 22,
                        color: C.glass,
                        child: Icon(Icons.north_east, size: 18, color: C.ink2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: C.glassSoft,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('OPENS',
                                  style: C.t(11, weight: FontWeight.w700, color: C.violetInk, letterSpacing: .1)),
                              Text('${_mon3(c.openAt.month)} ${c.openAt.day}',
                                  style: C.t(26, weight: FontWeight.w800, letterSpacing: -.02, color: C.ink2, height: 1.1)),
                              Text('${c.openAt.year} · 08:00',
                                  style: C.t(12, weight: FontWeight.w600, color: C.violetInk)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 96,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: C.glassSoft,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('WORDS',
                                style: C.t(11, weight: FontWeight.w700, color: C.violetInk, letterSpacing: .1)),
                            Text('${c.wordCount}', style: C.t(26, weight: FontWeight.w800, color: C.ink2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _mon3(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  Widget _capsuleRow(Capsule c) {
    final target = c.sealed ? c.openAt : (c.openedAt ?? c.openAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: C.glass, borderRadius: BorderRadius.circular(28)),
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
                colors: capsuleGradient(c.id),
              ),
            ),
            alignment: Alignment.center,
            child: LockGlyph(size: 20, color: C.plum, stroke: 1.8, open: !c.sealed),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: C.t(16, weight: FontWeight.w700, letterSpacing: -.01)),
                const SizedBox(height: 2),
                Text(capsuleSubtitle(c),
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
    );
  }
}

/// The "⋯" chip on the home header — a small dropdown for account-wide actions.
class _HomeMenu extends StatelessWidget {
  const _HomeMenu({required this.wipePending});
  final bool wipePending;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      color: C.isDark ? C.lav1 : Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (v) {
        if (v == 'notifications') go(context, const NotificationsScreen());
        if (v == 'wipe') _confirmWipe(context);
        if (v == 'cancel') AppScope.read(context).cancelWipe();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'notifications',
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, size: 19, color: C.ink),
              const SizedBox(width: 12),
              Text('Notifications',
                  style: C.t(14, weight: FontWeight.w600, color: C.ink)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (!wipePending)
          PopupMenuItem(
            value: 'wipe',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 19, color: Color(0xFFE5484D)),
                const SizedBox(width: 12),
                Text('Remove all capsules',
                    style: C.t(14, weight: FontWeight.w600, color: const Color(0xFFE5484D))),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.undo_rounded, size: 19, color: C.ink),
                const SizedBox(width: 12),
                Text('Cancel scheduled deletion',
                    style: C.t(14, weight: FontWeight.w600, color: C.ink)),
              ],
            ),
          ),
      ],
      child: IconChip(
        size: 48,
        radius: 24,
        color: C.glass,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmWipe(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.isDark ? C.lav1 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Remove all capsules?',
            style: C.t(19, weight: FontWeight.w800, color: C.ink, letterSpacing: -.02)),
        content: Text(
          'Every capsule on this device is scheduled for permanent deletion in 7 days. '
          'Nothing is removed until then — you can cancel any time from the ⋯ menu.',
          style: C.t(14, color: C.bodyInk, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep them', style: C.t(14, weight: FontWeight.w700, color: C.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AppScope.read(context).armWipe();
            },
            child: Text('Delete in 7 days',
                style: C.t(14, weight: FontWeight.w800, color: const Color(0xFFE5484D))),
          ),
        ],
      ),
    );
  }
}

/// Shown on the home screen while a wipe is scheduled.
class _WipeBanner extends StatelessWidget {
  const _WipeBanner({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFE5484D);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: C.isDark ? .16 : .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: danger.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Capsules delete in ${store.wipeDaysLeft} days',
                    style: C.t(13.5, weight: FontWeight.w800, color: C.ink)),
                const SizedBox(height: 1),
                Text('On ${_fmtDate(store.wipeDeletesAt!)} · tap to stop',
                    style: C.t(12, weight: FontWeight.w600, color: C.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: store.cancelWipe,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(16)),
              child: Text('Cancel',
                  style: C.t(12.5, weight: FontWeight.w800, color: C.onFill)),
            ),
          ),
        ],
      ),
    );
  }
}
