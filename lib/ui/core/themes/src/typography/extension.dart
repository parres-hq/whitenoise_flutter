part of 'typography.dart';

class TypographyThemeExt extends ThemeExtension<TypographyThemeExt> {
  const TypographyThemeExt({
    required this.labelLargeB,
    required this.labelMediumB,
    required this.labelSmallB,
  });

  final TextStyle labelLargeB;
  final TextStyle labelMediumB;
  final TextStyle labelSmallB;

  @override
  ThemeExtension<TypographyThemeExt> copyWith({
    TextStyle? labelLargeB,
    TextStyle? labelMediumB,
    TextStyle? labelSmallB,
  }) {
    return TypographyThemeExt(
      labelLargeB: labelLargeB ?? this.labelLargeB,
      labelMediumB: labelMediumB ?? this.labelMediumB,
      labelSmallB: labelSmallB ?? this.labelSmallB,
    );
  }

  @override
  ThemeExtension<TypographyThemeExt> lerp(
      covariant TypographyThemeExt? other, double t) {
    if (other == null) return this;
    return TypographyThemeExt(
      labelLargeB: TextStyle.lerp(labelLargeB, other.labelLargeB, t)!,
      labelMediumB: TextStyle.lerp(labelMediumB, other.labelMediumB, t)!,
      labelSmallB: TextStyle.lerp(labelSmallB, other.labelSmallB, t)!,
    );
  }
}
