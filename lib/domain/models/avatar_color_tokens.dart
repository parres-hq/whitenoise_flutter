import 'dart:ui';

class AvatarColorToken {
  final String name;
  final Color lightSurface;
  final Color lightBorder;
  final Color lightForeground;
  final Color darkSurface;
  final Color darkBorder;
  final Color darkForeground;

  const AvatarColorToken({
    required this.name,
    required this.lightSurface,
    required this.lightBorder,
    required this.lightForeground,
    required this.darkSurface,
    required this.darkBorder,
    required this.darkForeground,
  });

  Color getSurfaceColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  Color getBorderColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkBorder : lightBorder;
  }

  Color getForegroundColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkForeground : lightForeground;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lightSurface': lightSurface.toARGB32(),
      'lightBorder': lightBorder.toARGB32(),
      'lightForeground': lightForeground.toARGB32(),
      'darkSurface': darkSurface.toARGB32(),
      'darkBorder': darkBorder.toARGB32(),
      'darkForeground': darkForeground.toARGB32(),
    };
  }

  factory AvatarColorToken.fromJson(Map<String, dynamic> json) {
    return AvatarColorToken(
      name: json['name'] as String,
      lightSurface: Color(json['lightSurface'] as int),
      lightBorder: Color(json['lightBorder'] as int),
      lightForeground: Color(json['lightForeground'] as int),
      darkSurface: Color(json['darkSurface'] as int),
      darkBorder: Color(json['darkBorder'] as int),
      darkForeground: Color(json['darkForeground'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarColorToken &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          lightSurface == other.lightSurface &&
          lightBorder == other.lightBorder &&
          lightForeground == other.lightForeground &&
          darkSurface == other.darkSurface &&
          darkBorder == other.darkBorder &&
          darkForeground == other.darkForeground;

  @override
  int get hashCode =>
      name.hashCode ^
      lightSurface.hashCode ^
      lightBorder.hashCode ^
      lightForeground.hashCode ^
      darkSurface.hashCode ^
      darkBorder.hashCode ^
      darkForeground.hashCode;

  @override
  String toString() => 'AvatarColorToken($name)';
}

class AvatarColorTokens {
  static const AvatarColorToken blue = AvatarColorToken(
    name: 'Blue',
    lightSurface: Color(0xFFEFF6FF),
    lightBorder: Color(0xFFBFDBFE),
    lightForeground: Color(0xFF1E3A8A),
    darkSurface: Color(0xFF172554),
    darkBorder: Color(0xFFBFDBFE),
    darkForeground: Color(0xFFEFF6FF),
  );

  static const AvatarColorToken cyan = AvatarColorToken(
    name: 'Cyan',
    lightSurface: Color(0xFFECFEFF),
    lightBorder: Color(0xFFA5F3FC),
    lightForeground: Color(0xFF164E63),
    darkSurface: Color(0xFF083344),
    darkBorder: Color(0xFFA5F3FC),
    darkForeground: Color(0xFFECFEFF),
  );

  static const AvatarColorToken emerald = AvatarColorToken(
    name: 'Emerald',
    lightSurface: Color(0xFFECFDF5),
    lightBorder: Color(0xFFA7F3D0),
    lightForeground: Color(0xFF064E3B),
    darkSurface: Color(0xFF022C22),
    darkBorder: Color(0xFFA7F3D0),
    darkForeground: Color(0xFFECFDF5),
  );

  static const AvatarColorToken fuchsia = AvatarColorToken(
    name: 'Fuchsia',
    lightSurface: Color(0xFFFDF4FF),
    lightBorder: Color(0xFFF5D0FE),
    lightForeground: Color(0xFF701A75),
    darkSurface: Color(0xFF4A044E),
    darkBorder: Color(0xFFF5D0FE),
    darkForeground: Color(0xFFFDF4FF),
  );

  static const AvatarColorToken indigo = AvatarColorToken(
    name: 'Indigo',
    lightSurface: Color(0xFFEEF2FF),
    lightBorder: Color(0xFFC7D2FE),
    lightForeground: Color(0xFF312E81),
    darkSurface: Color(0xFF1E1B4B),
    darkBorder: Color(0xFFC7D2FE),
    darkForeground: Color(0xFFEEF2FF),
  );

  static const AvatarColorToken lime = AvatarColorToken(
    name: 'Lime',
    lightSurface: Color(0xFFF7FEE7),
    lightBorder: Color(0xFFD9F99D),
    lightForeground: Color(0xFF365314),
    darkSurface: Color(0xFF111111),
    darkBorder: Color(0xFFD9F99D),
    darkForeground: Color(0xFFF7FEE7),
  );

  static const AvatarColorToken orange = AvatarColorToken(
    name: 'Orange',
    lightSurface: Color(0xFFFFF7ED),
    lightBorder: Color(0xFFFED7AA),
    lightForeground: Color(0xFF7C2D12),
    darkSurface: Color(0xFF431407),
    darkBorder: Color(0xFFFED7AA),
    darkForeground: Color(0xFFFFF7ED),
  );

  static const AvatarColorToken rose = AvatarColorToken(
    name: 'Rose',
    lightSurface: Color(0xFFFFF1F2),
    lightBorder: Color(0xFFFECDD3),
    lightForeground: Color(0xFF881337),
    darkSurface: Color(0xFF4C0519),
    darkBorder: Color(0xFFFECDD3),
    darkForeground: Color(0xFFFFF1F2),
  );

  static const AvatarColorToken sky = AvatarColorToken(
    name: 'Sky',
    lightSurface: Color(0xFFF0F9FF),
    lightBorder: Color(0xFFBAE6FD),
    lightForeground: Color(0xFF0CA4E6),
    darkSurface: Color(0xFF082F49),
    darkBorder: Color(0xFFBAE6FD),
    darkForeground: Color(0xFFF0F9FF),
  );

  static const AvatarColorToken teal = AvatarColorToken(
    name: 'Teal',
    lightSurface: Color(0xFFF0FDFA),
    lightBorder: Color(0xFF99F6E4),
    lightForeground: Color(0xFF134E4A),
    darkSurface: Color(0xFF042F2E),
    darkBorder: Color(0xFF99F6E4),
    darkForeground: Color(0xFFF0FDFA),
  );

  static const AvatarColorToken violet = AvatarColorToken(
    name: 'Violet',
    lightSurface: Color(0xFFF5F3FF),
    lightBorder: Color(0xFFDDD6FE),
    lightForeground: Color(0xFF4C1D95),
    darkSurface: Color(0xFF2E1065),
    darkBorder: Color(0xFFDDD6FE),
    darkForeground: Color(0xFFF5F3FF),
  );

  static const AvatarColorToken amber = AvatarColorToken(
    name: 'Amber',
    lightSurface: Color(0xFFFFFBEA),
    lightBorder: Color(0xFFFDE68A),
    lightForeground: Color(0xFF78350F),
    darkSurface: Color(0xFF451A03),
    darkBorder: Color(0xFFFDE68A),
    darkForeground: Color(0xFFFFFBEA),
  );

  static const List<AvatarColorToken> all = [
    blue,
    cyan,
    emerald,
    fuchsia,
    indigo,
    lime,
    orange,
    rose,
    sky,
    teal,
    violet,
    amber,
  ];
}
