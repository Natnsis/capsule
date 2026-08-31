import 'package:flutter/material.dart';
import '../app_state.dart';
import '../nav.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';
  bool _error = false;

  int get _entered => _pin.length;

  void _tap(String key) {
    final store = AppScope.read(context);
    setState(() {
      _error = false;
      if (key == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (key == 'bio') {
        goRoot(context, const MainShell());
      } else if (_pin.length < 4) {
        _pin += key;
        if (_pin.length == 4) {
          final entered = _pin;
          Future.delayed(const Duration(milliseconds: 180), () {
            if (!mounted) return;
            if (store.hasPin && !store.checkPin(entered)) {
              setState(() {
                _pin = '';
                _error = true;
              });
              return;
            }
            if (!store.hasPin) store.setPin(entered);
            goRoot(context, const MainShell());
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context); // repaint on theme change
    final unlocking = store.hasPin;
    final canGoBack = Navigator.of(context).canPop();
    return Screen(
      decoration: BoxDecoration(gradient: C.screenGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Blob(
              size: 300,
              opacity: C.isDark ? .4 : .75,
              center: const Alignment(-0.2, -0.3),
              colors: const [Colors.white, Color(0xFFE3DAF3), Color(0xFFB7A5DC)],
              stops: const [0, .45, 1],
            ),
          ),
          Positioned.fill(
            child: AdaptiveBody(
            padding: const EdgeInsets.fromLTRB(30, 24, 30, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (canGoBack)
                      GestureDetector(
                        onTap: () => back(context),
                        child: IconChip(
                          size: 44,
                          radius: 22,
                          color: C.glass,
                          child: Icon(Icons.arrow_back, size: 20, color: C.ink),
                        ),
                      )
                    else
                      const SizedBox(width: 44, height: 44),
                    Text(unlocking ? 'UNLOCK' : 'STEP 1 OF 2',
                        style: C.t(13, weight: FontWeight.w700, color: C.muted2, letterSpacing: .14)),
                  ],
                ),
                const SizedBox(height: 34),
                Text(unlocking ? 'Enter your\n4-digit PIN' : 'Set your\n4-digit PIN',
                    style: C.t(36, weight: FontWeight.w800, letterSpacing: -.03, height: 1.08)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 290,
                  child: Text(
                    unlocking
                        ? 'Your capsules stay locked behind this PIN. Only this device, only you.'
                        : "Everything stays on this phone. There's no account, no cloud, no reset link — so pick one you'll remember.",
                    style: C.t(15, color: C.bodyInk, height: 1.55),
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 4; i++) ...[
                      _pinDot(i < _entered),
                      if (i < 3) const SizedBox(width: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _error ? 'That PIN doesn’t match. Try again.' : '',
                    style: C.t(12.5, weight: FontWeight.w600, color: const Color(0xFFE5484D)),
                  ),
                ),
                const SizedBox(height: 24),
                _KeypadRow(['1', '2', '3'], onKey: _tap),
                const SizedBox(height: 14),
                _KeypadRow(['4', '5', '6'], onKey: _tap),
                const SizedBox(height: 14),
                _KeypadRow(['7', '8', '9'], onKey: _tap),
                const SizedBox(height: 14),
                _KeypadRow(const ['add', '0', 'del'], onKey: _tap),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _tap('bio'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fingerprint, size: 18, color: C.muted),
                      const SizedBox(width: 8),
                      Text('Use Face ID / fingerprint instead',
                          style: C.t(14, weight: FontWeight.w600, color: C.muted)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _pinDot(bool filled) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: filled ? C.ink : C.ink.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(9),
        ),
      );
}

/// One row of three keypad keys. Each key flexes to a third of the available
/// width and keeps a fixed height, so the pad never overflows on a narrow phone.
class _KeypadRow extends StatelessWidget {
  const _KeypadRow(this.keys, {required this.onKey});
  final List<String> keys;
  final void Function(String) onKey;

  TextStyle get _numStyle => C.t(26, weight: FontWeight.w600, color: C.ink);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: _key(keys[i])),
        ],
      ],
    );
  }

  Widget _key(String k) {
    final faded = k == 'add' || k == 'del';
    Widget child;
    if (k == 'add') {
      child = Icon(Icons.add, size: 24, color: C.muted2);
    } else if (k == 'del') {
      child = Icon(Icons.backspace_outlined, size: 22, color: C.ink);
    } else {
      child = Text(k, style: _numStyle);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onKey(k),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: faded ? C.glassSoft : C.glass,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
