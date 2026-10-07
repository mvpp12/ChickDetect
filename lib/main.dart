import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'core/tokens.dart';
import 'data/contacts.dart';
import 'data/scan_store.dart';
import 'ml/classifier.dart';
import 'ui/guide_intro_page.dart';
import 'ui/shell.dart';
import 'ui/welcome_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColor.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ChickDetectApp());
}

class ChickDetectApp extends StatefulWidget {
  /// Supplied only by the browser preview, which pre-fills sample scans.
  final ScanStore? store;

  const ChickDetectApp({super.key, this.store});

  @override
  State<ChickDetectApp> createState() => _ChickDetectAppState();
}

class _ChickDetectAppState extends State<ChickDetectApp> {
  final LanguageController _language = LanguageController();
  late final ScanStore _store = widget.store ?? ScanStore();
  final ContactStore _contacts = ContactStore();
  final Classifier _classifier = Classifier();

  /// null while we are still finding out; true once the guide has been seen.
  bool? _guideSeen;

  /// First launch only: the welcome screen comes before the guide. Not
  /// stored — once the guide is finished it never shows again anyway.
  bool _welcomeDone = false;
  bool _modelFailed = false;

  static const String _guideKey = 'photo_guide_seen';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// The landing page stays at least this long, even when loading is instant
  /// — in a browser it is, and the logo used to flash past unseen. Loading
  /// that takes longer (the AI on an older phone) simply keeps it up longer.
  /// The landing page shows its loading bar for at least this long.
  static const Duration minSplash = Duration(milliseconds: 2500);

  Future<void> _boot() async {
    final Stopwatch shown = Stopwatch()..start();

    // Language and records first: they decide what the first frame says.
    await _language.load();
    await _store.load();
    await _contacts.load();

    bool seen = false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_guideKey) ?? false;
    } catch (_) {
      seen = false;
    }

    // The model is the slow part. Loading it here rather than on the scan
    // screen means the shutter is live the moment the camera opens, instead of
    // the farmer pressing a dead button and assuming the app is broken.
    try {
      await _classifier.load();
    } catch (_) {
      _modelFailed = true;
    }

    final Duration left = minSplash - shown.elapsed;
    if (left > Duration.zero) await Future<void>.delayed(left);

    if (!mounted) return;
    setState(() => _guideSeen = seen);
  }

  Future<void> _markGuideSeen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guideKey, true);
    } catch (_) {
      // Worst case the guide shows once more. Not worth failing over.
    }
    if (!mounted) return;
    setState(() => _guideSeen = true);
  }

  @override
  void dispose() {
    _classifier.dispose();
    _language.dispose();
    _store.dispose();
    _contacts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: _language,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ScanStore>.value(value: _store),
          ChangeNotifierProvider<ContactStore>.value(value: _contacts),
          Provider<Classifier>.value(value: _classifier),
        ],
        child: MaterialApp(
          title: 'ChickDetect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          // A short fade from the landing page into the app, instead of a cut.
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOut,
            child: switch (_guideSeen) {
              // Loading: the landing page with a loading bar, same on every
              // launch. Keyed the same as the first-launch welcome so the
              // button simply fades in on the screen already showing.
              null => const WelcomePage(key: ValueKey<String>('landing')),
              // First launch: welcome, then the guide, then the app.
              false when !_welcomeDone => WelcomePage(
                key: const ValueKey<String>('landing'),
                onStart: () => setState(() => _welcomeDone = true),
              ),
              false => GuideIntroPage(
                key: const ValueKey<String>('guide'),
                onDone: _markGuideSeen,
              ),
              true => AppShell(
                key: const ValueKey<String>('shell'),
                modelFailed: _modelFailed,
              ),
            },
          ),
        ),
      ),
    );
  }
}
