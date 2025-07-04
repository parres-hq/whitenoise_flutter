import 'package:intl/intl.dart';

extension TimeagoFormatter on DateTime {
  String timeago() {
    final now = DateTime.now();
    final difference = now.difference(this);

    // <60s = "Now"
    if (difference.inSeconds < 60) {
      return 'Now';
    }

    // 1-59min = "32min" - Relative
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    }

    // 1h - 12h = "4h" - Relative
    if (difference.inHours < 12) {
      return '${difference.inHours}h';
    }

    // Same day >= 12h = "14:30" - Absolute
    if (DateFormat('yyyy-MM-dd').format(this) == DateFormat('yyyy-MM-dd').format(now)) {
      return DateFormat('HH:mm').format(this);
    }

    // >24h = Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    // 2-6 days = "Monday" - Weekday name
    if (difference.inDays >= 2 && difference.inDays <= 6) {
      return DateFormat('EEEE').format(this);
    }

    // >6days = "Jun 10" - Month, Day (if same year) or "Jun 10, 2023" (if different year)
    if (difference.inDays > 6) {
      if (this.year == now.year) {
        return DateFormat('MMM d').format(this);
      } else {
        return DateFormat('MMM d, yyyy').format(this);
      }
    }

    // Fallback (should not reach here)
    if (this.year == now.year) {
      return DateFormat('MMM d').format(this);
    } else {
      return DateFormat('MMM d, yyyy').format(this);
    }
  }
}
