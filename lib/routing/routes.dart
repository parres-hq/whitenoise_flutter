import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const home = '/';
  // Auth
  static const login = '/login';

  // Chats
  static const chats = '/chats';
  static const chat = '/chats/:id';
  static const newChat = '/chats/new';

  // Contacts
  static const contacts = '/contacts';
  static const contact = '/contacts/:id';

  // Settings
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsNetwork = '/settings/network';
  static const settingsKeys = '/settings/keys';
  static const settingsWallet = '/settings/wallet';

  static void goToChat(BuildContext context, String chatId) {
    GoRouter.of(context).go('/chats/$chatId');
  }

  static void goToContact(BuildContext context, String contactId) {
    GoRouter.of(context).go('/contacts/$contactId');
  }

  static void goToOnboarding(BuildContext context) {
    GoRouter.of(context).go('/onboarding');
  }
}
