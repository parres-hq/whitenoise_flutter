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
    final int totalMinutes = frequency.inMinutes;
    if (totalMinutes >= 1440 && totalMinutes % 1440 == 0) {
      final int days = totalMinutes ~/ 1440;
      return days == 1 ? '1 day' : '$days days';
    }
    if (totalMinutes >= 60 && totalMinutes % 60 == 0) {
      final int hours = totalMinutes ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return totalMinutes == 1 ? '1 minute' : '$totalMinutes minutes';
  }
}
