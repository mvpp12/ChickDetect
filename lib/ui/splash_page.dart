import 'dart:async';

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/tokens.dart';
import 'widgets/brand_mark.dart';

/// First frame. Shows while preferences, records and the model load.
///
/// It carries no claims and no controls — every extra word here is read once
/// and never again. The progress bar is honest: it moves because real work is
/// finishing, and the screen leaves as soon as that work is done.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      // Matches ChickDetectApp.minSplash, so the bar is full as the page
      // leaves rather than stopping short or finishing early.
      duration: const Duration(milliseconds: 2500),
    );
  }

  bool _started = false;
  Timer? _fallback;

  /// The logo animates in only once its image is ready. Otherwise, wherever
  /// loading the image is slow (the browser preview), the fade-in plays while
  /// there is nothing to show and the logo just pops in late. A short timeout
  /// starts it regardless, so a missing image can never hold the page still.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    precacheImage(
      const AssetImage(BrandMark.fullAsset),
      context,
    ).whenComplete(_go);
    _fallback = Timer(const Duration(milliseconds: 700), _go);
  }

  void _go() {
    if (mounted && !_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF7FAF8), AppColor.mintSoft],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned(left: 0, right: 0, bottom: 0, child: _Horizon()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 3),
                    // The full logo carries the name and the one-line promise
                    // itself, so the separate title and tagline that sat here
                    // would only repeat it.
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _c,
                        curve: const Interval(0, 0.45),
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1).animate(
                          CurvedAnimation(
                            parent: _c,
                            curve: const Interval(
                              0,
                              0.5,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Image.asset(
                            BrandMark.fullAsset,
                            filterQuality: FilterQuality.medium,
                            semanticLabel: l.appName,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    AnimatedBuilder(
                      animation: _c,
                      builder: (BuildContext context, Widget? child) {
                        return Column(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Insets.rFull),
                              child: LinearProgressIndicator(
                                value: Curves.easeInOut.transform(_c.value),
                                minHeight: 5,
                                backgroundColor: AppColor.green900.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColor.green700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.loadingModel,
                              style: AppFont.bodySm.copyWith(
                                color: AppColor.ink3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: Insets.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Horizon extends StatelessWidget {
  const _Horizon();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 150,
    child: CustomPaint(painter: _HorizonPainter(), size: Size.infinite),
  );
}

/// Two soft ridges. Drawn rather than shipped as an image so it scales to any
/// screen without a second asset — and so it can never render as the giant
/// arrow the previous build's barn silhouette turned into.
class _HorizonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint far = Paint()..color = AppColor.mint.withValues(alpha: 0.55);
    final Path p1 = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.1,
        size.width * 0.55,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.66,
        size.width,
        size.height * 0.28,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p1, far);

    final Paint near = Paint()
      ..color = AppColor.mintLine.withValues(alpha: 0.5);
    final Path p2 = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.44,
        size.width * 0.58,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.86,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p2, near);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
