import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_content.freezed.dart';

@freezed
class NotificationContent with _$NotificationContent {
  const factory NotificationContent({
    required String title,
    required String body,
    required String groupKey,
    required Map<String, dynamic> payload,
  }) = _NotificationContent;
}
