import 'conditions.dart';

/// Supportive care for each result, kept apart from the condition facts in
/// conditions.dart so the two can be reviewed separately — this file is the
/// one a vet should read before a release.
///
/// Rules this content follows:
///   * Supportive only. Nothing here treats or cures anything, and the screen
///     says so above it. Where a real treatment exists, the advice is to ask
///     a vet for it.
///   * No doses. Doses depend on the product, the age of the birds and the
///     vet; the advice is to follow the label or the vet.
///   * Plain words, in both languages.
class CarePlan {
  /// Comfort and handling: warmth, quiet, reach.
  final List<Say> supportive;

  /// Vitamins, electrolytes, probiotics — framed as support, never cure.
  final List<Say> supplements;

  /// Food and water.
  final List<Say> foodWater;

  /// Keeping sick birds apart.
  final List<Say> isolation;

  /// What to check, and how often.
  final List<Say> monitoring;

  /// Signs (matched by their English text in [Condition.signs]) that mean
  /// "call a vet now" rather than "keep watching".
  final Set<String> warningSigns;

  const CarePlan({
    this.supportive = const <Say>[],
    this.supplements = const <Say>[],
    this.foodWater = const <Say>[],
    this.isolation = const <Say>[],
    this.monitoring = const <Say>[],
    this.warningSigns = const <String>{},
  });

  bool get isEmpty =>
      supportive.isEmpty &&
      supplements.isEmpty &&
      foodWater.isEmpty &&
      isolation.isEmpty &&
      monitoring.isEmpty;
}

/// When to stop reading and call — true for any result.
const List<Say> kCallNowIf = <Say>[
  Say(
    'Maraming manok ang sabay-sabay na may sintomas',
    'Several chickens show signs at the same time',
  ),
  Say('May biglang namamatay na manok', 'Chickens are dying suddenly'),
  Say(
    'Hirap huminga o humihingal ang manok',
    'A chicken is struggling to breathe or gasping',
  ),
  Say('Mabilis na lumalala ang lagay', 'Things are getting worse quickly'),
  Say(
    'Hinala mong nakakahawang sakit ito',
    'You think it may be a disease that spreads',
  ),
];

CarePlan careFor(String key) => kCare[key] ?? const CarePlan();

const Map<String, CarePlan> kCare = <String, CarePlan>{
  // ─────────────────────────────────────────────────────────────────────
  'healthy': CarePlan(
    supplements: <Say>[
      Say(
        'Karaniwang hindi na kailangan ng dagdag na bitamina kung kumpleto ang '
            'pakain.',
        'Healthy chickens on complete feed usually do not need extra vitamins.',
      ),
      Say(
        'Makakatulong ang bitamina na may electrolytes kapag mainit ang panahon, '
            'bibiyahe, o pagkatapos ng bakuna. Sundin ang nasa label.',
        'Vitamins with electrolytes can help during hot weather, transport or '
            'after vaccination. Follow the label.',
      ),
    ],
    foodWater: <Say>[
      Say(
        'Malinis at sariwang tubig araw-araw',
        'Clean, fresh water every day',
      ),
      Say('Tuyo at hindi inaamag na pakain', 'Dry feed with no mould'),
    ],
    monitoring: <Say>[
      Say('Mag-scan kada ilang araw', 'Scan every few days'),
      Say(
        'Tingnan kung kumakain, umiinom at malikot ang mga manok',
        'Check that your chickens eat, drink and move around normally',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────
  'newcastle': CarePlan(
    supportive: <Say>[
      Say(
        'Panatilihing mainit, tuyo at malayo sa hangin ang may sakit',
        'Keep sick chickens warm, dry and out of drafts',
      ),
      Say(
        'Ilapit ang pakain at tubig para hindi na maglakad nang malayo ang '
            'mahihina',
        'Put food and water close so weak birds do not have to walk far',
      ),
      Say(
        'Bigyan sila ng tahimik at malilim na lugar',
        'Give them a quiet, shaded place',
      ),
    ],
    supplements: <Say>[
      Say(
        'Bitamina para sa manok na may electrolytes sa inuming tubig — tumutulong '
            'itong patuloy silang uminom at kumain. Hindi nito pinapatay ang '
            'virus.',
        'Poultry vitamins with electrolytes in the drinking water help sick '
            'birds keep drinking and eating. They do not kill the virus.',
      ),
      Say(
        'Karaniwang may Vitamin A, D, E at B-complex ang bitamina para sa manok. '
            'Gumamit ng produktong para sa manok at sundin ang label.',
        'Poultry vitamin mixes usually contain vitamins A, D, E and B-complex. '
            'Use a product made for chickens and follow the label.',
      ),
    ],
    foodWater: <Say>[
      Say(
        'Palitan ang tubig kahit dalawang beses isang araw',
        'Change the water at least twice a day',
      ),
      Say(
        'Mas madaling kainin ang pakain na binasa nang kaunti',
        'Feed mixed with a little water is easier for weak birds to eat',
      ),
    ],
    isolation: <Say>[
      Say(
        'Ihiwalay ang may sakit, sa lugar na hindi dadaanan ng hangin papunta sa '
            'malulusog',
        'Keep sick birds in a separate pen, where the wind does not blow toward '
            'healthy birds',
      ),
      Say(
        'Unahin ang malulusog, huli ang may sakit — at magpalit ng bota',
        'Tend healthy birds first and sick birds last — and change boots',
      ),
    ],
    monitoring: <Say>[
      Say(
        'Bilangin ang may sakit at namatay tuwing umaga at gabi, at isulat',
        'Count sick and dead birds every morning and evening, and write it down',
      ),
      Say(
        'Bantayan ang baluktot na leeg, maingay na paghinga at pagbaba ng itlog',
        'Watch for twisted necks, noisy breathing and fewer eggs',
      ),
    ],
    warningSigns: <String>{
      'Sudden deaths with no warning',
      'Twisted neck, tilted head, walking in circles',
      'Gasping, coughing, noisy breathing',
      'Cannot move its wings or legs',
      'Many chickens get sick within days',
    },
  ),

  // ─────────────────────────────────────────────────────────────────────
  'coccidiosis': CarePlan(
    supportive: <Say>[
      Say(
        'Panatilihing mainit at tuyo ang may sakit',
        'Keep sick birds warm and dry',
      ),
      Say(
        'Bawasan ang siksikan para hindi sila ma-stress',
        'Reduce crowding so they are less stressed',
      ),
    ],
    supplements: <Say>[
      Say(
        'Madalas ibinibigay ang Vitamin A at K para makabawi ang bituka at '
            'mapigilan ang pagdurugo. Tanungin ang beterinaryo o agrivet kung '
            'anong produkto.',
        'Vitamins A and K are often given to help the gut recover and to help '
            'with bleeding. Ask your vet or agrivet which product to use.',
      ),
      Say(
        'Electrolytes sa tubig para mapalitan ang tubig na nawala sa pagtatae',
        'Electrolytes in the water help replace fluids lost to diarrhoea',
      ),
      Say(
        'Kung amprolium ang gamot na binigay ng beterinaryo, huwag magdagdag ng '
            'Vitamin B1 (thiamine) habang ginagamot maliban kung sabihin niya — '
            'puwede nitong pahinain ang gamot.',
        'If your vet gives amprolium, do not add extra vitamin B1 (thiamine) '
            'during treatment unless the vet says so — it can weaken the '
            'medicine.',
      ),
      Say(
        'Makakatulong ang probiotics para sa manok pagkatapos ng gamutan',
        'Poultry probiotics can help the gut after treatment ends',
      ),
    ],
    foodWater: <Say>[
      Say(
        'Laging may malinis na tubig na abot-kamay',
        'Keep clean water within easy reach at all times',
      ),
      Say(
        'Huwag ipakain ang basa o inaamag na pakain',
        'Never give wet or mouldy feed',
      ),
    ],
    isolation: <Say>[
      Say(
        'Ilipat ang may sakit sa malinis at tuyong kulungan',
        'Move sick birds to a clean, dry pen',
      ),
      Say('Alisin agad ang basang sapin', 'Remove wet bedding right away'),
    ],
    monitoring: <Say>[
      Say(
        'Tingnan ang dumi araw-araw kung may dugo pa',
        'Check the droppings every day for blood',
      ),
      Say(
        'Bantayan kung kumakain at lumalaki pa ang mga manok',
        'Watch whether the chickens keep eating and growing',
      ),
    ],
    warningSigns: <String>{
      'Blood — bright red, or dark and sticky',
      'More deaths over a few days',
      'Not eating, losing weight',
    },
  ),

  // ─────────────────────────────────────────────────────────────────────
  'salmonella': CarePlan(
    supportive: <Say>[
      Say(
        'Panatilihing mainit ang mga sisiw — gumamit ng brooder o ilaw',
        'Keep chicks warm — use a brooder or a heat lamp',
      ),
      Say(
        'Malinis at tuyong sapin, palitan nang madalas',
        'Clean, dry bedding, changed often',
      ),
    ],
    supplements: <Say>[
      Say(
        'Electrolytes sa tubig para hindi matuyuan ng tubig ang nagtatae',
        'Electrolytes in the water help birds with diarrhoea stay hydrated',
      ),
      Say(
        'Probiotics para sa manok (mabuting bacteria) — puwedeng makatulong sa '
            'bituka, lalo na pagkatapos ng antibiotic. Tanungin ang beterinaryo '
            'kung kailan.',
        'Poultry probiotics (good bacteria) may help the gut, especially after '
            'antibiotics. Ask your vet about the timing.',
      ),
      Say(
        'Makakatulong ang bitamina para sa manok sa paggaling; hindi ito gamot',
        'A poultry vitamin mix can support recovery; it is not a treatment',
      ),
    ],
    foodWater: <Say>[
      Say('Linisin ang inuman araw-araw', 'Clean the drinkers every day'),
      Say(
        'Takpan ang pakain at ilayo sa daga',
        'Keep feed covered and away from rats',
      ),
    ],
    isolation: <Say>[
      Say(
        'Ihiwalay ang may sakit, lalo na sa mga sisiw',
        'Separate sick birds, especially from the chicks',
      ),
      Say(
        'Maghugas ng kamay pagkatapos humawak ng manok, sapin o itlog',
        'Wash your hands after touching chickens, bedding or eggs',
      ),
    ],
    monitoring: <Say>[
      Say(
        'Silipin ang mga sisiw kada ilang oras',
        'Check the chicks every few hours',
      ),
      Say(
        'Bantayan kung may nagtatae o nilalagnat sa bahay',
        'Watch for diarrhoea or fever in anyone at home',
      ),
    ],
    warningSigns: <String>{
      'Most deaths are chicks',
      'Not eating but drinking more than usual',
    },
  ),
};
