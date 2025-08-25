import 'package:whitenoise/models/relay_status.dart';

class RelayInfo {
  final String url;
  final bool connected;
  final RelayStatus status;

  const RelayInfo({
    required this.url,
    required this.connected,
    this.status = RelayStatus.disconnected,
  });

  RelayInfo copyWith({
    String? url,
    bool? connected,
    RelayStatus? status,
  }) {
    return RelayInfo(
      url: url ?? this.url,
      connected: connected ?? this.connected,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(covariant RelayInfo other) {
    if (identical(this, other)) return true;

    return other.url == url && other.connected == connected && other.status == status;
  }

  @override
  int get hashCode => url.hashCode ^ connected.hashCode ^ status.hashCode;
}
