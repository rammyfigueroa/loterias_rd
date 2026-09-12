import 'package:flutter/material.dart';

/// Asset based brand logo for Sorteos Dominicanos.
///
/// [forDarkBackground] uses the white-text version that reads better on
/// the blue header. The standard version is useful on light backgrounds.
class BrandLogo extends StatelessWidget {
  final double height;
  final bool forDarkBackground;
  final BoxFit fit;

  const BrandLogo({
    super.key,
    this.height = 44,
    this.forDarkBackground = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      forDarkBackground
          ? 'assets/branding/sorteos_dominicanos_header.png'
          : 'assets/branding/sorteos_dominicanos_horizontal.png',
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}
