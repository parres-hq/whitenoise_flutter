import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';

enum RelayStatus {
  initialized('Initialized'),
  pending('Pending'),
  connecting('Connecting'),
  connected('Connected'),
  disconnected('Disconnected'),
  terminated('Terminated'),
  banned('Banned'),
  sleeping('Sleeping');

  const RelayStatus(this.value);

  final String value;

  static RelayStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'initialized':
        return RelayStatus.initialized;
      case 'pending':
        return RelayStatus.pending;
      case 'connecting':
        return RelayStatus.connecting;
      case 'connected':
        return RelayStatus.connected;
      case 'disconnected':
        return RelayStatus.disconnected;
      case 'terminated':
        return RelayStatus.terminated;
      case 'banned':
        return RelayStatus.banned;
      case 'sleeping':
        return RelayStatus.sleeping;
      default:
        return RelayStatus.disconnected;
    }
  }

  @override
  String toString() => value;

  bool get isConnected => this == RelayStatus.connected;
}

extension RelayStatusExt on RelayStatus {
  Color getColor(BuildContext context) {
    switch (this) {
      case RelayStatus.connected:
        return context.colors.success;
      case RelayStatus.connecting:
        return context.colors.warning;
      case RelayStatus.pending:
        return context.colors.warning;
      case RelayStatus.initialized:
        return context.colors.primary;
      case RelayStatus.disconnected:
        return context.colors.destructive;
      case RelayStatus.terminated:
        return context.colors.destructive;
      case RelayStatus.banned:
        return context.colors.destructive;
      case RelayStatus.sleeping:
        return context.colors.mutedForeground.withValues(alpha: 0.6);
    }
  }

  String getIconAsset() {
    switch (this) {
      case RelayStatus.connected:
        return AssetsPaths.icCheckmarkFilledSvg;
      case RelayStatus.connecting:
        return AssetsPaths.icInProgress;
      case RelayStatus.pending:
        return AssetsPaths.icIconsTime;
      case RelayStatus.initialized:
        return AssetsPaths.icRadioButton;
      case RelayStatus.disconnected:
        return AssetsPaths.icErrorFilled;
      case RelayStatus.terminated:
        return AssetsPaths.icErrorFilled;
      case RelayStatus.banned:
        return AssetsPaths.icLocked;
      case RelayStatus.sleeping:
        return AssetsPaths.icMoon;
    }
  }
}
