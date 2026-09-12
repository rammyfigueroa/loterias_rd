import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Lottery icon widget for Sorteos Dominicanos.
///
/// Put the PNG logo files in:
/// assets/branding/lotteries/
///
/// Required filenames:
/// - lottery_nacional.png
/// - lottery_leidsa.png
/// - lottery_real.png
/// - lottery_loteka.png
/// - lottery_americanas.png
/// - lottery_new_york.png
/// - lottery_la_primera.png
/// - lottery_la_suerte.png
/// - lottery_lotedom.png
/// - lottery_anguila.png
/// - lottery_king_lottery.png
///
/// If an asset is missing, the app will not crash. It will use a fallback icon.
class LotteryIcon extends StatelessWidget {
  final String lotteryName;
  final double size;
  final Color? color;

  const LotteryIcon({
    super.key,
    required this.lotteryName,
    this.size = 36,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPathFor(lotteryName);

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallbackIcon(context),
      );
    }

    return _fallbackIcon(context);
  }

  Widget _fallbackIcon(BuildContext context) {
    final name = _normalize(lotteryName);

    // Use dynamic here because font_awesome_flutter 11 uses FaIconData,
    // while Flutter's native Icon uses IconData. FaIcon expects FaIconData.
    dynamic icon;

    if (name.contains('nacional')) {
      icon = FontAwesomeIcons.flag;
    } else if (name.contains('leidsa')) {
      icon = FontAwesomeIcons.dice;
    } else if (name.contains('real')) {
      icon = FontAwesomeIcons.ticket;
    } else if (name.contains('loteka')) {
      icon = FontAwesomeIcons.circleDot;
    } else if (name.contains('americana') ||
        name.contains('florida') ||
        name.contains('mega') ||
        name.contains('powerball')) {
      icon = FontAwesomeIcons.star;
    } else if (name.contains('new york') || name.contains('nueva york')) {
      icon = FontAwesomeIcons.city;
    } else if (name.contains('primera')) {
      icon = FontAwesomeIcons.one;
    } else if (name.contains('suerte')) {
      icon = FontAwesomeIcons.clover;
    } else if (name.contains('lotedom')) {
      icon = FontAwesomeIcons.bolt;
    } else if (name.contains('anguila')) {
      icon = FontAwesomeIcons.water;
    } else if (name.contains('king')) {
      icon = FontAwesomeIcons.crown;
    } else {
      icon = FontAwesomeIcons.ticket;
    }

    return FaIcon(
      icon,
      size: size,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }

  String? _assetPathFor(String name) {
    final lower = _normalize(name);

    if (lower.contains('nacional')) {
      return 'assets/branding/lotteries/lottery_nacional.png';
    }

    if (lower.contains('leidsa') ||
        lower.contains('kino') ||
        lower.contains('loto - leidsa') ||
        lower.contains('quiniela leidsa')) {
      return 'assets/branding/lotteries/lottery_leidsa.png';
    }

    if (lower.contains('loteria real') ||
        lower.contains('lotería real') ||
        lower.contains('quiniela real') ||
        lower.contains('loto real') ||
        lower == 'real') {
      return 'assets/branding/lotteries/lottery_real.png';
    }

    if (lower.contains('loteka') || lower.contains('mega chances')) {
      return 'assets/branding/lotteries/lottery_loteka.png';
    }

    if (lower.contains('americana') ||
        lower.contains('florida') ||
        lower.contains('mega millions') ||
        lower.contains('powerball')) {
      return 'assets/branding/lotteries/lottery_americanas.png';
    }

    if (lower.contains('new york') || lower.contains('nueva york')) {
      return 'assets/branding/lotteries/lottery_new_york.png';
    }

    if (lower.contains('primera') || lower.contains('loto 5')) {
      return 'assets/branding/lotteries/lottery_la_primera.png';
    }

    if (lower.contains('suerte')) {
      return 'assets/branding/lotteries/lottery_la_suerte.png';
    }

    if (lower.contains('lotedom') || lower.contains('quemaito')) {
      return 'assets/branding/lotteries/lottery_lotedom.png';
    }

    if (lower.contains('anguila')) {
      return 'assets/branding/lotteries/lottery_anguila.png';
    }

    if (lower.contains('king')) {
      return 'assets/branding/lotteries/lottery_king_lottery.png';
    }

    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }
}
