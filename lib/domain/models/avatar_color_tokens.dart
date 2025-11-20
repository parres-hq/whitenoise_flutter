import 'dart:ui';

class AvatarColorToken {
  final String name;
  final Color lightSurface;
  final Color darkSurface;
  final Color lightForeground;
  final Color darkForeground;
  final Color lightBorder;
  final Color darkBorder;

  const AvatarColorToken({
    required this.name,
    required this.lightSurface,
    required this.darkSurface,
    required this.lightForeground,
    required this.darkForeground,
    required this.lightBorder,
    required this.darkBorder,
  });

  Color getSurfaceColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  Color getBorderColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  Color getForegroundColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkForeground : lightForeground;

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
    lightSurface: Color(0xffEFF6FF),
    darkSurface: Color(0xff172554),
    lightForeground: Color(0xff1E3A8A),
    darkForeground: Color(0xFFEFF6FF),
    lightBorder: Color(0xFFBFDBFE),
    darkBorder: Color(0xFFBFDBFE),
  );

  static const AvatarColorToken cyan = AvatarColorToken(
    name: 'Cyan',
    lightSurface: Color(0xffECFEFF),
    darkSurface: Color(0xFF083344),
    lightForeground: Color(0xFF164E63),
    darkForeground: Color(0xFFECFEFF),
    lightBorder: Color(0xFFA5F3FC),
    darkBorder: Color(0xFFA5F3FC),
  );

  static const AvatarColorToken emerald = AvatarColorToken(
    name: 'Emerald',
    lightSurface: Color(0xFFECFDF5),
    darkSurface: Color(0xFF022C22),
    lightForeground: Color(0xFF064E3B),
    darkForeground: Color(0xFFECFDF5),
    lightBorder: Color(0xFFA7F3D0),
    darkBorder: Color(0xFFA7F3D0),
  );

  static const AvatarColorToken fuchsia = AvatarColorToken(
    name: 'Fuchsia',
    lightSurface: Color(0xFFFDF4FF),
    darkSurface: Color(0xFF4A044E),
    lightForeground: Color(0xFF701A75),
    darkForeground: Color(0xFFFDF4FF),
    lightBorder: Color(0xFFF5D0FE),
    darkBorder: Color(0xFFF5D0FE),
  );

  static const AvatarColorToken indigo = AvatarColorToken(
    name: 'Indigo',
    lightSurface: Color(0xFFEEF2FF),
    darkSurface: Color(0xFF1E1B4B),
    lightForeground: Color(0xFF312E81),
    darkForeground: Color(0xFFEEF2FF),
    lightBorder: Color(0xFFC7D2FE),
    darkBorder: Color(0xFFC7D2FE),
  );

  static const AvatarColorToken lime = AvatarColorToken(
    name: 'Lime',
    lightSurface: Color(0xFFF7FEE7),
    darkSurface: Color(0xFF111111),
    lightForeground: Color(0xFF365314),
    darkForeground: Color(0xFFF7FEE7),
    lightBorder: Color(0xFFD9F99D),
    darkBorder: Color(0xFFD9F99D),
  );

  static const AvatarColorToken orange = AvatarColorToken(
    name: 'Orange',
    lightSurface: Color(0xFFFFF7ED),
    darkSurface: Color(0xFF431407),
    lightForeground: Color(0xFF7C2D12),
    darkForeground: Color(0xFFFFF7ED),
    lightBorder: Color(0xFFFED7AA),
    darkBorder: Color(0xFFFED7AA),
  );

  static const AvatarColorToken rose = AvatarColorToken(
    name: 'Rose',
    lightSurface: Color(0xFFFFF1F2),
    darkSurface: Color(0xFF4C0519),
    lightForeground: Color(0xFF881337),
    darkForeground: Color(0xFFFFF1F2),
    lightBorder: Color(0xFFFECDD3),
    darkBorder: Color(0xFFFECDD3),
  );

  static const AvatarColorToken sky = AvatarColorToken(
    name: 'Sky',
    lightSurface: Color(0xFFF0F9FF),
    darkSurface: Color(0xFF082F49),
    lightForeground: Color(0xFF0CA4E6),
    darkForeground: Color(0xFFF0F9FF),
    lightBorder: Color(0xFFBAE6FD),
    darkBorder: Color(0xFFBAE6FD),
  );

  static const AvatarColorToken teal = AvatarColorToken(
    name: 'Teal',
    lightSurface: Color(0xFFF0FDFA),
    darkSurface: Color(0xFF042F2E),
    lightForeground: Color(0xFF134E4A),
    darkForeground: Color(0xFFF0FDFA),
    lightBorder: Color(0xFF99F6E4),
    darkBorder: Color(0xFF99F6E4),
  );

  static const AvatarColorToken violet = AvatarColorToken(
    name: 'Violet',
    lightSurface: Color(0xFFF5F3FF),
    darkSurface: Color(0xFF2E1065),
    lightForeground: Color(0xFF4C1D95),
    darkForeground: Color(0xFFF5F3FF),
    lightBorder: Color(0xFFDDD6FE),
    darkBorder: Color(0xFFDDD6FE),
  );

  static const AvatarColorToken amber = AvatarColorToken(
    name: 'Amber',
    lightSurface: Color(0xFFFFFBEA),
    darkSurface: Color(0xFF451A03),
    lightForeground: Color(0xFF78350F),
    darkForeground: Color(0xFFFFFBEA),
    lightBorder: Color(0xFFFDE68A),
    darkBorder: Color(0xFFFDE68A),
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
