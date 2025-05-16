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
}
