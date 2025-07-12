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

  // Contacts
  static const contacts = '/contacts';
  static const contact = '/contacts/:id';

  // Settings
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsNetwork = '/settings/network';
  static const settingsKeys = '/settings/keys';
  static const settingsWallet = '/settings/wallet';
  static const settingsDeveloper = '/settings/developer';
  static const settingsAppSettings = '/settings/app_settings';
  static const settingsDonate = '/settings/donate';
  static const settingsShareProfile = '/settings/share_profile';

  static void goToChat(BuildContext context, String chatId, {String? inviteId}) {
    GoRouter.of(context).go('/chats/$chatId', extra: inviteId);
  }

  static void goToContact(BuildContext context, String contactId) {
    GoRouter.of(context).go('/contacts/$contactId');
  }

  static void goToOnboarding(BuildContext context) {
    GoRouter.of(context).go('/onboarding');
  }
}
