import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'core/tokens.dart';
import 'data/scan_store.dart';
import 'ml/classifier.dart';
import 'ui/guide_intro_page.dart';
import 'ui/shell.dart';
import 'ui/splash_page.dart';

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
  final Classifier _classifier = Classifier();

  /// null while we are still finding out; true once the guide has been seen.
  bool? _guideSeen;
  bool _modelFailed = false;

  static const String _guideKey = 'photo_guide_seen';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Language and records first: they decide what the first frame says.
    await _language.load();
    await _store.load();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: _language,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ScanStore>.value(value: _store),
          Provider<Classifier>.value(value: _classifier),
        ],
        child: MaterialApp(
          title: 'ChickDetect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Builder(
            builder: (BuildContext context) {
              if (_guideSeen == null) return const SplashPage();
              if (_guideSeen == false) {
                return GuideIntroPage(onDone: _markGuideSeen);
              }
              return AppShell(modelFailed: _modelFailed);
            },
          ),
        ),
      ),
    );
  }
}
