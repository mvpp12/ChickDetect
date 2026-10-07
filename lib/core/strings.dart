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
  String get doThis => _p('Gawin', 'Do');
  String get avoidThis => _p('Iwasan', 'Avoid');
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
    'Sa telepono mismo sinusuri ang litrato, ilang segundo lang. Titingnan muna '
        'ng app kung malinaw ito. Kapag malabo o madilim, sasabihin nito agad.',
    'The photo is checked right on your phone in a few seconds. The app first '
        'makes sure it is clear. If it is blurry or dark, it tells you straight away.',
  );

  String get flow3Title =>
      _p('Resulta at ang dapat gawin', 'The result, and what to do');
  String get flow3Body => _p(
    'Malusog, may sakit, o kailangang kunan ulit — kasama ang unang dapat gawin. Naka-save ang bawat scan sa telepono, para makita mo kung gumaganda o lumalala ang lagay ng mga manok mo.',
    'Healthy, sick, or take another photo — with the first thing to do. Every scan is saved on your phone, so you can see if your chickens are getting better or worse.',
  );

  String get rule1Title => _p('Sariwang dumi', 'Fresh droppings');
  String get rule1Body => _p(
    'Kunan sa loob ng 10 hanggang 20 minuto matapos lumabas. Nag-iiba ang kulay '
        'at hugis ng tuyong dumi, kaya puwedeng magkamali ang resulta.',
    'Take it within 10 to 20 minutes after it comes out. Dry droppings change '
        'colour and shape, which can make the result wrong.',
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
      _p('Hindi gumana ang pagsusuri', 'The checker did not start');
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
    'Hindi pa ito sinuri. Kailangan ng malinaw na litrato para sa tamang resulta.',
    'It was not checked yet. A clear photo is needed for a reliable result.',
  );
  String get qualityBlur => _p('Malabo ang kuha', 'The photo is blurry');
  String get qualityBlurFix => _p(
    'Hawakan ng dalawang kamay, pindutin ang dumi sa screen para luminaw, at hintayin bago kumuha.',
    'Hold the phone with both hands, tap the dropping on the screen to focus, and wait before taking the photo.',
  );
  String get qualityDark => _p('Masyadong madilim', 'Too dark');
  String get qualityDarkFix => _p(
    'Buksan ang ilaw ng telepono o lumipat sa maliwanag. Sa dilim, kulay lang ang '
        'nakikita sa litrato.',
    'Turn on the phone light or move to a brighter spot. In the dark only colour '
        'shows in the photo.',
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
  String get howScored => _p('Mga iskor', 'The scores');
  String get notADiagnosis => _p(
    'Tumutulong ang ChickDetect sa maagang pagtuklas; ang beterinaryo pa rin '
        'ang magkukumpirma.',
    'ChickDetect helps with early detection; a vet makes the final call.',
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
  String get recordsSub => _p('Lahat ng scan mo', 'All your scans');
  String get longPressHint => _p(
    'Pindutin nang matagal ang isang scan para pumili at magbura.',
    'Long-press a scan to select and delete.',
  );
  String selectedCount(int n) => _p('$n napili', '$n selected');
  String get selectAll => _p('Piliin lahat', 'Select all');
  String get selectNone => _p('Alisin lahat', 'Deselect all');
  String deleteSelectedQ(int n) =>
      _p('Burahin ang $n scan?', 'Delete $n ${n == 1 ? 'scan' : 'scans'}?');
  String get deleteSelectedBody => _p(
    'Mabubura nang tuluyan ang mga napiling scan at ang mga litrato nito.',
    'The selected scans and their photos will be deleted for good.',
  );
  String deletedCount(int n) =>
      _p('Nabura ang $n scan', '$n ${n == 1 ? 'scan' : 'scans'} deleted');

  // ── welcome (first launch) ─────────────────────────────────────────────
  String get welcomeHeadline => _p('I-scan ang dumi.', 'Scan the droppings.');
  String get welcomeSubhead =>
      _p('Makita agad ang sakit.', 'Spot sickness early.');
  String get welcomeStart => _p('Simulan', 'Get started');
  String get welcomeNote =>
      _p('Hindi kailangan ng internet', 'No internet needed');
  String get notDroppingTitle => _p(
    'Hindi ito mukhang dumi ng manok',
    'This does not look like a chicken dropping',
  );
  String get notDroppingBody => _p(
    'Itutok ang camera sa isang sariwang dumi, mga 10 hanggang 15 cm ang layo, '
        'para mapuno nito ang gitna ng litrato.',
    'Point the camera at one fresh dropping, about 10 to 15 cm away, so it '
        'fills the middle of the photo.',
  );
  String get notSavedRetake => _p(
    'Hindi ito nai-save sa listahan. Kumuha ng mas malinaw na litrato para '
        'sa resulta.',
    'This was not saved to your records. Take a clearer photo to get a '
        'result.',
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
  String noScansIn(int? days) =>
      _p('Walang scan ${period(days)}', 'No scans ${period(days)}');
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
  String get tapToFilter => _p('Pindutin para makita', 'Tap to see them');
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
    'Tatlong sakit at malusog na dumi ang kayang makita ng ChickDetect.',
    'ChickDetect can spot three sicknesses and healthy droppings.',
  );
  String get openGuide => _p('Buksan', 'Open');
  String get limitsTitle => _p('Ang hindi nito kaya', 'What it cannot do');
  String get limitsBody => _p(
    'Apat na uri ng dumi ang natutunan ng ChickDetect, at natuto rin itong '
        'makilala kung hindi dumi ang kinunan. Mas mahigpit pa rin ito bago '
        'sabihing malusog. Hindi pa nito nasubukan ang lahat ng uri ng sahig at '
        'pakain sa mga bukid dito, kaya bantayan pa rin ang mga manok.',
    'ChickDetect learned four kinds of dropping, and it also learned to tell '
        'when a photo is not a dropping. It is still stricter before it says '
        'healthy. It has not yet seen every kind of bedding and feed used on '
        'local farms, so keep watching your chickens too.',
  );

  // ── settings ───────────────────────────────────────────────────────────
  String get settings => _p('Settings', 'Settings');
  String get language => _p('Wika', 'Language');
  String get languageNote => _p(
    'Isang wika lang ang gagamitin sa buong app.',
    'The whole app uses one language.',
  );
  String get modelOnPhone =>
      _p('Pagsusuri sa telepono', 'Checking on your phone');
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

  // ── scan details: tabs ─────────────────────────────────────────────────
  String get tabOverview => _p('Buod', 'Overview');
  String get tabAnalysis => _p('Pagsusuri', 'Analysis');
  String get tabCare => _p('Payo', 'Advice');
  String get tabVet => _p('Beterinaryo', 'Vet');

  // overview
  String get statusLabel => _p('Lagay', 'Status');
  String get scannedOn => _p('Na-scan', 'Scanned');
  String get chickenAndCoop => _p('Manok at kulungan', 'Chicken and coop');
  String get whatNext => _p('Susunod na titingnan', 'What to check next');
  String get quickWhy => _p('Bakit ito ang resulta?', 'Why this result?');
  String get quickDo => _p('Ano ang dapat gawin', 'What to do');
  String get quickVet =>
      _p('Kailan tatawag sa beterinaryo', 'When to call a vet');

  // AI analysis
  String get aiScore => _p('Iskor', 'Score');
  String whyTitle(String name) => _p('Bakit $name?', 'Why $name?');
  String get whyIntro => _p(
    'Tinitingnan ng ChickDetect ang buong litrato at binibigyan ng iskor ang '
        'bawat posibleng resulta. Narito ang mga nasukat para maintindihan mo '
        'ang resulta.',
    'ChickDetect looks at the whole photo and gives each possible result a '
        'score. Here is what was measured, so you can understand the result.',
  );
  String get howCompared =>
      _p('Paghahambing ng apat na resulta', 'How the four results compared');
  String lead(int points) => _p(
    'Lamang ng $points puntos sa kasunod na sagot',
    '$points points ahead of the next answer',
  );
  String get leadClear => _p(
    'Malinaw ang lamang — isang resulta lang ang tumugma nang husto.',
    'A clear lead — one result stood out from the rest.',
  );
  String get leadNarrow => _p(
    'Maliit ang lamang — magkalapit ang dalawang resulta, kaya bantayang mabuti.',
    'A narrow lead — two results were close, so keep a close watch.',
  );
  String get coloursTitle =>
      _p('Mga kulay sa gitna ng litrato', 'Colours in the middle of the photo');
  String get coloursNote => _p(
    'Sinukat mula sa litrato. Ihambing sa karaniwang itsura sa ibaba.',
    'Measured from the photo. Compare it with the typical look below.',
  );
  String typicalFor(String name) =>
      _p('Karaniwang dumi kapag $name', 'Typical droppings with $name');
  String colourName(String family) => switch (family) {
    'green' => _p('Berde', 'Green'),
    'brown' => _p('Kayumanggi o maitim', 'Brown or dark'),
    'white' => _p('Puti', 'White'),
    'red' => _p('Pula', 'Red'),
    _ => _p('Dilaw', 'Yellow'),
  };
  String get focusTitle =>
      _p('Saang bahagi nakatuon ang pagsusuri', 'Where the check focused');
  String get focusBody => _p(
    'Tinatakpan ng app ang bawat bahagi ng litrato, isa-isa, at tinitingnan '
        'kung gaano bumababa ang score. Mas matingkad = mas mahalaga sa sagot.',
    'The app covers each part of the photo in turn and checks how much the '
        'score drops. Brighter = mattered more to the answer.',
  );
  String get focusButton => _p('Ipakita', 'Show me');
  String get focusWorking =>
      _p('Sinusuri ang bawat bahagi…', 'Checking each part…');
  String get focusPhoneOnly =>
      _p('Sa phone app lang ito gumagana', 'This only works in the phone app');
  String get focusNone => _p(
    'Walang bahaging mas mahalaga kaysa sa iba.',
    'No single part mattered more than the rest.',
  );
  String get noPhotoSaved =>
      _p('Walang naka-save na litrato', 'No photo saved');
  String get pleaseNote => _p('Paalala', 'Please note');
  String get aiDisclaimer => _p(
    'Paunang pagsusuri ang ChickDetect para matulungan kang makita agad ang '
        'posibleng sakit. Hindi nito pinapalitan ang pagsusuri ng beterinaryo — '
        'ipakumpirma sa kanila, lalo na kung nakakahawang sakit.',
    'ChickDetect is a preliminary check that helps you spot possible disease '
        'early. It does not replace a veterinarian\'s findings — have a vet '
        'confirm it, especially for a disease that spreads.',
  );

  // confirming the answer
  String get confirmTitle =>
      _p('Tingnan ang manok para makumpirma', 'Check your chickens to confirm');
  String get confirmNote => _p(
    'Kung nakikita mo ang mga ito sa manok, mas malamang na tama ang resulta. '
        'Ang may "Babala" ay dahilan para tumawag agad sa beterinaryo.',
    'If you can see these in your chickens, the result is more likely right. '
        'Anything marked "Warning sign" means call a vet right away.',
  );
  String get warningSign => _p('Babala', 'Warning sign');

  // recommendations
  String get careTitle => _p('Mga payo sa kalusugan', 'Health recommendations');
  String get careDisclaimer => _p(
    'Pangsuporta lang ang mga ito — hindi gamot o lunas, at hindi pamalit sa '
        'beterinaryo.',
    'These support your chickens\' health. They are not a treatment or a '
        'cure, and they do not replace a vet.',
  );
  String get careSupportive => _p('Pag-aalaga', 'Supportive care');
  String get careSupplements =>
      _p('Bitamina at supplement', 'Vitamins and supplements');
  String get careFood => _p('Pagkain at tubig', 'Food and water');
  String get careIsolation => _p('Paghihiwalay', 'Keeping sick birds apart');
  String get careMonitoring => _p('Ano ang babantayan', 'What to watch');

  // vet care
  String get callNowTitle =>
      _p('Tumawag agad sa beterinaryo kung:', 'Call a vet right away if:');
  String get forThisResult => _p('Para sa resultang ito', 'For this result');
  String get needHelp => _p('Kailangan ng tulong?', 'Need help?');
  String get contactVet => _p('Beterinaryo', 'Veterinarian');
  String get contactPoultry =>
      _p('Espesyalista sa manok', 'Poultry specialist');
  String get contactOffice =>
      _p('Opisina ng agrikultura o beterinaryo', 'Agriculture or vet office');
  String callWho(String who) => _p('Tawagan: $who', 'Call $who');
  String get addNumber => _p('Idagdag ang numero', 'Add number');
  String get editNumbers => _p('Baguhin ang mga numero', 'Edit numbers');
  String get contactsTitle => _p('Mga numero ng tulong', 'Vet contacts');
  String get contactsNote => _p(
    'I-save ang numero ng beterinaryo at opisina malapit sa inyo. Nasa '
        'telepono lang ito.',
    'Save the numbers of the vet and office near you. They stay on this '
        'phone.',
  );
  String get contactsEmpty =>
      _p('Wala pang naka-save na numero', 'No numbers saved yet');
  String get nameOptional => _p('Pangalan (opsyonal)', 'Name (optional)');
  String get phoneNumber => _p('Numero ng telepono', 'Phone number');
  String get callFailed =>
      _p('Hindi mabuksan ang tawag', 'Could not open the phone dialer');

  // photo
  String get tapToZoom =>
      _p('Pindutin para makita nang buo', 'Tap to view full screen');

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
