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


  /// Show welcome invitation bottom sheet
  static Future<void> _showWelcomeBottomSheet(
    BuildContext context,
    WidgetRef ref,
    WelcomeData welcomeData,
  ) async {
    try {
      final result = await GroupWelcomeInvitationSheet.show(
        context: context,
        welcomeData: welcomeData,
        onAccept: () => _acceptWelcome(ref, welcomeData.id),
        onDecline: () => _declineWelcome(ref, welcomeData.id),
      );

      // If the sheet was dismissed without action (result is null), ignore the welcome
      if (result == null) {
        _logger.info(
          'WelcomeNotificationService: Welcome ${welcomeData.id} dismissed, marking as ignored',
        );
        await _ignoreWelcome(ref, welcomeData.id);
      } else {
        _logger.info(
          'WelcomeNotificationService: Welcome ${welcomeData.id} processed with result: $result',
        );
      }

      // Show next pending welcome after this one is closed
      _showNextWelcome(ref);
    } catch (e) {
      _logger.severe('WelcomeNotificationService: Error showing welcome sheet', e);
      // If there was an error, still ignore the welcome to prevent it from reappearing
      await _ignoreWelcome(ref, welcomeData.id);
      _showNextWelcome(ref);
    }
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

  /// Ignore a welcome invitation (mark as dismissed)
  static Future<void> _ignoreWelcome(WidgetRef ref, String welcomeId) async {
    try {
      final success = await ref.read(welcomesProvider.notifier).ignoreWelcome(welcomeId);
      if (success) {
        _logger.info('WelcomeNotificationService: Successfully ignored welcome $welcomeId');
      } else {
        _logger.warning('WelcomeNotificationService: Failed to ignore welcome $welcomeId');
      }
    } catch (e) {
      _logger.severe('WelcomeNotificationService: Error ignoring welcome $welcomeId', e);
    }
  }

  /// Manually show a welcome invitation
  static Future<void> showWelcomeInvitation(
    BuildContext context,
    WidgetRef ref,
    WelcomeData welcomeData,
  ) async {
    await _showWelcomeBottomSheet(context, ref, welcomeData);
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

  /// Show the next pending welcome if available
  static void _showNextWelcome(WidgetRef ref) {
    // Add a small delay to ensure the current bottom sheet is fully closed
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(welcomesProvider.notifier).showNextPendingWelcome();
    });
  }
}
