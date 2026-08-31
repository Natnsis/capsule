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

class SealedDetailScreen extends StatelessWidget {
  const SealedDetailScreen({super.key, this.title = 'To me, at 25', this.openOn});

  final String title;
  final DateTime? openOn;

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    final open = openOn ?? DateTime(2026, 9, 15);
    final left = open.difference(DateTime.now());
    final days = left.inDays.clamp(0, 99999);
    final hours = (left.inHours % 24).clamp(0, 23);
    final mins = (left.inMinutes % 60).clamp(0, 59);
    final openStr = '${open.day} ${_monthsLong[open.month - 1]} ${open.year} · 08:00';
    return Screen(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.bgTop, C.bgBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [C.card1, C.card3],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -70,
                    top: -40,
                    child: Blob(
                      size: 300,
                      center: const Alignment(-0.3, -0.4),
                      colors: const [Color(0xFFF6DCE2), Color(0xFFC79BD9), Color(0xFF5F3591)],
                      stops: const [0, .45, 1],
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -70,
                    child: Blob(
                      size: 190,
                      opacity: .85,
                      center: const Alignment(-0.2, -0.3),
                      colors: const [Colors.white, Color(0xFFCFC0E9), Color(0xFF7E5FB4)],
                      stops: const [0, .45, 1],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
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
                        color: C.glass,
                        child: Icon(Icons.arrow_back, size: 20, color: C.ink),
                      ),
                    ),
                    Row(
                      children: [
                        IconChip(
                          size: 46,
                          radius: 23,
                          color: C.glass,
                          child: Icon(Icons.calendar_today_outlined, size: 19, color: C.ink),
                        ),
                        const SizedBox(width: 10),
                        IconChip(
                          size: 46,
                          radius: 23,
                          color: C.glass,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              3,
                              (i) => Container(
                                margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                                width: 4,
                                height: 4,
                                decoration:
                                    BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LockGlyph(size: 13, color: C.onFill, stroke: 2.1),
                      const SizedBox(width: 7),
                      Text('Sealed · biometric',
                          style: C.t(12.5, weight: FontWeight.w700, color: C.onFill)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Capsule', style: C.t(15, weight: FontWeight.w700, color: C.bodyInk2)),
                const SizedBox(height: 4),
                Text(title,
                    style: C.t(42, weight: FontWeight.w800, letterSpacing: -.035, height: 1.02)),
                const SizedBox(height: 26),
                GestureDetector(
                  onTap: () => go(context, OpenDayScreen(title: title)),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: C.glass,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        Text('OPENS IN',
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
                        Text(openStr, style: C.t(13, weight: FontWeight.w600, color: C.muted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: C.glass,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Sealed on', '12 Sep 2024'),
                      const SizedBox(height: 14),
                      _detailRow('Contents', '642 words · 2 photos'),
                      const SizedBox(height: 14),
                      _detailRow('Stored', 'On this device, offline'),
                    ],
                  ),
                ),
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
                              Text('Locked from you too',
                                  style: C.t(14.5, weight: FontWeight.w700, color: C.plum2)),
                              const SizedBox(height: 2),
                              Text('No preview, no export, no delete until the open day.',
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
        ],
      ),
    );
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

  Widget _detailRow(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: C.t(14, weight: FontWeight.w600, color: C.muted)),
          Text(v, style: C.t(14, weight: FontWeight.w700)),
        ],
      );
}
