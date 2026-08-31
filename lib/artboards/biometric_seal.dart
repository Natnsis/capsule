import 'package:flutter/material.dart';
import '../app_state.dart';
import '../nav.dart';
import '../services.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'sealed_detail.dart';

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

class BiometricSealScreen extends StatefulWidget {
  const BiometricSealScreen({
    super.key,
    required this.title,
    required this.openOn,
    this.note = '',
    this.bioSealed = false,
    this.draftId,
    this.photoCount = 0,
  });
  final String title;
  final String note;
  final DateTime openOn;
  final bool bioSealed;
  final int? draftId;
  final int photoCount;

  @override
  State<BiometricSealScreen> createState() => _BiometricSealScreenState();
}

class _BiometricSealScreenState extends State<BiometricSealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  bool _sealing = false;

  /// Resolved once: this is a biometric seal AND the device can actually do it.
  /// Drives the whole screen — glyph, copy, whether we prompt for a fingerprint.
  bool _bio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = AppScope.read(context);
      final bio = widget.bioSealed &&
          store.biometricEnabled &&
          await Biometrics.instance.isEnrolled;
      if (mounted && bio != _bio) setState(() => _bio = bio);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _seal() async {
    if (_sealing) return;
    setState(() => _sealing = true);
    final store = AppScope.read(context);

    if (_bio) {
      final ok = await Biometrics.instance
          .authenticate(context, 'Lock this capsule with your fingerprint');
      if (!ok) {
        if (mounted) setState(() => _sealing = false);
        return;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    final sealed = await store.sealCapsule(
      id: widget.draftId,
      title: widget.title,
      note: widget.note,
      openAt: widget.openOn,
      bioSealed: _bio,
      photoCount: widget.photoCount,
    );
    if (mounted) {
      // Reset the stack: dismissing the confirmation lands on the app root,
      // not back inside the compose form.
      goResetTo(
        context,
        SealedDetailScreen(
          capsuleId: sealed.id,
          title: widget.title,
          openOn: widget.openOn,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    const white72 = Color(0xB8FFFFFF);
    final d = widget.openOn;
    final until = '${_monthsShort[d.month - 1]} ${d.day}, ${d.year}';
    final title = widget.title.isEmpty ? 'this capsule' : '“${widget.title}”';
    return Screen(
      // Always a dark, focused "seal" moment — independent of app theme.
      color: const Color(0xFF141019),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: Blob(
              size: 300,
              opacity: .7,
              center: const Alignment(-0.2, -0.3),
              colors: const [Color(0xFFC9A6E0), Color(0xFF6B3E9C), Color(0x00141019)],
              stops: const [0, .55, 1],
            ),
          ),
          Positioned(
            bottom: -80,
            right: -70,
            child: Blob(
              size: 320,
              opacity: .55,
              center: const Alignment(-0.2, -0.3),
              colors: const [Color(0xFFF0C6D2), Color(0xFF8A5FB8), Color(0x00141019)],
              stops: const [0, .5, 1],
            ),
          ),
          Positioned.fill(
            child: AdaptiveBody(
            padding: const EdgeInsets.fromLTRB(30, 28, 30, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => back(context),
                    child: IconChip(
                      size: 44,
                      radius: 22,
                      color: Colors.white.withValues(alpha: .14),
                      child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 42),
                Text('Seal $title\nuntil $until',
                    textAlign: TextAlign.center,
                    style: C.t(32,
                        weight: FontWeight.w800,
                        letterSpacing: -.03,
                        height: 1.12,
                        color: Colors.white)),
                const SizedBox(height: 14),
                SizedBox(
                  width: 300,
                  child: Text(
                    _bio
                        ? "Your fingerprint locks this capsule. From now on, a PIN alone can't open it, edit it, or delete it — not on this phone, not by anyone."
                        : "Once sealed, this capsule can't be opened, edited, or deleted before its open day — on this phone or anywhere.",
                    textAlign: TextAlign.center,
                    style: C.t(15, color: white72, height: 1.6),
                  ),
                ),
                const SizedBox(height: 56),
                GestureDetector(
                  onTap: _seal,
                  child: SizedBox(
                    width: 184,
                    height: 184,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _c,
                          builder: (_, _) {
                            final t = _c.value;
                            final scale = 0.9 + t * 0.35;
                            final opacity = t < 0.7 ? 0.7 * (1 - t / 0.7) : 0.0;
                            return Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity.clamp(0, 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.white.withValues(alpha: .22)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          margin: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: _sealing ? .2 : .08),
                            border: Border.all(color: Colors.white.withValues(alpha: .18)),
                          ),
                        ),
                        if (_bio)
                          const FingerprintGlyph(size: 76, color: Colors.white, stroke: 1.1)
                        else
                          const LockGlyph(size: 64, color: Colors.white, stroke: 1.7),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                    _sealing
                        ? 'Sealing…'
                        : _bio
                            ? 'Touch the sensor to seal'
                            : 'Tap to seal this capsule',
                    style: C.t(16, weight: FontWeight.w700, color: Colors.white)),
                if (_bio) ...[
                  const SizedBox(height: 8),
                  Text('Face ID also works',
                      style: C.t(13.5, color: Colors.white.withValues(alpha: .55))),
                ],
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withValues(alpha: .14)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.error_outline, size: 20, color: Color(0xFFF0C6D2)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "This is permanent. Sealed capsules can't be unsealed, edited, or deleted before their open day.",
                          style: C.t(13, color: Colors.white.withValues(alpha: .8), height: 1.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => back(context),
                  child: Text('Cancel',
                      style:
                          C.t(15, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .6))),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
