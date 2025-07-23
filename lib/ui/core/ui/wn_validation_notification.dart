import 'package:flutter/widgets.dart';

class WnValidationNotification extends Notification {
  WnValidationNotification(this.hash, this.valid);
  final int hash;
  final bool valid;

  @override
  String toString() {
    return 'WnValidationNotification($hash, $valid)';
  }
}
