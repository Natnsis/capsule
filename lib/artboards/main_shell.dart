import 'dart:io';

import 'package:flutter/material.dart';
import '../nav.dart';
import '../app_state.dart';
import '../services.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'profile.dart';
import 'capsule_list.dart';
import 'new_capsule.dart';

/// The signed-in app container: swaps the primary tabs and owns the floating
/// bottom navigation bar plus the detached compose button beside it.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  /// The setup nudge is checked once per app run, no matter how many times the
  /// shell is rebuilt into the root (sealing a capsule does that).
  static bool _nudgeCheckedThisRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNudgeSetup());
  }

  /// A light "finish setting up Capsule" sheet listing only the switches that
  /// are still off — biometric unlock, notifications, exact open-day alerts.
  /// Tapping through drops the user on the Profile tab where every toggle lives.
  Future<void> _maybeNudgeSetup() async {
    if (_nudgeCheckedThisRun || !mounted) return;
    _nudgeCheckedThisRun = true;
    // Only phones have these OS gates to grant.
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final store = AppScope.read(context);
    final snoozed = store.permNudgeSnoozedAt;
    if (snoozed != null &&
        DateTime.now().difference(snoozed) < const Duration(days: 4)) {
      return; // asked recently — stay quiet
    }

    final bioAvailable = await Biometrics.instance.isAvailable;
    final bioOn = store.biometricEnabled && await Biometrics.instance.isEnrolled;
    final notifOn =
        store.notificationsEnabled && await Notifier.instance.isGranted;
    final exactOn =
        !Platform.isAndroid || await Notifier.instance.canScheduleExact();

    final missing = <String>[
      if (bioAvailable && !bioOn) 'fingerprint unlock',
      if (!notifOn) 'notifications',
      if (Platform.isAndroid && !exactOn) 'exact open-day alerts',
    ];
    if (missing.isEmpty || !mounted) return;

    final one = missing.length == 1;
    final showTest = !notifOn || (Platform.isAndroid && !exactOn);
    final go = await showMiniSheet(
      context,
      icon: Icons.tune_rounded,
      badge: 'FINISH SETUP',
      title: one ? 'One switch left for Capsule' : 'Capsule isn’t fully set up',
      message: one
          ? 'Turn on ${_readableList(missing)} so Capsule works the way it should.'
          : 'Turn on ${_readableList(missing)} so a capsule can reach you the '
              'moment it opens — even with the app closed.',
      tip: showTest
          ? 'After enabling, run “Test background alert” in your profile to '
              'watch a real open-day alert land.'
          : null,
      cta: 'Take me there',
      dismissLabel: 'Later',
    );
    store.snoozePermissionNudge();
    if (go && mounted) setState(() => _index = 2);
  }

  /// "a", "a and b", "a, b, and c".
  static String _readableList(List<String> xs) {
    if (xs.length == 1) return xs.first;
    if (xs.length == 2) return '${xs[0]} and ${xs[1]}';
    return '${xs.sublist(0, xs.length - 1).join(', ')}, and ${xs.last}';
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    return Scaffold(
      backgroundColor: C.paper,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              CapsuleListScreen(),
              ProfileScreen(),
            ],
          ),
          Positioned(
            left: 26,
            right: 26,
            bottom: 30,
            child: Row(
              children: [
                Expanded(
                  child: FrostedBar(
                    children: [
                      NavIcon(
                        LockGlyph(
                            size: 20,
                            color: _index == 0 ? C.onFill : C.muted,
                            stroke: 1.8),
                        label: 'Home',
                        active: _index == 0,
                        onTap: () => setState(() => _index = 0),
                      ),
                      NavIcon(
                        Icon(Icons.grid_view_rounded,
                            size: 19, color: _index == 1 ? C.onFill : C.muted),
                        label: 'Capsules',
                        active: _index == 1,
                        onTap: () => setState(() => _index = 1),
                      ),
                      NavIcon(
                        Icon(Icons.person_outline,
                            size: 20, color: _index == 2 ? C.onFill : C.muted),
                        label: 'Profile',
                        active: _index == 2,
                        onTap: () => setState(() => _index = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ComposeButton(onTap: () => go(context, const NewCapsuleScreen())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The standalone "new capsule" action, sitting apart from the nav bar.
class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: C.fill,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF321E50).withValues(alpha: 0.45),
              blurRadius: 30,
              spreadRadius: -8,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Icon(Icons.add, size: 26, color: C.onFill),
      ),
    );
  }
}
