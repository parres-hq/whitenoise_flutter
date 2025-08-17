class MenuItem {
  final String label;
  final String assetPath;
  final bool isDestructive;

  // contsructor
  const MenuItem({
    required this.label,
    required this.assetPath,
    this.isDestructive = false,
  });
}
