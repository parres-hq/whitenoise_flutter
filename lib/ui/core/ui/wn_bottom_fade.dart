import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnBottomFade extends StatelessWidget {
  const WnBottomFade({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.neutral.withValues(alpha: 0),
              context.colors.neutral,
            ],
          ),
        ),
      ),
    );
  }
}
