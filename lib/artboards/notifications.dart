import 'package:flutter/material.dart';
import '../nav.dart';
import '../app_state.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'open_day.dart';

/// In-app Notifications screen: the list of reminders Capsule has sent, plus
/// the per-capsule reminder schedule. (Not an OS lock screen — just how a
/// Capsule notification looks and where they live in the app.)
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    return Screen(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.bgTop, C.bgBottom],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => back(context),
                  child: IconChip(
                    size: 46,
                    radius: 23,
                    color: C.glass,
                    child: Icon(Icons.arrow_back, size: 20, color: C.ink),
                  ),
                ),
                const SizedBox(width: 14),
                Text('NOTIFICATIONS',
                    style: C.t(15, weight: FontWeight.w700, color: C.muted2, letterSpacing: .14)),
              ],
            ),
            const SizedBox(height: 26),
            Text('Recent', style: C.t(13, weight: FontWeight.w800, color: C.faint, letterSpacing: .14)),
            const SizedBox(height: 12),
            _NotifCard(
              time: 'now',
              title: '3 days until “To me, at 25” opens',
              body: 'Sealed 12 Sep 2024. Get ready — it opens Monday at 08:00.',
              unread: true,
              onTap: () => back(context),
            ),
            const SizedBox(height: 10),
            _NotifCard(
              time: 'Yesterday',
              gradient: const [Color(0xFFE7C9D4), Color(0xFFB49BD6)],
              title: 'Your capsule is open',
              body: '“To me, at 25” is ready to read. Tap to unlock with your PIN.',
              onTap: () => go(context, const OpenDayScreen()),
            ),
            const SizedBox(height: 10),
            _NotifCard(
              time: '4 Jun',
              gradient: const [Color(0xFFD7E7E0), Color(0xFFBFCFEA)],
              title: 'Wedding day letter sealed',
              body: 'Locked with your fingerprint until 04 Jun 2031.',
              onTap: () {},
            ),
            const SizedBox(height: 26),
            Text('REMINDER SCHEDULE',
                style: C.t(13, weight: FontWeight.w800, color: C.faint, letterSpacing: .14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: C.glass,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  _schedRow('3 days before', 'Heads-up'),
                  _schedDivider(),
                  _schedRow('Open day, 08:00', 'Open now'),
                  _schedDivider(),
                  _schedRow('If unread', 'Nudge after 24 h'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: C.muted3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Capsule sends at most three reminders per capsule.',
                      style: C.t(12.5, weight: FontWeight.w500, color: C.muted3)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _schedDivider() =>
      Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 14), color: C.lav5);

  Widget _schedRow(String a, String b) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: C.t(14.5, weight: FontWeight.w700, color: C.ink)),
          Text(b, style: C.t(13.5, weight: FontWeight.w600, color: C.muted)),
        ],
      );
}

/// A single Capsule notification — the visual spec for a push/in-app alert.
class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.time,
    required this.title,
    required this.body,
    required this.onTap,
    this.gradient,
    this.unread = false,
  });

  final String time;
  final String title;
  final String body;
  final VoidCallback onTap;
  final List<Color>? gradient;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: unread ? C.glass : C.glassSoft,
          borderRadius: BorderRadius.circular(26),
          border: unread ? Border.all(color: C.ink.withValues(alpha: .08), width: 1) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: gradient == null ? C.fill : null,
                gradient: gradient == null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient!),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: LockGlyph(
                size: 19,
                color: gradient == null ? C.onFill : const Color(0xFF3B2E5C),
                stroke: 1.8,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Row(
                        children: [
                          Text('CAPSULE',
                              style: C.t(12.5,
                                  weight: FontWeight.w800, color: C.muted, letterSpacing: .06)),
                          if (unread) ...[
                            const SizedBox(width: 7),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: C.ink, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                      Text(time, style: C.t(12, weight: FontWeight.w600, color: C.muted3)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(title, style: C.t(15.5, weight: FontWeight.w700, height: 1.25)),
                  const SizedBox(height: 3),
                  Text(body, style: C.t(13.5, color: C.bodyInk, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
