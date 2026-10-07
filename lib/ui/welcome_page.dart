import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';

/// The first screen a new user sees: what ChickDetect is for, and one button.
///
/// A photograph of the app in use fills the screen. Over its top, a soft
/// white fade carries the brand and a large, left-aligned headline; over its
/// foot, a second fade carries the one action at thumb height. Reads top to
/// bottom: who this is, what it does, the scene, then the button.
///
/// It is also the landing screen on every launch. While the app loads,
/// [onStart] is null and a slim loading bar sits where the button goes; the
/// app then moves on by itself. Only on first launch does the button appear,
/// fading in on the same screen, because only then is there a guide to start.
/// One landing page, never a button to tap through every day.
class WelcomePage extends StatelessWidget {
  final VoidCallback? onStart;

  /// The background photograph. Swap for the final artwork when it exists.
  static const String heroAsset = 'assets/onboarding/welcome_hero.jpg';

  const WelcomePage({super.key, this.onStart});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            heroAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          // Top fade for the words, bottom fade for the button: the photo
          // shows through in the middle, where nothing needs to be read.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // A light veil at the top, not a white-out: the sky stays
                // visible, and the dark headline still reads on it (the
                // contrast was measured on the photo's sky).
                stops: <double>[0, 0.30, 0.46, 0.72, 0.90],
                colors: <Color>[
                  Color(0x66FFFFFF),
                  Color(0x33FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x00F6F8FA),
                  AppColor.bg,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.xl,
                Insets.lg,
                Insets.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Brand: the real mark beside the logo's own lettering.
                  Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/images/logo_mark.png',
                        width: 58,
                        height: 58,
                        filterQuality: FilterQuality.medium,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Image.asset(
                              'assets/images/logo_wordmark.png',
                              semanticLabel: l.appName,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),
                  Text(
                    l.welcomeHeadline,
                    style: AppFont.display.copyWith(
                      fontSize: 36,
                      height: 1.15,
                      color: AppColor.green900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.welcomeSubhead,
                    style: AppFont.h1.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: AppColor.ink2,
                    ),
                  ),
                  const Spacer(),
                  // Same height either way, so nothing jumps when the button
                  // takes the loading bar's place.
                  SizedBox(
                    height: Insets.button + 12 + 18,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: onStart == null
                          ? Column(
                              key: const ValueKey<String>('loading'),
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(Insets.rFull),
                                  child: const LinearProgressIndicator(
                                    minHeight: 5,
                                    backgroundColor: Color(0x1F0A4A33),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColor.green700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l.loadingModel,
                                  style: AppFont.labelSm.copyWith(
                                    color: AppColor.ink2,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey<String>('start'),
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                ElevatedButton(
                                  onPressed: onStart,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(l.welcomeStart),
                                      const SizedBox(width: 8),
                                      const Icon(AppIcons.chevron, size: 18),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    l.welcomeNote,
                                    style: AppFont.labelSm.copyWith(
                                      color: AppColor.ink2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
