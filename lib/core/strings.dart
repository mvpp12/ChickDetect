import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App copy, in Tagalog and English.
///
/// Deliberately a plain Dart class rather than `gen-l10n` and .arb files. The
/// previous version kept its generated localizations checked in, and they went
/// stale every time a string was added — the build then failed on a missing
/// getter, which is the last thing you want the night before a defence. This
/// has no code generation step, so a new string cannot get out of sync with
/// the file that uses it.
///
/// It also keeps [MaterialApp] on its default English locale. Flutter's
/// bundled Material translations do not cover `tl`, and forcing that locale is
/// a runtime crash waiting to happen; the app's own language is a setting that
/// has nothing to do with the framework's.
enum Lang { tl, en }

class L {
  final Lang lang;

  const L(this.lang);

  static const String _prefsKey = 'app_language';

  String _p(String tl, String en) => lang == Lang.tl ? tl : en;

  static L of(BuildContext context) =>
      L(LanguageScope.of(context)?.lang ?? Lang.tl);

  // ── identity ───────────────────────────────────────────────────────────
  String get appName => 'ChickDetect';
  String get onDevice => _p('NASA TELEPONO LANG', 'STAYS ON YOUR PHONE');
  String get offlineReady => _p('Handa kahit offline', 'Ready offline');

  // ── navigation ─────────────────────────────────────────────────────────
  String get navScan => _p('Mag-scan', 'Scan');
  String get navHistory => _p('Listahan', 'Records');
  String get navGuide => _p('Gabay', 'Guide');
  String get navSettings => _p('Settings', 'Settings');

  // ── shared verbs ───────────────────────────────────────────────────────
  String get next => _p('Susunod', 'Next');
  String get back => _p('Bumalik', 'Back');
  String get skip => _p('Lampasan', 'Skip');
  String get cancel => _p('Huwag na', 'Cancel');
  String get delete => _p('Burahin', 'Delete');
  String get close => _p('Isara', 'Close');
  String get save => _p('I-save', 'Save');
  String get retake => _p('Kunan ulit', 'Retake');
  String get usePhoto => _p('Gamitin ito', 'Use this photo');
  String get scanAgain => _p('Mag-scan ulit', 'Scan again');
  String get startScanning => _p('Simulan ang pag-scan', 'Start scanning');
  String get viewFullReport => _p('Buong detalye', 'See full details');
  String get copied => _p('Nakopya na', 'Copied');
  String get done => _p('Tapos na', 'Done');
  String get openSettings => _p('Buksan ang Settings', 'Open settings');

  // ── splash ─────────────────────────────────────────────────────────────
  String get tagline => _p(
    'I-scan ang dumi.\nMakita agad ang sakit.',
    'Scan the droppings.\nSpot sickness early.',
  );
  String get loadingModel =>
      _p('Inihahanda ang app…', 'Getting the app ready…');

  // ── first-run guide ────────────────────────────────────────────────────
  String get guideEyebrow => _p('Bago ka magsimula', 'Before you start');
  String get guideTitle => _p('Paano ito gumagana', 'How it works');
  String get guideIntro => _p(
    'Tatlong hakbang lang, mula sa pagkuha ng litrato hanggang sa resulta. Hindi kailangan ng internet.',
    'Three steps, from taking the photo to seeing the result. No internet needed.',
  );
  String get startGuide => _p('Simulan ang gabay', 'Start the guide');
  String get step => _p('Hakbang', 'Step');
  String get stepOf => _p('sa', 'of');

  // The walkthrough after the landing card. Each of these is written against
  // the photograph it sits on: aiming, reading, and the result.
  String get flow1Title =>
      _p('Itutok sa sariwang dumi', 'Aim at a fresh dropping');
  String get flow1Body => _p(
    'Mga 10 hanggang 15 cm ang layo, isang sariwang dumi lang sa gitna. Dito madalas nagkakamali — kapag pangit ang kuha, mali rin ang resulta.',
    'About 10 to 15 cm away, one fresh dropping in the middle. This is where most mistakes happen — a bad photo gives a wrong result.',
  );
  String get flow1Do => _p('10–15 cm, sariwa', '10–15 cm, fresh');
  String get flow1Dont => _p('Malayo o tuyo', 'Far away or dried');

  String get flow2Title =>
      _p('Sinusuri sa telepono mo', 'Checked on your phone');
  String get flow2Body => _p(
    'Ang AI ay nasa loob ng telepono, ilang segundo lang. Titingnan muna nito kung malinaw ang litrato. Kapag malabo o madilim, sasabihin nito agad — hindi ito manghuhula.',
    'The AI runs inside your phone and takes a few seconds. It first checks that the photo is clear. If it is blurry or dark, it tells you — it will not guess.',
  );

  String get flow3Title =>
      _p('Resulta at ang dapat gawin', 'The result, and what to do');
  String get flow3Body => _p(
    'Malusog, may sakit, o kailangang kunan ulit — kasama ang unang dapat gawin. Naka-save ang bawat scan sa telepono, para makita mo kung gumaganda o lumalala ang lagay ng mga manok mo.',
    'Healthy, sick, or take another photo — with the first thing to do. Every scan is saved on your phone, so you can see if your chickens are getting better or worse.',
  );

  String get rule1Title => _p('Sariwang dumi', 'Fresh droppings');
  String get rule1Body => _p(
    'Kunan sa loob ng 10 hanggang 20 minuto matapos lumabas. Nag-iiba ang kulay at hugis ng tuyong dumi, kaya nagkakamali ang AI.',
    'Take it within 10 to 20 minutes after it comes out. Dry droppings change colour and shape, and the AI gets confused.',
  );
  String get rule1Do => _p('Basa at sariwa', 'Wet and fresh');
  String get rule1Dont => _p('Tuyo o luma', 'Dried or old');

  String get rule2Title =>
      _p('Isa lang, nasa gitna', 'Just one, in the middle');
  String get rule2Body => _p(
    'Isang dumi lang ang kunan. Huwag isama ang sapin, lupa, paa o ibang dumi.',
    'Photograph just one dropping. Keep bedding, soil, feet and other droppings out of the photo.',
  );
  String get rule2Do => _p('Isa, nasa gitna', 'One, in the middle');
  String get rule2Dont => _p('Kalat-kalat', 'Scattered');

  String get rule3Title => _p('Malapit at maliwanag', 'Close and bright');
  String get rule3Body => _p(
    'Mga 10 hanggang 15 cm ang layo, sa maliwanag na lugar. Kung madilim ang kulungan, buksan ang ilaw ng telepono at huwag tabunan ng anino mo.',
    'About 10 to 15 cm away, in good light. If the coop is dark, turn on the phone light and keep your shadow off it.',
  );
  String get rule3Do => _p('10–15 cm, maliwanag', '10–15 cm, bright');
  String get rule3Dont => _p('Malayo o madilim', 'Far or dark');

  // ── camera ─────────────────────────────────────────────────────────────
  String get aimHere =>
      _p('Itapat 10–15 cm mula sa dumi', 'Hold 10–15 cm from the sample');
  String get checkPhoto =>
      _p('Malinaw ba? Isang dumi lang?', 'Is it clear? Just one dropping?');
  String get takePhoto => _p('Kumuha ng litrato', 'Take photo');
  String get lightOn => _p('Patayin ang ilaw', 'Turn the light off');
  String get lightOff => _p('Buksan ang ilaw', 'Turn the light on');
  String get howToScan => _p('Paano mag-scan', 'How to scan');
  String get gallery => _p('Mula sa gallery', 'From gallery');
  String get analysing => _p('Sinusuri ang litrato…', 'Checking the photo…');
  String get checkingPhoto =>
      _p('Sinusuri ang kalidad ng litrato…', 'Checking photo quality…');
  String get nothingLeavesPhone =>
      _p('Walang litratong umaalis sa telepono', 'No photo leaves this phone');
  String get cameraUnavailable =>
      _p('Walang magamit na kamera', 'No camera available');
  String get modelUnavailable =>
      _p('Hindi gumana ang AI', 'The AI did not start');
  String get phoneOnly => _p(
    'Sa phone app lang gumagana ang pag-scan',
    'Scanning only works in the phone app',
  );
  String get tryAgain => _p('Subukan ulit', 'Try again');
  String get captureFailed => _p(
    'Hindi nakuha ang litrato. Subukan ulit.',
    'Could not take the photo. Try again.',
  );
  String get analysisFailed => _p(
    'Hindi nasuri ang litrato. Subukan ulit.',
    'Could not check the photo. Try again.',
  );

  // ── photo quality ──────────────────────────────────────────────────────
  String get photoRejected =>
      _p('Kunan ulit ang litrato', 'Please take the photo again');
  String get photoRejectedWhy => _p(
    'Hindi ito sinuri ng AI. Mas mabuting kumuha ng bagong litrato kaysa manghula sa malabo.',
    'The AI did not check it. A new photo is better than a guess from a bad one.',
  );
  String get qualityBlur => _p('Malabo ang kuha', 'The photo is blurry');
  String get qualityBlurFix => _p(
    'Hawakan ng dalawang kamay, pindutin ang dumi sa screen para luminaw, at hintayin bago kumuha.',
    'Hold the phone with both hands, tap the dropping on the screen to focus, and wait before taking the photo.',
  );
  String get qualityDark => _p('Masyadong madilim', 'Too dark');
  String get qualityDarkFix => _p(
    'Buksan ang ilaw ng telepono o lumipat sa maliwanag. Sa dilim, kulay lang ang nakikita ng AI.',
    'Turn on the phone light or move to a brighter spot. In the dark the AI only sees colour.',
  );
  String get qualityBright => _p('Sobrang liwanag', 'Too bright');
  String get qualityBrightFix => _p(
    'Iwasan ang tirik na araw. Mas maganda sa lilim o sa maulap na umaga.',
    'Avoid strong sunlight. Shade or a cloudy morning is best.',
  );
  String get qualityFlat => _p('Walang makitang dumi', 'No dropping found');
  String get qualityFlatFix => _p(
    'Lapitan pa ang dumi hanggang mapuno nito ang gitna ng litrato.',
    'Move closer until the dropping fills the middle of the photo.',
  );
  String get qualityOk => _p('Maganda ang kuha', 'Good shot');
  String get photoQuality => _p('Linaw ng litrato', 'Photo quality');
  String get sharpness => _p('Linaw', 'Sharpness');
  String get brightness => _p('Liwanag', 'Brightness');
  String get detail => _p('Detalye', 'Detail');

  // ── result ─────────────────────────────────────────────────────────────
  String get scanResult => _p('RESULTA NG SCAN', 'SCAN RESULT');
  String get certainty => _p('Gaano kasigurado', 'How sure');
  String get needed => _p('Kailangan', 'Needed');
  String get strongMatch => _p('Sigurado', 'Very sure');
  String get likelyMatch => _p('Medyo sigurado', 'Fairly sure');
  String get belowBar => _p('Hindi pa sigurado', 'Not sure yet');
  String get spread => _p('Bilis kumalat', 'How fast it spreads');
  String get riskToPeople => _p('Delikado ba sa tao', 'Risk to people');
  String get requiredByLaw => _p('Utos ng batas', 'The law requires this');
  String get whatThisIs => _p('Ano ito', 'What this is');
  String get whatToLookFor => _p('Ano ang makikita', 'Signs to look for');
  String get first24 => _p('Gawin ngayong araw', 'Do today');
  String get thisWeek => _p('Gawin ngayong linggo', 'Do this week');
  String get neverDo => _p('Huwag gagawin', 'Never do this');
  String get whenToCall =>
      _p('Kailan tatawag sa beterinaryo', 'When to call a vet');
  String get howScored => _p('Mga score ng AI', 'The AI\'s scores');
  String get notADiagnosis => _p(
    'Litrato lang ang tinitingnan ng app. Hindi nito kayang palitan ang beterinaryo.',
    'This app only looks at a photo. It cannot replace a vet.',
  );
  String get analysedHere => _p(
    'Sinuri sa telepono mo — walang internet',
    'Checked on your phone — no internet used',
  );

  // ── naming a scan ──────────────────────────────────────────────────────
  String get nameThisScan =>
      _p('Saang kulungan ito?', 'Which coop is this from?');
  String get coop => _p('Kulungan', 'Coop');
  String get coopHint => _p('hal. Kulungan A', 'e.g. Coop A');
  String get noteHint => _p('hal. pulang inahin', 'e.g. red hen');
  String get note => _p('Paalala', 'Note');
  String get noCoop => _p('Ilagay ang kulungan', 'Add the coop');
  String get editLabels =>
      _p('Palitan ang kulungan at paalala', 'Edit coop and note');
  String get savedToRecords =>
      _p('Naka-save na sa telepono', 'Saved on your phone');

  // ── records ────────────────────────────────────────────────────────────
  String get records => _p('Listahan ng mga Scan', 'Scan Records');
  String get recordsSub => _p(
    'Lahat ng scan mo, nasa telepono lang',
    'All your scans, kept on this phone',
  );
  String get flockHealth => _p('Lagay ng mga manok', 'Your chickens\' health');
  // Short enough for a three-way segmented control on a 360dp screen; the
  // longer "Huling 7 araw" was cut off in Tagalog.
  String get last7 => _p('7 araw', '7 days');
  String get last30 => _p('30 araw', '30 days');
  String get allTime => _p('Lahat', 'All');
  String get healthy => _p('Malusog', 'Healthy');
  String get inconclusive => _p('Kunan ulit', 'Retake');
  String get diseased => _p('May sakit', 'Sick');
  String get all => _p('Lahat', 'All');
  String get searchHint =>
      _p('Hanapin ang kulungan o numero', 'Search coop or number');
  String get noMatches => _p('Walang nahanap', 'Nothing found');
  String get noRecordsYet => _p('Wala pang scan', 'No scans yet');
  String get noRecordsBody => _p(
    'Dito lalabas ang bawat dumi na na-scan mo, para makita agad kung may problema sa mga manok.',
    'Every dropping you scan shows up here, so you can spot a problem with your chickens early.',
  );
  String get savedOffline => _p(
    'Kusang naka-save, kahit walang internet',
    'Saved automatically, even offline',
  );
  String get exportCsv => _p('Kopyahin bilang CSV', 'Copy as CSV');
  String get exportCsvBody => _p(
    'Kokopyahin ang lahat ng scan para mai-paste sa Excel o Google Sheets.',
    'Copies all your scans so you can paste them into Excel or Google Sheets.',
  );
  String get clearRecords => _p('Burahin lahat ng scan', 'Delete all scans');
  String get clearRecordsQ => _p('Burahin lahat?', 'Delete everything?');
  String get clearRecordsBody => _p(
    'Mabubura nang tuluyan ang lahat ng scan sa teleponong ito. Hindi na ito maibabalik.',
    'Every scan on this phone will be deleted for good. This cannot be undone.',
  );
  String get deleteScanQ => _p('Burahin ang scan na ito?', 'Delete this scan?');
  String get deleteScanBody => _p(
    'Mabubura nang tuluyan ang litrato at resulta nito.',
    'Its photo and result will be deleted for good.',
  );
  String get scanDeleted => _p('Nabura ang scan', 'Scan deleted');
  String get recordsDeleted => _p('Nabura lahat ng scan', 'All scans deleted');
  String get today => _p('Ngayon', 'Today');
  String get yesterday => _p('Kahapon', 'Yesterday');
  // ── health summary card ────────────────────────────────────────────────
  /// "in the last 7 days" etc. [days] is null for the all-time view.
  String period(int? days) => days == null
      ? _p('sa lahat ng scan', 'across all your scans')
      : _p('sa huling $days araw', 'in the last $days days');
  String sickFound(int n, int? days) => _p(
    '$n may sakit ${period(days)}',
    '$n sick ${n == 1 ? 'result' : 'results'} ${period(days)}',
  );
  String noSickFound(int? days) => _p(
    'Walang nakitang sakit ${period(days)}',
    'No sickness found ${period(days)}',
  );
  String noScansIn(int? days) => _p(
    'Walang scan ${period(days)}',
    'No scans ${period(days)}',
  );
  String get noClearResults => _p(
    'Wala pang malinaw na resulta — kunan ulit',
    'No clear results yet — take the photos again',
  );
  String needRetake(int n) => _p(
    '$n litrato ang kailangang kunan ulit',
    '$n ${n == 1 ? 'photo needs' : 'photos need'} retaking',
  );
  String lastScanAgo(int days) => _p(
    'Huling scan: $days araw na ang nakaraan',
    'Last scan was $days days ago',
  );
  String get scanNow => _p('Mag-scan na', 'Scan now');
  String get latest => _p('Pinakabago', 'Latest');
  String get tapToFilter =>
      _p('Pindutin para makita', 'Tap to see them');
  String get showing => _p('Ipinapakita', 'Showing');
  String get showAll => _p('Ipakita lahat', 'Show all');
  String get trendBetter => _p('Gumaganda kumpara noon', 'Better than before');
  String get trendWorse => _p('Lumalala kumpara noon', 'Worse than before');
  String get trendSame => _p('Halos pareho lang', 'About the same');
  String get notEnoughData => _p(
    'Mag-scan pa para makita kung gumaganda',
    'Scan more to see if things are improving',
  );

  // ── guide tab ──────────────────────────────────────────────────────────
  String get guideTab => _p('Gabay sa Pag-scan', 'How to Scan');
  String get guideTabSub => _p(
    'Paano kumuha ng magandang litrato, at ano ang ibig sabihin ng bawat resulta.',
    'How to take a good photo, and what each result means.',
  );
  String get photoRules => _p('Para sa magandang litrato', 'For a good photo');
  String get conditionsCovered =>
      _p('Mga sakit na kayang makita', 'Sicknesses it can spot');
  String get conditionsCoveredSub => _p(
    'Tatlong sakit at malusog na dumi lang ang kilala ng AI. Wala nang iba.',
    'The AI only knows three sicknesses and healthy droppings. Nothing else.',
  );
  String get openGuide => _p('Buksan', 'Open');
  String get limitsTitle => _p('Ang hindi nito kaya', 'What it cannot do');
  String get limitsBody => _p(
    'Apat na uri lang ng dumi ang natutunan ng AI. Kapag iba ang kinunan — sahig, pakain, o ang manok mismo — pipili pa rin ito ng isa sa apat. Kaya sinusuri muna ng app ang litrato, at mas mahigpit ito bago sabihing malusog.',
    'The AI only learned four kinds of dropping. If you photograph something else — the floor, the feed, the chicken — it will still pick one of the four. That is why the app checks the photo first, and is stricter before it says healthy.',
  );

  // ── settings ───────────────────────────────────────────────────────────
  String get settings => _p('Settings', 'Settings');
  String get language => _p('Wika', 'Language');
  String get languageNote => _p(
    'Isang wika lang ang gagamitin sa buong app.',
    'The whole app uses one language.',
  );
  String get modelOnPhone => _p('AI sa telepono', 'The AI on your phone');
  String get replayGuide =>
      _p('Panoorin ulit ang gabay', 'Watch the guide again');
  String get resultsItGives =>
      _p('Mga resulta na kaya nito', 'Results it can give');
  String get certaintyNeeded =>
      _p('Gaano dapat kasigurado', 'How sure it must be');
  String get yourData => _p('Ang mga scan mo', 'Your scans');
  String get aboutDataBody => _p(
    'Lahat ng litrato at resulta ay nasa telepono mo lang. Walang ina-upload, walang account, at hindi gumagamit ng load.',
    'Every photo and result stays on your phone. Nothing is uploaded, there is no account, and it uses no mobile data.',
  );
  String get version => _p('Bersyon', 'Version');

  // ── generic ────────────────────────────────────────────────────────────
  String get scans => _p('scan', 'scans');
  String get ofLabel => _p('sa', 'of');

  String countScans(int n) => '$n ${_p('scan', n == 1 ? 'scan' : 'scans')}';
}

/// Holds the chosen language and writes it through to preferences.
class LanguageController extends ChangeNotifier {
  Lang _lang = Lang.tl;

  Lang get lang => _lang;

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(L._prefsKey);
      if (saved == 'en') _lang = Lang.en;
    } catch (_) {
      // Preferences can be unavailable on a fresh install; Tagalog is the
      // default and the app is fully usable without ever saving a choice.
    }
    notifyListeners();
  }

  Future<void> set(Lang value) async {
    if (_lang == value) return;
    _lang = value;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(L._prefsKey, value == Lang.en ? 'en' : 'tl');
    } catch (_) {
      // Not fatal: the choice simply does not survive a restart.
    }
  }
}

/// Puts the current language in the tree so any widget can read copy without
/// being passed it.
class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;

  /// Reads the controller without subscribing — for tap handlers.
  static LanguageController? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}
