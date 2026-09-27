import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/tokens.dart';

/// The app's mark: the ChickDetect chicken, on a white tile.
///
/// The artwork is drawn for a light background — its outline is the same dark
/// green as the brand — so it always sits on white, never on the green.
class BrandMark extends StatelessWidget {
  final double size;
  final double radius;

  const BrandMark({super.key, this.size = 38, this.radius = 11});

  /// The whole logo with its wordmark, for the landing screen.
  static const String fullAsset = 'assets/images/logo_full.png';
  static const String markAsset = 'assets/images/logo_mark.png';

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.1),
    decoration: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColor.line),
    ),
    child: Image.asset(
      markAsset,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'ChickDetect',
    ),
  );
}

/// The one place the app states that nothing leaves the phone.
///
/// In the prototype this claim appeared in seven places — the status bar, the
/// header, under the camera, on the records note, on a privacy card, in
/// Settings and at the foot of every report. Saying it once, always visible,
/// is both less noise and more credible.
class OnDeviceBadge extends StatelessWidget {
  const OnDeviceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.mint,
        borderRadius: BorderRadius.circular(Insets.rFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColor.green700,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l.onDevice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.micro.copyWith(color: AppColor.green900),
            ),
          ),
        ],
      ),
    );
  }
}
