import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/contact_list/group_welcome_invitation_sheet.dart';

class WelcomeNotificationService {
  static final _logger = Logger('WelcomeNotificationService');
  static BuildContext? _currentContext;

  /// Initialize the service with a build context
  static void initialize(BuildContext context) {
    _currentContext = context;
  }

  /// Set up the callback for new welcome notifications
  /// NOTE: Automatic bottom sheet notifications are disabled as welcomes now show in the chat list
  static void setupWelcomeNotifications(WidgetRef ref) {
    // Welcomes are now integrated into the chat list, so we don't need automatic popups
    // ref
    //     .read(welcomesProvider.notifier)
    //     .setOnNewWelcomeCallback(
    //       (welcomeData) => _handleNewWelcome(ref, welcomeData),
    //     );
  }

  /// Clear the welcome notifications callback
  static void clearWelcomeNotifications(WidgetRef ref) {
    ref.read(welcomesProvider.notifier).clearOnNewWelcomeCallback();
  }

  /// Accept a welcome invitation
  static Future<void> _acceptWelcome(WidgetRef ref, String welcomeId) async {
    try {
      final success = await ref.read(welcomesProvider.notifier).acceptWelcomeInvitation(welcomeId);
      await ref.read(groupsProvider.notifier).loadGroups();
      if (success) {
        _logger.info('WelcomeNotificationService: Successfully accepted welcome $welcomeId');
      } else {
        _logger.warning('WelcomeNotificationService: Failed to accept welcome $welcomeId');
      }
    } catch (e) {
      _logger.severe('WelcomeNotificationService: Error accepting welcome $welcomeId', e);
    }
  }

  /// Decline a welcome invitation
  static Future<void> _declineWelcome(WidgetRef ref, String welcomeId) async {
    try {
      final success = await ref.read(welcomesProvider.notifier).declineWelcomeInvitation(welcomeId);
      if (success) {
        _logger.info('WelcomeNotificationService: Successfully declined welcome $welcomeId');
      } else {
        _logger.warning('WelcomeNotificationService: Failed to decline welcome $welcomeId');
      }
    } catch (e) {
      _logger.severe('WelcomeNotificationService: Error declining welcome $welcomeId', e);
    }
  }

  /// Update the context (useful for navigation changes)
  static void updateContext(BuildContext context) {
    _currentContext = context;
  }

  /// Clear the stored context
  static void clearContext() {
    _currentContext = null;
  }

  /// Get current context (for testing)
  static BuildContext? get currentContext => _currentContext;
}
