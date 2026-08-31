import 'package:flutter/material.dart';

const String kFontFamily = 'Plus Jakarta Sans';

/// Which palette [C] is currently serving. Flipped by `AppStore` at the app
/// root; every screen reads [C] fresh on build so a toggle repaints all of
/// them at once.
enum AppBrightness { light, dark }

/// Immutable colour set. One instance per brightness (see [_light] / [_dark]).
class _Palette {
  const _Palette({
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.plum,
    required this.plum2,
    required this.slate,
    required this.muted,
    required this.muted2,
    required this.muted3,
    required this.label,
    required this.label2,
    required this.label3,
    required this.bodyInk,
    required this.bodyInk2,
    required this.violetInk,
    required this.faint,
    required this.faint2,
    required this.weekday,
    required this.canvas,
    required this.paper,
    required this.lav1,
    required this.lav2,
    required this.lav3,
    required this.lav4,
    required this.lav5,
    required this.lav6,
    required this.lav7,
    required this.divider,
    required this.dashed,
    required this.dashPurple,
    required this.card1,
    required this.card2,
    required this.card3,
    required this.blobPink,
    required this.blobMid,
    required this.blobDeep,
    required this.greenBg,
    required this.greenInk,
    required this.fill,
    required this.onFill,
    required this.glass,
    required this.glassSoft,
    required this.glassLine,
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
  });

  final Color ink, ink2, ink3, plum, plum2, slate;
  final Color muted, muted2, muted3;
  final Color label, label2, label3, bodyInk, bodyInk2, violetInk;
  final Color faint, faint2, weekday;
  final Color canvas, paper, lav1, lav2, lav3, lav4, lav5, lav6, lav7;
  final Color divider, dashed, dashPurple;
  final Color card1, card2, card3, blobPink, blobMid, blobDeep;
  final Color greenBg, greenInk;

  /// Semantic tokens (theme-aware, not lifted from the mock).
  /// [fill] / [onFill] — primary solid button + active-nav surface and the text
  /// that sits on it. [glass] / [glassSoft] — the frosted translucent panels.
  final Color fill, onFill, glass, glassSoft, glassLine;

  /// Screen background gradient stops.
  final Color bgTop, bgMid, bgBottom;
}

const _light = _Palette(
  ink: Color(0xFF141019),
  ink2: Color(0xFF1B1226),
  ink3: Color(0xFF2C2440),
  plum: Color(0xFF3B2E5C),
  plum2: Color(0xFF3B3155),
  slate: Color(0xFF3E3358),
  muted: Color(0xFF5B4E7C),
  muted2: Color(0xFF6B5C90),
  muted3: Color(0xFF8C7FAE),
  label: Color(0xFF4C4069),
  label2: Color(0xFF5C4E7D),
  label3: Color(0xFF463A63),
  bodyInk: Color(0xFF4B4067),
  bodyInk2: Color(0xFF4B3A72),
  violetInk: Color(0xFF5B4A7E),
  faint: Color(0xFFB0A4CA),
  faint2: Color(0xFFCFC6DF),
  weekday: Color(0xFFA498C2),
  canvas: Color(0xFFC9BFDF),
  paper: Color(0xFFFBFAFD),
  lav1: Color(0xFFF0ECF7),
  lav2: Color(0xFFF4F1FA),
  lav3: Color(0xFFF7F5FC),
  lav4: Color(0xFFEDE8F6),
  lav5: Color(0xFFEAE4F3),
  lav6: Color(0xFFF1EDF8),
  lav7: Color(0xFFF2EEF8),
  divider: Color(0xFFE7E1F1),
  dashed: Color(0xFFC7BBDF),
  dashPurple: Color(0xFF7B6CA0),
  card1: Color(0xFFCFC3E8),
  card2: Color(0xFFBDA8DF),
  card3: Color(0xFFB69FDB),
  blobPink: Color(0xFFF2C8D2),
  blobMid: Color(0xFFC69BD8),
  blobDeep: Color(0xFF6E3F9E),
  greenBg: Color(0xFFE4F0EA),
  greenInk: Color(0xFF26543F),
  fill: Color(0xFF141019),
  onFill: Color(0xFFFFFFFF),
  glass: Color(0xCCFFFFFF),
  glassSoft: Color(0x8CFFFFFF),
  glassLine: Color(0x14141019),
  bgTop: Color(0xFFF3F1F6),
  bgMid: Color(0xFFE8E2F1),
  bgBottom: Color(0xFFDED5EC),
);

const _dark = _Palette(
  ink: Color(0xFFF3EFFA),
  ink2: Color(0xFFEBE4F7),
  ink3: Color(0xFFDDD4EC),
  plum: Color(0xFFCABFE4),
  plum2: Color(0xFFC5BADF),
  slate: Color(0xFFC7BCE1),
  muted: Color(0xFF9C8FBE),
  muted2: Color(0xFFA99BC8),
  muted3: Color(0xFF897BAB),
  label: Color(0xFFB2A4D2),
  label2: Color(0xFFB6A9D4),
  label3: Color(0xFFA99BCB),
  bodyInk: Color(0xFFB3A6D2),
  bodyInk2: Color(0xFFB8A9DC),
  violetInk: Color(0xFFAB9CCB),
  faint: Color(0xFF6B5E8A),
  faint2: Color(0xFF4E4368),
  weekday: Color(0xFF7E7299),
  canvas: Color(0xFF2A2140),
  paper: Color(0xFF100B1A),
  lav1: Color(0xFF221A36),
  lav2: Color(0xFF1E1730),
  lav3: Color(0xFF1B142B),
  lav4: Color(0xFF2A2142),
  lav5: Color(0xFF2E2547),
  lav6: Color(0xFF241C39),
  lav7: Color(0xFF241C39),
  divider: Color(0xFF2C2347),
  dashed: Color(0xFF4A3E68),
  dashPurple: Color(0xFF9484B8),
  card1: Color(0xFF3B3059),
  card2: Color(0xFF4B3B70),
  card3: Color(0xFF473969),
  blobPink: Color(0xFFB98B99),
  blobMid: Color(0xFF8C6AA8),
  blobDeep: Color(0xFF6E3F9E),
  greenBg: Color(0xFF1E3B30),
  greenInk: Color(0xFF8FD9B8),
  fill: Color(0xFFEFE9F8),
  onFill: Color(0xFF171126),
  glass: Color(0x1FFFFFFF),
  glassSoft: Color(0x12FFFFFF),
  glassLine: Color(0x1FFFFFFF),
  bgTop: Color(0xFF181022),
  bgMid: Color(0xFF1E1530),
  bgBottom: Color(0xFF241833),
);

/// Design tokens. Every member is a theme-aware getter — reading `C.ink` on a
/// dark build returns the dark value. Call [C.set] (done by the app root) to
/// switch, then rebuild the tree.
class C {
  C._();

  static _Palette _p = _light;

  static AppBrightness get brightness => _p == _dark ? AppBrightness.dark : AppBrightness.light;
  static bool get isDark => _p == _dark;

  static void set(AppBrightness b) {
    _p = b == AppBrightness.dark ? _dark : _light;
  }

  // Ink / text
  static Color get ink => _p.ink;
  static Color get ink2 => _p.ink2;
  static Color get ink3 => _p.ink3;
  static Color get plum => _p.plum;
  static Color get plum2 => _p.plum2;
  static Color get slate => _p.slate;
  static Color get muted => _p.muted;
  static Color get muted2 => _p.muted2;
  static Color get muted3 => _p.muted3;
  static Color get label => _p.label;
  static Color get label2 => _p.label2;
  static Color get label3 => _p.label3;
  static Color get bodyInk => _p.bodyInk;
  static Color get bodyInk2 => _p.bodyInk2;
  static Color get violetInk => _p.violetInk;
  static Color get faint => _p.faint;
  static Color get faint2 => _p.faint2;
  static Color get weekday => _p.weekday;

  // Surfaces
  static Color get canvas => _p.canvas;
  static Color get paper => _p.paper;
  static Color get lav1 => _p.lav1;
  static Color get lav2 => _p.lav2;
  static Color get lav3 => _p.lav3;
  static Color get lav4 => _p.lav4;
  static Color get lav5 => _p.lav5;
  static Color get lav6 => _p.lav6;
  static Color get lav7 => _p.lav7;
  static Color get divider => _p.divider;
  static Color get dashed => _p.dashed;
  static Color get dashPurple => _p.dashPurple;

  // Accent purples / gradients
  static Color get card1 => _p.card1;
  static Color get card2 => _p.card2;
  static Color get card3 => _p.card3;
  static Color get blobPink => _p.blobPink;
  static Color get blobMid => _p.blobMid;
  static Color get blobDeep => _p.blobDeep;

  // Status
  static Color get greenBg => _p.greenBg;
  static Color get greenInk => _p.greenInk;

  // Semantic (theme-aware)
  static Color get fill => _p.fill;
  static Color get onFill => _p.onFill;
  static Color get glass => _p.glass;
  static Color get glassSoft => _p.glassSoft;
  static Color get glassLine => _p.glassLine;
  static Color get bgTop => _p.bgTop;
  static Color get bgMid => _p.bgMid;
  static Color get bgBottom => _p.bgBottom;

  /// Standard top-to-bottom screen wash.
  static LinearGradient get screenGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_p.bgTop, _p.bgMid, _p.bgBottom],
        stops: const [0, .55, 1],
      );

  static TextStyle t(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? _p.ink,
        letterSpacing: letterSpacing == null ? null : size * letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );
}

const double kBoardW = 390;
const double kBoardH = 844;
const Radius kBoardRadius = Radius.circular(46);

BoxShadow get kBoardShadow => BoxShadow(
      color: const Color(0xFF3C285A).withValues(alpha: 0.45),
      blurRadius: 80,
      spreadRadius: -30,
      offset: const Offset(0, 40),
    );
