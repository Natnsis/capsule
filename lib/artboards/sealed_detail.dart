import 'package:flutter/material.dart';
import '../nav.dart';
import '../app_state.dart';
import '../services.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'open_day.dart';

const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

String _fmtDate(DateTime d) => '${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

class SealedDetailScreen extends StatefulWidget {
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
  State<SealedDetailScreen> createState() => _SealedDetailScreenState();
}

class _SealedDetailScreenState extends State<SealedDetailScreen> {
  /// Marks the capsule opened (behind a biometric check when it was sealed with
  /// one) and moves on to the letter. Replaces this screen so a back-swipe
  /// doesn't return to a stale "sealed" view.
  Future<void> _open(AppStore store, Capsule c) async {
    if (c.bioSealed &&
        store.biometricEnabled &&
        await Biometrics.instance.isAvailable) {
      if (!mounted) return;
      final ok = await Biometrics.instance
          .authenticate(context, 'Unlock “${c.title}” with your fingerprint');
      if (!ok || !mounted) return;
    }
    final opened = await store.openCapsule(c);
    if (mounted) {
      goReplace(context, OpenDayScreen(title: opened.title, capsuleId: opened.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context); // repaint on theme / capsule change
    final capsule = widget.capsuleId == null ? null : store.byId(widget.capsuleId!);

    final name = capsule?.title ?? widget.title;
    final open = capsule != null
        ? store.openMomentOf(capsule)
        : (widget.openOn ?? DateTime(2026, 9, 15));
    final bio = capsule?.bioSealed ?? false;
    final due = capsule != null ? store.isDue(capsule) : false;

    final left = open.difference(DateTime.now());
    final days = left.inDays.clamp(0, 99999);
    final hours = (left.inHours % 24).clamp(0, 23);
    final mins = (left.inMinutes % 60).clamp(0, 59);
    final openStr = '${_fmtDate(open)} · ${store.openTimeLabel}';

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
              onOpen: due ? () => _open(store, capsule) : null,
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

class _CountdownCard extends StatefulWidget {
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
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard>
    with SingleTickerProviderStateMixin {
  // A slow in-and-out breath. Only runs while the card is the thing to tap.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _live => widget.due && widget.onOpen != null;

  @override
  void initState() {
    super.initState();
    if (_live) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_CountdownCard old) {
    super.didUpdateWidget(old);
    if (_live && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_live && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final due = widget.due;
    // Once it's due the countdown is all zeros — swap it for the open prompt.
    final content = due
        ? Column(
            children: [
              Text('READY TO OPEN',
                  style: C.t(12,
                      weight: FontWeight.w700, color: C.muted3, letterSpacing: .14)),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: C.fill, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(Icons.lock_open_rounded, size: 24, color: C.onFill),
              ),
              const SizedBox(height: 14),
              Text('Tap to open it now',
                  style: C.t(14, weight: FontWeight.w700, color: C.ink)),
            ],
          )
        : Column(
            children: [
              Text('OPENS IN',
                  style: C.t(12,
                      weight: FontWeight.w700, color: C.muted3, letterSpacing: .14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _tile('${widget.days}', 'days'),
                  const SizedBox(width: 10),
                  _tile(widget.hours.toString().padLeft(2, '0'), 'hours'),
                  const SizedBox(width: 10),
                  _tile(widget.mins.toString().padLeft(2, '0'), 'mins'),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.openStr,
                  style: C.t(13, weight: FontWeight.w600, color: C.muted)),
            ],
          );

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _live ? Curves.easeInOut.transform(_pulse.value) : 0.0;
        final card = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: C.glass,
            borderRadius: BorderRadius.circular(32),
            // Width is reserved in both states so the card never shifts.
            border: Border.all(color: C.fill.withValues(alpha: .4 * t), width: 1.5),
            boxShadow: t == 0
                ? null
                : [
                    BoxShadow(
                      color: C.fill.withValues(alpha: .10 + .16 * t),
                      blurRadius: 16 + 16 * t,
                      spreadRadius: 1 + 3 * t,
                    ),
                  ],
          ),
          child: child,
        );
        return _live ? GestureDetector(onTap: widget.onOpen, child: card) : card;
      },
      child: content,
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
}
