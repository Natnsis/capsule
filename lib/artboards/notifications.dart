import 'package:flutter/material.dart';
import '../app_state.dart';
import '../capsule_format.dart';
import '../nav.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'open_day.dart';
import 'sealed_detail.dart';

/// In-app Notifications feed — every reminder Capsule has generated, whether or
/// not the OS was allowed to surface it outside the app.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).markNotificationsRead();
    });
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return fmtDay(t);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final feed = store.notificationsFeed;

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
            if (!store.notificationsEnabled)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: C.glassSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: C.glassLine),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 18, color: C.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Notifications are off — reminders only show here.',
                          style: C.t(12.5, weight: FontWeight.w600, color: C.muted)),
                    ),
                  ],
                ),
              ),
            if (feed.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Text('Nothing yet. Capsule will let you know when one opens.',
                      textAlign: TextAlign.center,
                      style: C.t(14, weight: FontWeight.w600, color: C.muted)),
                ),
              )
            else
              for (int i = 0; i < feed.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _NotifCard(
                  time: _ago(feed[i].createdAt),
                  title: feed[i].title,
                  body: feed[i].body,
                  unread: !feed[i].read,
                  onTap: () {
                    final id = feed[i].capsuleId;
                    if (id == null) return;
                    final c = store.byId(id);
                    if (c == null) return;
                    go(
                      context,
                      c.opened
                          ? OpenDayScreen(title: c.title, capsuleId: c.id)
                          : SealedDetailScreen(capsuleId: c.id, title: c.title, openOn: c.openAt),
                    );
                  },
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.time,
    required this.title,
    required this.body,
    required this.onTap,
    this.unread = false,
  });

  final String time;
  final String title;
  final String body;
  final VoidCallback onTap;
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
              decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: LockGlyph(size: 19, color: C.onFill, stroke: 1.8),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
