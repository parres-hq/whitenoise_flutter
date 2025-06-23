extension StringExtensions on String {
  /// Formats the public key by adding a space every 5 characters
  String formatPublicKey() {
    return replaceAllMapped(
      RegExp(r'.{5}'),
      (match) => '${match.group(0)} ',
    );
  }
}
