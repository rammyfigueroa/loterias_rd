import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/lottery_result.dart';
import 'result_share_text.dart';

Future<void> shareLotteryResult(
  BuildContext context,
  LotteryResult result,
) async {
  try {
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    await SharePlus.instance.share(
      ShareParams(
        text: buildResultShareText(result),
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Share result failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('No se pudo compartir el resultado. Inténtalo nuevamente.'),
      ),
    );
  }
}
