import 'package:flutter/material.dart';
import '../app_state.dart';
import '../nav.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'create_pin.dart';

class _Slide {
  const _Slide(this.image, this.title, this.body);
  final String image;
  final String title;
  final String body;
}

const _slides = <_Slide>[
  _Slide(
    'assets/imgs/slide1',
    'Say it now.\nRead it later.',
    'Write a note, add photos, pick the day it opens. A message to whoever you '
        'become.',
  ),
  _Slide(
    'assets/imgs/slide2',
    'Sealed means\nsealed.',
    'Once you lock a capsule, not even you can open it early. No preview, no '
        'export, no shortcuts.',
  ),
  _Slide(
    'assets/imgs/slide3',
    'Future you is\nlistening.',
    'Choose the open day and let it go. Capsule brings it back to you right on '
        'time.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _slides.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    AppScope.read(context).completeOnboarding();
    goRoot(context, const CreatePinScreen());
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    return Screen(
      decoration: BoxDecoration(gradient: C.screenGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: C.glassLine),
                    ),
                    child: Image.asset(
                      'assets/imgs/icon',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: C.fill,
                        child: Center(
                          child: LockGlyph(size: 18, stroke: 1.8, color: C.onFill),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _finish,
                    child: Text('Skip',
                        style: C.t(14, weight: FontWeight.w600, color: C.muted)),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 0; i < _slides.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: i == _page ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page ? C.ink : C.ink.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _next,
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: C.fill,
                    borderRadius: BorderRadius.circular(31),
                  ),
                  alignment: Alignment.center,
                  child: Text(_isLast ? 'Get started' : 'Next',
                      style: C.t(17, weight: FontWeight.w700, color: C.onFill)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              slide.image,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _ImagePlaceholder(),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(slide.title,
            style: C.t(38, weight: FontWeight.w800, letterSpacing: -.035, height: 1.05)),
        const SizedBox(height: 14),
        Text(slide.body, style: C.t(15.5, color: C.bodyInk, height: 1.55)),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Stand-in until the real slide artwork is dropped into `assets/imgs/`.
class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [C.card1, C.card3],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 34, color: C.onFill.withValues(alpha: .8)),
            const SizedBox(height: 8),
            Text('Artwork coming',
                style: C.t(12.5, weight: FontWeight.w700, color: C.onFill.withValues(alpha: .8))),
          ],
        ),
      ),
    );
  }
}
