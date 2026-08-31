import 'package:flutter/material.dart';
import '../app_state.dart';
import '../nav.dart';
import '../services.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

enum _Phase { unlock, currentPin, create, confirm }

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key, this.change = false});

  /// Launched from Settings to change an existing PIN.
  final bool change;

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';
  String _firstEntry = '';
  String? _error;
  late _Phase _phase;

  int get _entered => _pin.length;

  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _phase = widget.change ? _Phase.currentPin : _Phase.create;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;
    if (!widget.change && AppScope.of(context).hasPin) {
      _phase = _Phase.unlock;
    }
  }

  void _tap(String key) {
    final store = AppScope.read(context);
    if (key == 'bio') return;
    setState(() {
      _error = null;
      if (key == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        return;
      }
      if (_pin.length >= 4) return;
      _pin += key;
      if (_pin.length == 4) {
        final entered = _pin;
        Future.delayed(const Duration(milliseconds: 160), () {
          if (mounted) _advance(store, entered);
        });
      }
    });
  }

  void _advance(AppStore store, String entered) {
    switch (_phase) {
      case _Phase.unlock:
        if (store.checkPin(entered)) {
          goRoot(context, const MainShell());
        } else {
          setState(() {
            _pin = '';
            _error = 'Wrong PIN. Try again.';
          });
        }
      case _Phase.currentPin:
        if (store.checkPin(entered)) {
          setState(() {
            _pin = '';
            _phase = _Phase.create;
          });
        } else {
          setState(() {
            _pin = '';
            _error = 'That’s not your current PIN.';
          });
        }
      case _Phase.create:
        setState(() {
          _firstEntry = entered;
          _pin = '';
          _phase = _Phase.confirm;
        });
      case _Phase.confirm:
        if (entered == _firstEntry) {
          store.setPin(entered);
          if (widget.change) {
            back(context);
          } else {
            goRoot(context, const MainShell());
          }
        } else {
          setState(() {
            _pin = '';
            _firstEntry = '';
            _phase = _Phase.create;
            _error = 'PINs didn’t match. Start again.';
          });
        }
    }
  }

  ({String eyebrow, String title, String body}) _copyFor(_Phase p) {
    switch (p) {
      case _Phase.unlock:
        return (
          eyebrow: 'UNLOCK',
          title: 'Enter your\n4-digit PIN',
          body: 'Your capsules stay locked behind this PIN. Only this device, only you.',
        );
      case _Phase.currentPin:
        return (
          eyebrow: 'STEP 1 OF 3',
          title: 'Enter your\ncurrent PIN',
          body: 'Confirm it’s you before choosing a new PIN.',
        );
      case _Phase.create:
        return (
          eyebrow: widget.change ? 'STEP 2 OF 3' : 'STEP 1 OF 2',
          title: widget.change ? 'Choose a\nnew PIN' : 'Set your\n4-digit PIN',
          body:
              "Everything stays on this phone. There's no account, no cloud, no reset link — so pick one you'll remember.",
        );
      case _Phase.confirm:
        return (
          eyebrow: widget.change ? 'STEP 3 OF 3' : 'STEP 2 OF 2',
          title: 'Re-enter to\nconfirm',
          body: 'Type the same four digits once more.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    final copy = _copyFor(_phase);
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
                    Text(copy.eyebrow,
                        style: C.t(13, weight: FontWeight.w700, color: C.muted2, letterSpacing: .14)),
                  ],
                ),
                const SizedBox(height: 34),
                Text(copy.title,
                    style: C.t(36, weight: FontWeight.w800, letterSpacing: -.03, height: 1.08)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 290,
                  child: Text(copy.body, style: C.t(15, color: C.bodyInk, height: 1.55)),
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
                    _error ?? '',
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
                if (_phase == _Phase.unlock)
                  GestureDetector(
                    onTap: _biometricUnlock,
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

  Future<void> _biometricUnlock() async {
    final ok = await Biometrics.instance.authenticate(context, 'Unlock Capsule');
    if (ok && mounted) goRoot(context, const MainShell());
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
