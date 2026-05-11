import 'package:flutter/material.dart';

/// Tamaños disponibles del patrón decorativo "greca" zapoteca.
enum GrecaSize { micro, small, medium }

/// Divisor decorativo horizontal que renderiza un PNG de greca repetido.
///
/// Se usa como separador rítmico entre secciones para reforzar la identidad
/// visual "Alebrije Night". No introduce funcionalidad — solo estética.
class GrecaDivider extends StatelessWidget {
  final GrecaSize size;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final Color? tint;

  const GrecaDivider({
    super.key,
    this.size = GrecaSize.small,
    this.opacity = 1.0,
    this.padding = EdgeInsets.zero,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final asset = switch (size) {
      GrecaSize.micro => 'assets/grecas/greca_micro_pattern.png',
      GrecaSize.small => 'assets/grecas/greca_small_pattern.png',
      GrecaSize.medium => 'assets/grecas/greca_medium_pattern.png',
    };
    final h = switch (size) {
      GrecaSize.micro => 8.0,
      GrecaSize.small => 14.0,
      GrecaSize.medium => 22.0,
    };

    return Padding(
      padding: padding,
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          height: h,
          width: double.infinity,
          child: Image.asset(
            asset,
            fit: BoxFit.none,
            repeat: ImageRepeat.repeatX,
            color: tint,
            colorBlendMode: tint == null ? null : BlendMode.srcIn,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }
}
