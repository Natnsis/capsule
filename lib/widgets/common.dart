import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../tokens.dart';

/// A plainly scrollable screen body. Content lays out top-to-bottom and the
/// whole thing scrolls when the viewport is shorter than the content, so a
/// screen can never overflow on a small or oddly-shaped window.
///
/// [child] should be a `Column` with fixed spacing (no `Spacer`/`Expanded` —
/// there's no bounded height to flex against inside a scroll view).
class AdaptiveBody extends StatelessWidget {
  const AdaptiveBody({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: padding, child: child);
  }
}

/// A full-bleed app screen: fills the device, paints the background
/// (solid colour or gradient) edge to edge, and hosts the screen content.
class Screen extends StatelessWidget {
  const Screen({
    super.key,
    required this.child,
    this.decoration,
    this.color,
  });

  final Widget child;
  final BoxDecoration? decoration;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color ?? C.paper,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

/// Back-compat alias kept only so a preview index can still render a framed
/// thumbnail of a screen. Not used by the running app.
class Artboard extends StatelessWidget {
  const Artboard({super.key, this.label = '', required this.child, this.decoration});

  final String label;
  final Widget child;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kBoardW,
      height: kBoardH,
      clipBehavior: Clip.antiAlias,
      decoration: (decoration ?? BoxDecoration(color: C.paper)).copyWith(
        borderRadius: const BorderRadius.all(kBoardRadius),
        boxShadow: [kBoardShadow],
      ),
      child: child,
    );
  }
}

/// Soft radial "blob" used across the gradient screens.
class Blob extends StatelessWidget {
  const Blob({
    super.key,
    required this.size,
    required this.colors,
    this.stops,
    this.center = const Alignment(-0.32, -0.4),
    this.opacity = 1,
  });

  final double size;
  final List<Color> colors;
  final List<double>? stops;
  final Alignment center;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: center, radius: 0.75, colors: colors, stops: stops),
        ),
      ),
    );
  }
}

class DashedRRect extends StatelessWidget {
  const DashedRRect({
    super.key,
    required this.child,
    this.radius = 22,
    this.color,
    this.strokeWidth = 1.5,
    this.gap = 5,
    this.dash = 5,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final double strokeWidth;
  final double gap;
  final double dash;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(radius, color ?? C.dashed, strokeWidth, gap, dash),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.radius, this.color, this.strokeWidth, this.gap, this.dash);
  final double radius, strokeWidth, gap, dash;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}

/// The Capsule padlock motif (rounded body + arc shackle).
class LockGlyph extends StatelessWidget {
  const LockGlyph({super.key, this.size = 20, this.color = Colors.white, this.stroke = 1.8, this.open = false});
  final double size;
  final Color color;
  final double stroke;
  final bool open;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LockPainter(color, stroke, open));
}

class _LockPainter extends CustomPainter {
  _LockPainter(this.color, this.stroke, this.open);
  final Color color;
  final double stroke;
  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // body: rect x4 y9 w16 h11 rx6
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(4 * s, 9 * s, 16 * s, 11 * s),
      Radius.circular(5.5 * s),
    );
    canvas.drawRRect(body, p);

    // shackle: arc from (8,9) up over to (16,9)
    final shackle = Path();
    if (open) {
      shackle
        ..moveTo(8 * s, 9 * s)
        ..lineTo(8 * s, 6.5 * s)
        ..arcToPoint(Offset(16 * s, 5.5 * s), radius: Radius.circular(4 * s));
    } else {
      shackle
        ..moveTo(8 * s, 9 * s)
        ..lineTo(8 * s, 7 * s)
        ..arcToPoint(Offset(16 * s, 7 * s), radius: Radius.circular(4 * s))
        ..lineTo(16 * s, 9 * s);
    }
    canvas.drawPath(shackle, p);

    // keyhole dot
    canvas.drawCircle(Offset(12 * s, 13.5 * s), 1.1 * s, Paint()..color = color);
    canvas.drawLine(Offset(12 * s, 14 * s), Offset(12 * s, 16.5 * s), p);
  }

  @override
  bool shouldRepaint(covariant _LockPainter old) =>
      old.color != color || old.stroke != stroke || old.open != open;
}

/// Concentric-arc fingerprint used on the biometric screen.
class FingerprintGlyph extends StatelessWidget {
  const FingerprintGlyph({super.key, this.size = 76, this.color = Colors.white, this.stroke = 1.1});
  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _FingerprintPainter(color, stroke));
}

class _FingerprintPainter extends CustomPainter {
  _FingerprintPainter(this.color, this.stroke);
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * size.width / 24
      ..strokeCap = StrokeCap.round
      ..color = color;
    final maxR = size.width * 0.46;
    for (int i = 0; i < 5; i++) {
      final r = maxR * (1 - i * 0.17);
      final start = -math.pi * (0.92 - i * 0.05);
      final sweep = math.pi * (1.0 + i * 0.08);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false, p);
    }
    // central vertical ridges
    canvas.drawLine(Offset(c.dx, c.dy - maxR * 0.1), Offset(c.dx, c.dy + maxR * 0.55), p);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(c.dx, c.dy + maxR * 0.2), radius: maxR * 0.22),
      math.pi * 0.05,
      math.pi * 0.9,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter old) => old.color != color || old.stroke != stroke;
}

/// Frosted pill used for the floating bottom navigation bars.
class FrostedBar extends StatelessWidget {
  const FrostedBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(37),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: C.isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(37),
            border: C.isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.12))
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF321E50).withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: -18,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A single bottom-bar tab. Inactive: just the icon. Active: a horizontal
/// pill — icon with the label beside it — sitting in the filled background.
class NavIcon extends StatelessWidget {
  const NavIcon(this.icon, {super.key, this.label, this.active = false, this.onTap});
  final Widget icon;
  final String? label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12),
        decoration: BoxDecoration(
          color: active ? C.fill : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (active && label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: C.t(13, weight: FontWeight.w700, color: C.onFill),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The owner's round profile picture. Uses the set image if there is one,
/// otherwise the bundled `assets/imgs/profile` placeholder.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.size, this.borderWidth = 3});
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: C.glass, width: borderWidth),
        image: DecorationImage(
          image: AppScope.of(context).profileImageOrPlaceholder,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Rounded square icon chip (e.g. the calendar / lock chips in headers).
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.child,
    this.size = 46,
    this.radius = 23,
    this.color,
  });
  final Widget child;
  final double size;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color ?? C.lav1, borderRadius: BorderRadius.circular(radius)),
        alignment: Alignment.center,
        child: child,
      );
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.child,
    required this.background,
    this.height = 44,
    this.padH = 20,
  });
  final Widget child;
  final Color background;
  final double height;
  final double padH;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: padH),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(height / 2)),
        alignment: Alignment.center,
        child: child,
      );
}

class Toggle extends StatelessWidget {
  const Toggle({super.key, this.on = true});
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? C.fill : C.faint,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: C.onFill, shape: BoxShape.circle),
        ),
      );
}

/// Simple stroked chevron / arrow icons matching the SVG line style.
class Stroke {
  static Widget icon(IconData data, {double size = 20, Color? color, double weight = 1.8}) =>
      Icon(data, size: size, color: color ?? C.ink, weight: weight * 200);
}
