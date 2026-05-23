import 'package:flutter/material.dart';
import '../theme.dart';

/// Text painted with the amber accent gradient (used for brand wordmarks).
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradientText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => CG.accentGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
