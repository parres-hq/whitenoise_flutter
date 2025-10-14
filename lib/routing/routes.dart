import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const home = '/';
  // Auth
  static const login = '/login';
  static const createProfile = '/create-profile';

  // Chats
  static const chats = '/chats';
  static const chat = '/chats/:id';
  static const newChat = '/chats/new';
  static const chatInfo = '/chats/:id/info';
  static const editGroup = '/chats/:id/info/edit';

  // Users
  static const users = '/users';
  static const user = '/users/:id';

  // Settings
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsNetwork = '/settings/network';
  static const settingsNetworkMonitor = '/settings/network/monitor';
  static const settingsKeys = '/settings/keys';
  static const settingsWallet = '/settings/wallet';
  static const settingsDeveloper = '/settings/developer';
  static const settingsAppSettings = '/settings/app_settings';
  static const settingsDonate = '/settings/donate';
  static const settingsShareProfile = '/settings/share_profile';
  static const settingsShareProfileQrScan = '/settings/share_profile/qr_scan';
  static const userProfileQrScan = '/user_profiles/qr_scan';

  // misc
  static const addUserToGroup = '/add_to_group/:id';

  static void goToChat(BuildContext context, String chatId, {String? inviteId}) {
    GoRouter.of(context).go('/chats/$chatId', extra: inviteId);
  }

  static void goToUser(BuildContext context, String userId) {
    GoRouter.of(context).go('/users/$userId');
  }

  static void goToOnboarding(BuildContext context) {
    GoRouter.of(context).go('/onboarding');
  }

  static void goToEditGroup(BuildContext context, String groupId) {
    GoRouter.of(context).push('/chats/$groupId/info/edit');
  }
}
