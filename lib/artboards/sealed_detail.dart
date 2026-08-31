import 'package:flutter/material.dart';
import '../nav.dart';
import '../app_state.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'open_day.dart';

const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

String _fmtDate(DateTime d) => '${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

class SealedDetailScreen extends StatelessWidget {
  const SealedDetailScreen({
    super.key,
    this.capsuleId,
    this.title = 'To me, at 25',
    this.openOn,
  });

  final int? capsuleId;
  final String title;
  final DateTime? openOn;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context); // repaint on theme / capsule change
    final capsule = capsuleId == null ? null : store.byId(capsuleId!);

    final name = capsule?.title ?? title;
    final open = capsule?.openAt ?? openOn ?? DateTime(2026, 9, 15);
    final bio = capsule?.bioSealed ?? false;
    final due = capsule?.due ?? false;

    final left = open.difference(DateTime.now());
    final days = left.inDays.clamp(0, 99999);
    final hours = (left.inHours % 24).clamp(0, 23);
    final mins = (left.inMinutes % 60).clamp(0, 59);
    final openStr = '${_fmtDate(open)} · 08:00';

    return Screen(
      decoration: BoxDecoration(gradient: C.screenGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 22),

            // Hero — contained so the blob can't spill past the card.
            ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [C.card1, C.card3],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -60,
                      child: Blob(
                        size: 220,
                        opacity: C.isDark ? .5 : .9,
                        center: const Alignment(-0.3, -0.4),
                        colors: const [Color(0xFFF6DCE2), Color(0xFFC79BD9), Color(0xFF5F3591)],
                        stops: const [0, .45, 1],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: C.glassSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LockGlyph(size: 13, color: C.plum, stroke: 2.1),
                              const SizedBox(width: 7),
                              Text(bio ? 'Sealed · biometric' : 'Sealed',
                                  style: C.t(12.5, weight: FontWeight.w700, color: C.plum)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Capsule',
                            style: C.t(13, weight: FontWeight.w700, color: C.plum)),
                        const SizedBox(height: 4),
                        Text(name,
                            style: C.t(34,
                                weight: FontWeight.w800,
                                letterSpacing: -.03,
                                height: 1.05,
                                color: C.ink2)),
                        const SizedBox(height: 14),
                        Text(due ? 'Its open day has arrived' : 'Opens $openStr',
                            style: C.t(13.5, weight: FontWeight.w600, color: C.plum)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Countdown — only tappable once the capsule is actually due.
            _CountdownCard(
              days: days,
              hours: hours,
              mins: mins,
              openStr: openStr,
              due: due,
              onOpen: due
                  ? () => go(context, OpenDayScreen(title: name, capsuleId: capsule?.id))
                  : null,
            ),

            if (capsule != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: C.glass,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    _detailRow('Sealed on', _fmtDate(capsule.createdAt)),
                    const SizedBox(height: 14),
                    _detailRow('Contents',
                        '${capsule.wordCount} words · ${capsule.photoCount} photo${capsule.photoCount == 1 ? '' : 's'}'),
                    const SizedBox(height: 14),
                    _detailRow('Stored', 'On this device, offline'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            DashedRRect(
              radius: 28,
              color: C.dashed,
              strokeWidth: 1,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: C.glassSoft,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    IconChip(
                      size: 44,
                      radius: 22,
                      color: C.glass,
                      child: Icon(Icons.cloud_off_outlined, size: 20, color: C.muted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bio ? 'Locked from you too' : 'Sealed until the open day',
                              style: C.t(14.5, weight: FontWeight.w700, color: C.plum2)),
                          const SizedBox(height: 2),
                          Text('No preview, no export, no delete until it opens.',
                              style: C.t(13, color: C.muted, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: C.t(14, weight: FontWeight.w600, color: C.muted)),
          Text(v, style: C.t(14, weight: FontWeight.w700)),
        ],
      );
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.days,
    required this.hours,
    required this.mins,
    required this.openStr,
    required this.due,
    this.onOpen,
  });

  final int days, hours, mins;
  final String openStr;
  final bool due;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: C.glass,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(due ? 'READY TO OPEN' : 'OPENS IN',
              style: C.t(12, weight: FontWeight.w700, color: C.muted3, letterSpacing: .14)),
          const SizedBox(height: 12),
          Row(
            children: [
              _tile('$days', 'days'),
              const SizedBox(width: 10),
              _tile(hours.toString().padLeft(2, '0'), 'hours'),
              const SizedBox(width: 10),
              _tile(mins.toString().padLeft(2, '0'), 'mins'),
            ],
          ),
          const SizedBox(height: 14),
          Text(due ? 'Tap to open it now' : openStr,
              style: C.t(13, weight: FontWeight.w600, color: C.muted)),
        ],
      ),
    );
    if (onOpen == null) return card;
    return GestureDetector(onTap: onOpen, child: card);
  }

  Widget _tile(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: C.lav2, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Text(value,
                  style: C.t(30, weight: FontWeight.w800, letterSpacing: -.03, height: 1.1)),
              Text(label, style: C.t(11.5, weight: FontWeight.w700, color: C.muted3)),
            ],
          ),
        ),
      );
}
