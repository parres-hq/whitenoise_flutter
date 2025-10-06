class BackgroundTaskConfig {
  final String id;
  final String uniqueName;
  final String displayName;
  final Duration frequency;

  const BackgroundTaskConfig({
    required this.id,
    required this.uniqueName,
    required this.displayName,
    required this.frequency,
  });

  String get frequencyDisplay {
    if (frequency.inHours >= 24) {
      final days = frequency.inHours ~/ 24;
      return days == 1 ? '24 hours' : '$days days';
    } else if (frequency.inHours > 0) {
      final hours = frequency.inHours;
      return hours == 1 ? '1 hour' : '$hours hours';
    } else {
      final minutes = frequency.inMinutes;
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }
  }
}
