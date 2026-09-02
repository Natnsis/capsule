import 'package:flutter/material.dart';

import 'db.dart';

const _mon = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String fmtDay(DateTime d) => '${d.day} ${_mon[d.month - 1]} ${d.year}';

/// A stable pastel pair for a capsule's icon tile, chosen from its id.
List<Color> capsuleGradient(int seed) {
  const palettes = <List<Color>>[
    [Color(0xFFCFC3E8), Color(0xFFBDA8DF)],
    [Color(0xFFE9D2DA), Color(0xFFCBB6E4)],
    [Color(0xFFD7E7E0), Color(0xFFBFCFEA)],
    [Color(0xFFE7C9D4), Color(0xFFB49BD6)],
    [Color(0xFFE9D3DB), Color(0xFFC3AEE0)],
    [Color(0xFFD5E6DF), Color(0xFFB9C9E8)],
  ];
  return palettes[seed.abs() % palettes.length];
}

/// "Opens 15 Sep 2026 · 3 days left" / "Opened 12 Jan 2026".
/// [openMoment] is the capsule's open date at the user's preferred time —
/// pass `store.openMomentOf(c)`.
String capsuleSubtitle(Capsule c, DateTime openMoment) {
  if (!c.sealed) return 'Opened ${fmtDay(c.openedAt!)}';
  final days = openMoment.difference(DateTime.now()).inDays;
  String rel;
  if (days <= 0) {
    rel = 'opens today';
  } else if (days < 45) {
    rel = '$days days left';
  } else if (days < 365) {
    rel = '${(days / 30).round()} m left';
  } else {
    final y = days ~/ 365;
    final m = ((days % 365) / 30).round();
    rel = m > 0 ? '$y y $m m left' : '$y y left';
  }
  return 'Opens ${fmtDay(openMoment)} · $rel';
}
