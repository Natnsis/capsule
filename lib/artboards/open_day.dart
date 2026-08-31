import 'package:flutter/material.dart';
import '../nav.dart';
import '../app_state.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'new_capsule.dart';

class OpenDayScreen extends StatelessWidget {
  const OpenDayScreen({super.key, this.title = 'To me, at 25'});
  final String title;

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    return Screen(
      color: C.paper,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
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
                    color: C.lav1,
                    child: Icon(Icons.arrow_back, size: 20, color: C.ink),
                  ),
                ),
                Row(
                  children: [
                    IconChip(
                      size: 46,
                      radius: 23,
                      color: C.lav1,
                      child: Icon(Icons.share_outlined, size: 19, color: C.ink),
                    ),
                    const SizedBox(width: 10),
                    IconChip(
                      size: 46,
                      radius: 23,
                      color: C.lav1,
                      child: Icon(Icons.download_outlined, size: 19, color: C.ink),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.greenBg, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LockGlyph(size: 13, color: C.greenInk, stroke: 2.1, open: true),
                  const SizedBox(width: 7),
                  Text('Opened today · 15 Sep 2026',
                      style: C.t(12.5, weight: FontWeight.w700, color: C.greenInk)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('To me, at 25',
                style: C.t(38, weight: FontWeight.w800, letterSpacing: -.035, height: 1.04)),
            const SizedBox(height: 8),
            Text('Written 12 Sep 2024 · sealed for 2 years, 3 days',
                style: C.t(13.5, weight: FontWeight.w600, color: C.muted3)),
            const SizedBox(height: 20),
            Row(
              children: [
                _photo(const [Color(0xFFE9D3DB), Color(0xFFC3AEE0)],
                    const Alignment(0.9, 0.9), const [Color(0xFFFDF0F3), Color(0xFFB784C9)]),
                const SizedBox(width: 10),
                _photo(const [Color(0xFFD5E6DF), Color(0xFFB9C9E8)],
                    const Alignment(-0.9, -0.9), const [Colors.white, Color(0xFF8FA9D6)]),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              "Hey. You're 25 now, which sounds impossible from here. I'm writing this from the small desk by the window, the one that wobbles.\n\nThings I hope are still true: you still call home on Sundays, you still make the bad jokes, you still keep the notebook. Things I hope changed: the fear of starting.",
              style: C.t(16.5, color: C.ink3, height: 1.75),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => go(context, const NewCapsuleScreen()),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(color: C.lav2, borderRadius: BorderRadius.circular(32)),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Icon(Icons.add, size: 20, color: C.onFill),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Write one back', style: C.t(16, weight: FontWeight.w700)),
                        Text('Reply to yourself, seal it for 2028',
                            style: C.t(13, weight: FontWeight.w500, color: C.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: C.ink),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo(List<Color> base, Alignment blobAt, List<Color> blobColors) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 118,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: base,
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: blobAt,
                child: Blob(size: 125, center: const Alignment(-0.3, -0.4), colors: blobColors),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
