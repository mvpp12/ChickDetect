import '../core/strings.dart';

/// One string in both languages.
class Say {
  final String tl;
  final String en;

  const Say(this.tl, this.en);

  String call(Lang lang) => lang == Lang.tl ? tl : en;
}

/// A numbered instruction and the reason behind it.
///
/// The reason is not padding. "Stop all movement" on its own gets ignored;
/// "nothing leaves the farm, this is the most important step" gets followed.
class ActionStep {
  final Say title;
  final Say why;

  const ActionStep(this.title, this.why);
}

/// Signs grouped by where they are seen.
class SignGroup {
  final Say where;
  final List<Say> items;

  const SignGroup(this.where, this.items);
}

enum Severity { none, watch, high }

class Condition {
  final String key;
  final Say name;
  final Say headline;
  final Say detail;
  final Say? spread;
  final Say? zoonotic;

  /// Legal duty, where one exists. Its own block, because not reporting a
  /// disease the law says must be reported is a legal matter, not advice.
  final Say? law;

  final List<SignGroup> signs;
  final List<ActionStep> firstDay;
  final List<ActionStep> thisWeek;
  final List<Say> neverDo;
  final Say escalate;
  final Severity severity;
  final bool isHealthy;

  const Condition({
    required this.key,
    required this.name,
    required this.headline,
    required this.detail,
    required this.signs,
    required this.firstDay,
    required this.thisWeek,
    required this.escalate,
    required this.severity,
    this.spread,
    this.zoonotic,
    this.law,
    this.neverDo = const <Say>[],
    this.isHealthy = false,
  });
}

/// Everything the app knows, in one table.
///
/// General poultry-health guidance for Philippine smallholders, written in
/// the words a farmer would use out loud — in both languages. Formal Tagalog
/// (kawan, paglaganap, katiyakan) and technical English (notifiable, urate,
/// coccidiostat) were swapped for everyday words, because advice that has to
/// be decoded is advice that does not get followed.
///
/// Every entry ends by pointing at a vet: this app looks at a photo, it does
/// not examine an animal.
const Map<String, Condition> kConditions = <String, Condition>{
  // ─────────────────────────────────────────────────────────────────────
  'healthy': Condition(
    key: 'healthy',
    isHealthy: true,
    severity: Severity.none,
    name: Say('Malusog', 'Healthy'),
    headline: Say(
      'Walang nakitang problema sa dumi na ito',
      'Nothing wrong found in this dropping',
    ),
    detail: Say(
      'Mukhang normal ang dumi: buo at hindi malabnaw, may puti sa ibabaw, '
          'walang dugo, sipon o kakaibang kulay. Tandaan: isang dumi lang ito, '
          'hindi lahat ng manok mo.',
      'This dropping looks normal: firm, with a white cap on top, and no '
          'blood, slime or strange colour. Remember, this is one dropping, not '
          'all of your chickens.',
    ),
    signs: <SignGroup>[
      SignGroup(Say('Sa dumi', 'In the droppings'), <Say>[
        Say('Buo at hindi malabnaw', 'Firm and holds its shape'),
        Say('May puti sa ibabaw', 'White cap on top'),
        Say(
          'Kulay kayumanggi hanggang maitim na berde, depende sa pakain',
          'Brown to dark green, depending on the feed',
        ),
      ]),
      SignGroup(Say('Sa manok', 'In the chicken'), <Say>[
        Say('Malikot at nakatayo nang tuwid', 'Active and standing tall'),
        Say('Matingkad na pula ang palong', 'Bright red comb'),
        Say('Normal kumain at uminom', 'Eating and drinking normally'),
      ]),
    ],
    firstDay: <ActionStep>[],
    thisWeek: <ActionStep>[
      ActionStep(
        Say('Ituloy lang ang pag-scan', 'Keep scanning'),
        Say(
          'Mag-scan kada ilang araw, lalo na kapag nagpalit ng pakain, '
              'pagkatapos ng malakas na ulan, o may bagong manok.',
          'Scan every few days, especially after changing feed, after heavy '
              'rain, or when new chickens arrive.',
        ),
      ),
      ActionStep(
        Say('Panatilihing tuyo ang sahig', 'Keep the floor dry'),
        Say(
          'Ang basang sahig ang madalas pagmulan ng sakit. Sa tag-ulan, '
              'palitan nang mas madalas ang sapin sa ilalim ng inuman.',
          'A wet floor is where sickness usually starts. In the rainy season, '
              'change the bedding under the drinkers more often.',
        ),
      ),
      ActionStep(
        Say(
          'Bantayan din ang manok, hindi lang ang dumi',
          'Watch the chicken, not just the dropping',
        ),
        Say(
          'Kahit malinis ang scan, puwede pa ring may sakit. Tingnan kung '
              'kumakain, paano tumayo, at kung may kakaibang tunog sa gabi.',
          'A clean scan does not mean no sickness. Check if they eat, how they '
              'stand, and any strange sounds at night.',
        ),
      ),
    ],
    escalate: Say(
      'Kung mukhang may sakit ang manok kahit malinis ang scan, paniwalaan ang '
          'nakikita mo at tumawag sa beterinaryo.',
      'If your chickens look sick even with clean scans, trust your eyes and '
          'call a vet.',
    ),
  ),

  // ─────────────────────────────────────────────────────────────────────
  'newcastle': Condition(
    key: 'newcastle',
    severity: Severity.high,
    name: Say('Newcastle Disease', 'Newcastle Disease'),
    headline: Say(
      'Kailangang i-report sa munisipyo',
      'Must be reported to your local government',
    ),
    detail: Say(
      'Isang virus na kumakalat sa dumi, hangin, maruming gamit, sapatos at '
          'ligaw na ibon. Kaya nitong patayin ang halos lahat ng manok na hindi '
          'nabakunahan, madalas sa loob lang ng isang linggo. Walang gamot — '
          'ang panlaban lang ay ihiwalay ang may sakit at magpabakuna.',
      'A virus that spreads through droppings, the air, dirty tools, shoes and '
          'wild birds. It can kill most chickens that are not vaccinated, often '
          'within a week. There is no cure — you fight it by separating sick '
          'birds and vaccinating.',
    ),
    spread: Say(
      'Napakabilis — 2 hanggang 5 araw sa lahat ng manok',
      'Very fast — 2 to 5 days to reach all your chickens',
    ),
    zoonotic: Say(
      'Kaunti — puwedeng mangati ang mata ng humahawak',
      'Low — it can irritate the eyes of people handling them',
    ),
    law: Say(
      'Sa Pilipinas, dapat i-report ang Newcastle Disease. Tumawag sa '
          'Municipal o City Agriculture Office, sa Provincial Veterinarian, o sa '
          'Bureau of Animal Industry. Kapag maaga kang nag-report, napipigilan '
          'ang pagkalat at puwede kang makakuha ng tulong mula sa gobyerno.',
      'In the Philippines, Newcastle Disease must be reported. Call your '
          'Municipal or City Agriculture Office, the Provincial Veterinarian, '
          'or the Bureau of Animal Industry. Reporting early stops the spread '
          'and can get you help from the government.',
    ),
    signs: <SignGroup>[
      SignGroup(Say('Sa dumi', 'In the droppings'), <Say>[
        Say(
          'Matingkad na berde o berdeng-dilaw, matubig',
          'Bright green or yellow-green, watery',
        ),
        Say('Minsan may kasamang dugo', 'Sometimes with blood'),
      ]),
      SignGroup(Say('Sa manok', 'In the chicken'), <Say>[
        Say(
          'Baluktot ang leeg, nakatagilid ang ulo, umiikot',
          'Twisted neck, tilted head, walking in circles',
        ),
        Say('Hindi maigalaw ang pakpak o paa', 'Cannot move its wings or legs'),
        Say(
          'Hinihingal, umuubo, maingay ang paghinga',
          'Gasping, coughing, noisy breathing',
        ),
        Say(
          'Namamaga ang paligid ng mata at leeg',
          'Swelling around the eyes and neck',
        ),
      ]),
      SignGroup(Say('Sa lahat ng manok', 'Across your chickens'), <Say>[
        Say(
          'Biglang namamatay kahit walang senyales',
          'Sudden deaths with no warning',
        ),
        Say(
          'Kaunti na lang ang itlog; malambot o pangit ang balat',
          'Far fewer eggs; soft or odd-shaped shells',
        ),
        Say(
          'Maraming manok ang nagkakasakit sa loob ng ilang araw',
          'Many chickens get sick within days',
        ),
      ]),
    ],
    firstDay: <ActionStep>[
      ActionStep(
        Say('Walang ilalabas sa farm', 'Nothing leaves the farm'),
        Say(
          'Walang manok, itlog, dumi, kahon o gamit ang ilalabas. Ito ang '
              'pinakamahalagang hakbang, at ito rin ang madalas makalimutan.',
          'No chickens, eggs, droppings, crates or tools leave. This is the '
              'most important step, and the one people most often forget.',
        ),
      ),
      ActionStep(
        Say('Ihiwalay ang may sakit', 'Separate the sick chickens'),
        Say(
          'Ilayo sila, sa lugar na hindi dadaanan ng hangin papunta sa ibang '
              'manok. Sariling pakainan, inuman at gamit — huwag ipahiram.',
          'Move them far away, where the wind will not blow toward the others. '
              'Give them their own feeder, drinker and tools — do not share.',
        ),
      ),
      ActionStep(
        Say('I-report ngayong araw', 'Report it today'),
        Say(
          'Tumawag sa agriculture office ng munisipyo, sa provincial '
              'veterinarian, o sa Bureau of Animal Industry. Hindi ka '
              'pinaparusahan; ito ang tamang proseso.',
          'Call your town\'s agriculture office, the provincial vet, or the '
              'Bureau of Animal Industry. You are not in trouble; this is the '
              'normal process.',
        ),
      ),
      ActionStep(
        Say('Magpalit ng sapatos at damit', 'Change shoes and clothes'),
        Say(
          'Tuwing lilipat ka mula sa kulungan ng may sakit papunta sa iba. Sa '
              'maliliit na farm, kadalasang sa bota dumadala ang sakit.',
          'Every time you go from the sick pen to the rest of the farm. On '
              'small farms, sickness is mostly carried on boots.',
        ),
      ),
    ],
    thisWeek: <ActionStep>[
      ActionStep(
        Say(
          'Maglinis at mag-disinfect nang maayos',
          'Clean and disinfect well',
        ),
        Say(
          'Ilang linggong nabubuhay ang virus sa dumi at gamit. Kuskusin muna '
              'ang dumi, saka gumamit ng disinfectant mula sa agrivet. Hindi '
              'sapat ang tubig lang.',
          'The virus lives for weeks in droppings and on tools. Scrub the dirt '
              'off first, then use a disinfectant from the agrivet store. Water '
              'alone is not enough.',
        ),
      ),
      ActionStep(
        Say(
          'Itapon nang tama ang patay na manok',
          'Get rid of dead chickens properly',
        ),
        Say(
          'Sunugin o ibaon nang malalim, malayo sa tubig at sa ibang manok. '
              'Huwag ibenta, kainin o ipakain sa hayop.',
          'Burn them or bury them deep, away from water and other chickens. '
              'Never sell them, eat them or feed them to animals.',
        ),
      ),
      ActionStep(
        Say(
          'Magtanong sa beterinaryo tungkol sa bakuna',
          'Ask a vet about vaccines',
        ),
        Say(
          'Ang bakuna ang proteksiyon ng mga natitirang manok. Ang beterinaryo '
              'ang dapat magsabi kung kailan at anong bakuna.',
          'Vaccines protect the chickens you still have. A vet should decide '
              'which vaccine and when.',
        ),
      ),
      ActionStep(
        Say('Harangan ang ligaw na ibon', 'Keep wild birds out'),
        Say(
          'Lagyan ng lambat ang mga butas. Madalas bumabalik ang virus dahil sa '
              'ligaw na ibon.',
          'Cover openings with net. Wild birds are the usual reason the virus '
              'comes back.',
        ),
      ),
    ],
    neverDo: <Say>[
      Say(
        'Huwag ibenta o ipamigay ang manok para hindi malugi — ganito kumakalat '
            'ang sakit sa ibang farm.',
        'Do not sell or give away chickens to save money — that is how the '
            'sickness reaches other farms.',
      ),
      Say(
        'Huwag gamitan ng antibiotic. Virus ito; walang epekto ang antibiotic at '
            'naaantala lang ang tamang gawin.',
        'Do not use antibiotics. This is a virus; antibiotics do nothing and '
            'only delay the right steps.',
      ),
      Say(
        'Huwag ilipat ang manok sa "malinis" na lugar na pareho ang tao, gamit o '
            'hangin.',
        'Do not move chickens to a "clean" area that shares the same people, '
            'tools or air.',
      ),
    ],
    escalate: Say(
      'Tumawag ngayong araw, huwag nang hintayin ang Lunes. Kapag maaga, '
          'napipigilan ang pagkalat.',
      'Call today — do not wait until after the weekend. Acting early stops '
          'the spread.',
    ),
  ),

  // ─────────────────────────────────────────────────────────────────────
  'coccidiosis': Condition(
    key: 'coccidiosis',
    severity: Severity.high,
    name: Say('Coccidiosis', 'Coccidiosis'),
    headline: Say(
      'May gamot — kailangang kumilos agad',
      'Treatable — act fast',
    ),
    detail: Say(
      'Isang parasite na sumisira sa bituka, madalas sa manok na 3 hanggang 8 '
          'linggo ang edad. Dumarami ito sa mainit at basang sahig, kaya '
          'pinakamalala tuwing tag-ulan. Kapag naagapan, gumagaling; kapag '
          'pinabayaan, hindi lumalaki ang manok at puwedeng mamatay.',
      'A parasite that damages the gut, usually in chickens 3 to 8 weeks old. '
          'It grows in warm, wet bedding, so it is worst in the rainy season. '
          'Caught early, chickens recover; left alone, they stop growing and '
          'can die.',
    ),
    spread: Say('Mabilis kapag basa ang sahig', 'Fast when the floor is wet'),
    signs: <SignGroup>[
      SignGroup(Say('Sa dumi', 'In the droppings'), <Say>[
        Say(
          'May dugo — matingkad na pula, o maitim at malagkit',
          'Blood — bright red, or dark and sticky',
        ),
        Say(
          'May sipon, o parang kulay-kahel na balat',
          'Slime, or orange-brown bits of gut lining',
        ),
        Say('Malabnaw at matubig', 'Runny and watery'),
      ]),
      SignGroup(Say('Sa manok', 'In the chicken'), <Say>[
        Say('Maputla ang palong at paa', 'Pale comb and legs'),
        Say(
          'Nakayuko, gusot ang balahibo, ayaw gumalaw',
          'Hunched, fluffed-up feathers, does not want to move',
        ),
        Say('Walang gana, pumapayat', 'Not eating, losing weight'),
      ]),
      SignGroup(Say('Sa lahat ng manok', 'Across your chickens'), <Say>[
        Say(
          'Hindi na lumalaki ang magkakasing-edad na manok',
          'Chickens of the same age stop growing',
        ),
        Say(
          'Dumarami ang namamatay sa loob ng ilang araw',
          'More deaths over a few days',
        ),
      ]),
    ],
    firstDay: <ActionStep>[
      ActionStep(
        Say(
          'Ilipat sa malinis at tuyong sahig',
          'Move them to a clean, dry floor',
        ),
        Say(
          'Kailangan ng parasite ang basa para kumalat. Ang tuyong sahig ang '
              'pinakamabilis na pampahinto — mas mabilis pa sa gamot.',
          'The parasite needs wet ground to spread. A dry floor stops it '
              'fastest — even faster than medicine.',
        ),
      ),
      ActionStep(
        Say('Ayusin ang pinanggagalingan ng basa', 'Fix what is making it wet'),
        Say(
          'Tumutulong inuman, pumapasok na ulan, baradong kanal. Kung hindi '
              'maaayos, babalik at babalik ang sakit kahit ilang gamot pa.',
          'Leaking drinkers, rain coming in, blocked drains. If you do not fix '
              'this, it keeps coming back no matter how much medicine you use.',
        ),
      ),
      ActionStep(
        Say(
          'Tanungin ang beterinaryo kung anong gamot',
          'Ask a vet which medicine to use',
        ),
        Say(
          'May gamot ito, pero ang tamang gamot at dami ay depende sa edad ng '
              'manok.',
          'It can be treated, but the right medicine and amount depend on the '
              'age of the chickens.',
        ),
      ),
      ActionStep(
        Say('Ilapit ang malinis na tubig', 'Put clean water close by'),
        Say(
          'Mabilis mauhaw ang may sakit, at ang mahihina ay hindi na '
              'naglalakad papunta sa inuman.',
          'Sick chickens dry out fast, and weak ones stop walking to the '
              'drinker.',
        ),
      ),
    ],
    thisWeek: <ActionStep>[
      ActionStep(
        Say('Huwag siksikan', 'Give them more space'),
        Say(
          'Kapag siksikan, mas dumarami ang parasite. Bigyan sila ng mas '
              'maluwag na lugar kung kaya.',
          'Crowding makes the parasite worse. Give the chickens more room if '
              'you can.',
        ),
      ),
      ActionStep(
        Say(
          'Linisin at patuyuin bago ang susunod na batch',
          'Clean and dry before the next batch',
        ),
        Say(
          'Ilang buwang nabubuhay ang itlog ng parasite sa sahig. Alisin lahat '
              'ng lumang sapin, linisin, at patuyuin bago pumasok ang bagong '
              'manok.',
          'The parasite\'s eggs live in the bedding for months. Remove all old '
              'bedding, clean, and let it dry before new chickens come in.',
        ),
      ),
      ActionStep(
        Say('Bantayan ang susunod na batch', 'Watch the next batch closely'),
        Say(
          'Parehong edad, parehong kulungan — babalik ito kung walang '
              'binago.',
          'Same age, same coop — it will come back if nothing changes.',
        ),
      ),
      ActionStep(
        Say('Magtanong kung paano ito maiiwasan', 'Ask how to prevent it'),
        Say(
          'May pakain na may halong gamot, at may bakuna. Ang beterinaryo ang '
              'makakapagsabi kung alin ang bagay sa iyo.',
          'There is feed with medicine mixed in, and there are vaccines. A vet '
              'can tell you which one suits you.',
        ),
      ),
    ],
    neverDo: <Say>[
      Say(
        'Huwag patungan ng bagong sapin ang basang sapin — lalo itong babasa at '
            'lalala.',
        'Do not put new bedding on top of wet bedding — it keeps the wet in '
            'and makes it worse.',
      ),
      Say(
        'Huwag itigil ang gamot kahit mukhang magaling na. Tapusin ang bilin ng '
            'beterinaryo.',
        'Do not stop the medicine early even if they look better. Finish what '
            'the vet told you.',
      ),
      Say(
        'Huwag agad isipin na coccidiosis ang lahat ng may dugo — may iba pang '
            'dahilan na alam ng beterinaryo.',
        'Do not assume every bloody dropping is coccidiosis — a vet can check '
            'for other causes.',
      ),
    ],
    escalate: Say(
      'Tumawag agad kapag may dugo sa dumi. Kapag maaga ang gamot, mas kaunti '
          'ang malulugi.',
      'Call as soon as you see blood. Early treatment means smaller losses.',
    ),
  ),

  // ─────────────────────────────────────────────────────────────────────
  'salmonella': Condition(
    key: 'salmonella',
    severity: Severity.high,
    name: Say('Salmonella', 'Salmonella'),
    headline: Say(
      'Puwedeng mahawa ang manok at ang tao',
      'Can make both chickens and people sick',
    ),
    detail: Say(
      'Sakit na dala ng bacteria mula sa maruming pakain, tubig at sahig, at '
          'ikinakalat ng daga. Pinakadelikado sa sisiw. Madalas, ang malalaking '
          'manok ay may dala nito kahit mukhang malusog — kaya umaabot ito sa '
          'itlog at sa pagkain natin.',
      'A sickness caused by bacteria in dirty feed, water and bedding, spread '
          'by rats and mice. Chicks suffer the most. Grown chickens often carry '
          'it while looking fine — which is how it reaches eggs and our food.',
    ),
    spread: Say(
      'Katamtaman — sa pakain, tubig at sahig',
      'Medium — through feed, water and bedding',
    ),
    zoonotic: Say(
      'Oo — puwedeng magdulot ng food poisoning sa tao',
      'Yes — it can give people food poisoning',
    ),
    signs: <SignGroup>[
      SignGroup(Say('Sa dumi', 'In the droppings'), <Say>[
        Say('Puti, matubig o mabula', 'White, watery or foamy'),
        Say('Minsan dumidikit sa puwit', 'Sometimes stuck around the bottom'),
      ]),
      SignGroup(Say('Sa manok', 'In the chicken'), <Say>[
        Say(
          'Nagsisiksikan sa mainit, gusot ang balahibo',
          'Crowding near warmth, fluffed-up feathers, droopy wings',
        ),
        Say(
          'Ayaw kumain pero madalas uminom',
          'Not eating but drinking more than usual',
        ),
        Say('Mabagal lumaki ang sisiw', 'Chicks grow slowly'),
      ]),
      SignGroup(Say('Sa lahat ng manok', 'Across your chickens'), <Say>[
        Say('Sisiw ang kadalasang namamatay', 'Most deaths are chicks'),
        Say(
          'May mga mukhang normal pero nakakahawa pa rin',
          'Some look normal but still spread it',
        ),
      ]),
    ],
    firstDay: <ActionStep>[
      ActionStep(
        Say('Ihiwalay ang may sakit', 'Separate the sick chickens'),
        Say(
          'Lalo na ilayo sa mga sisiw — sila ang pinakamadaling mamatay.',
          'Keep them away from the chicks most of all — chicks are the most '
              'likely to die.',
        ),
      ),
      ActionStep(
        Say(
          'Linisin at palitan ang tubig sa inuman',
          'Clean and refill the drinkers',
        ),
        Say(
          'Kuskusin, i-disinfect, at lagyan ng malinis na tubig. Ang maruming '
              'tubig ang paulit-ulit na nagpapasakit sa mga manok.',
          'Scrub, disinfect and refill with clean water. Dirty water keeps '
              'making the chickens sick again.',
        ),
      ),
      ActionStep(
        Say('Maghugas nang maayos ng kamay', 'Wash your hands well'),
        Say(
          'Sabon at tubig pagkatapos humawak ng manok, sapin o itlog. Huwag '
              'humawak ng pagkain bago maghugas. Para ito sa kalusugan mo.',
          'Use soap and water after touching chickens, bedding or eggs. Do not '
              'touch food before washing. This protects you.',
        ),
      ),
      ActionStep(
        Say('Itabi muna ang itlog', 'Set the eggs aside'),
        Say(
          'Huwag ibenta o kainin ang itlog ng may sakit hangga\'t hindi pa '
              'sinasabi ng beterinaryo na ligtas.',
          'Do not sell or eat eggs from sick chickens until a vet says they are '
              'safe.',
        ),
      ),
    ],
    thisWeek: <ActionStep>[
      ActionStep(
        Say('Palitan ang basa at maruming sapin', 'Replace wet, dirty bedding'),
        Say(
          'Ang tuyong sahig ang pinakamalaking tulong. Ayusin din agad ang '
              'tumutulong inuman.',
          'A dry floor helps the most. Fix leaking drinkers the same day.',
        ),
      ),
      ActionStep(
        Say('Puksain ang daga', 'Get rid of rats and mice'),
        Say(
          'Daga ang pangunahing nagdadala nito. Takpan ang pinagtataguan nila, '
              'walisin ang natapong pakain, at isara nang mabuti ang lalagyan.',
          'Rats and mice are the main carriers. Block where they hide, sweep up '
              'spilled feed, and keep feed tightly closed.',
        ),
      ),
      ActionStep(
        Say('Tingnan ang pakain', 'Check the feed'),
        Say(
          'Madalas nagsisimula ito sa marumi o inaamag na pakain. Tanungin ang '
              'pinagbilhan at tingnan ang petsa.',
          'It often starts from dirty or mouldy feed. Ask the seller and check '
              'the date on the bag.',
        ),
      ),
      ActionStep(
        Say(
          'Magtanong muna sa beterinaryo bago magpagamot',
          'Ask a vet before giving medicine',
        ),
        Say(
          'Puwedeng kailangan ng antibiotic — pero may araw na dapat hintayin '
              'bago puwedeng ibenta ang karne at itlog. Ang maling gamot ay '
              'nakakasama pa.',
          'Antibiotics may be needed — but you must wait some days before '
              'selling meat and eggs. The wrong medicine can do harm.',
        ),
      ),
    ],
    neverDo: <Say>[
      Say(
        'Huwag bumili ng antibiotic nang walang reseta. May araw na dapat '
            'hintayin bago puwedeng ibenta ang karne at itlog.',
        'Do not buy antibiotics without a vet\'s advice. You must wait some '
            'days before selling meat or eggs.',
      ),
      Say(
        'Huwag pahawakan sa bata ang may sakit na manok o palinisin sila ng '
            'kulungan.',
        'Do not let children touch sick chickens or clean the coop.',
      ),
      Say(
        'Huwag maghugas ng gamit kung saan dadaloy ang tubig papunta sa inuman.',
        'Do not wash tools where the water flows into the drinking water.',
      ),
    ],
    escalate: Say(
      'Tumawag sa beterinaryo kung may namamatay na sisiw, o kung may '
          'nagtatae at nilalagnat sa bahay pagkatapos humawak ng manok.',
      'Call a vet if chicks are dying, or if anyone at home gets diarrhoea and '
          'fever after handling the chickens.',
    ),
  ),

  // ─────────────────────────────────────────────────────────────────────
  // Named for what to do next, not for what the app could not do. "No clear
  // answer" read as the app failing; "take another photo" is an action. The
  // state itself stays: it is what stops a low-confidence guess being shown
  // as a result.
  'inconclusive': Condition(
    key: 'inconclusive',
    severity: Severity.watch,
    name: Say('Kunan ulit ang litrato', 'Take another photo'),
    headline: Say(
      'Kailangan ng mas malinaw na kuha para makasiguro',
      'A clearer photo is needed to be sure',
    ),
    detail: Say(
      'Hindi pa sapat na malinaw ang resulta sa litratong ito. Tungkol ito sa '
          'litrato, hindi sa manok — puwedeng malusog ang manok mo, puwede ring '
          'hindi. Mas malinaw na kuha ang kailangan para malaman.',
      'The result for this photo is not clear enough yet. This is about the photo, '
          'not the chicken — your chicken may be healthy or it may not. A '
          'clearer photo is what it needs to tell.',
    ),
    signs: <SignGroup>[],
    firstDay: <ActionStep>[
      ActionStep(
        Say('Kunan sa maliwanag na lugar', 'Use good light'),
        Say(
          'Sa lilim o sa maulap na umaga. Parehong nakakasira ang tirik na araw '
              'at madilim na anino.',
          'Shade or a cloudy morning is best. Strong sun and dark shadows both '
              'spoil the photo.',
        ),
      ),
      ActionStep(
        Say('Isang sariwang dumi lang', 'Just one fresh dropping'),
        Say(
          'Isang dumi lang, punuin ang litrato, huwag isama ang sahig at paa.',
          'One dropping only, fill the photo, keep the floor and feet out.',
        ),
      ),
      ActionStep(
        Say('Hawakan nang steady', 'Hold the phone steady'),
        Say(
          'Mga 10–15 cm ang layo. Pindutin ang dumi sa screen para luminaw at '
              'hintayin bago kumuha.',
          'About 10–15 cm away. Tap the dropping on the screen to focus and '
              'wait before taking the photo.',
        ),
      ),
    ],
    thisWeek: <ActionStep>[],
    escalate: Say(
      'Kung paulit-ulit na kailangang kunan ulit at mukhang may sakit ang mga '
          'manok, huwag nang maghintay — tumawag sa beterinaryo. Mas '
          'mapagkakatiwalaan ang nakikita mo.',
      'If you keep being asked to retake and your chickens look sick, do not '
          'wait — call a vet. What you can see matters more.',
    ),
  ),
};

Condition conditionFor(String? key) =>
    kConditions[(key ?? '').trim().toLowerCase()] ??
    kConditions['inconclusive']!;

/// The three the model can actually name, for the guide.
const List<String> kNamedConditions = <String>[
  'newcastle',
  'coccidiosis',
  'salmonella',
];
