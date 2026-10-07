import 'package:flutter/material.dart';

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
