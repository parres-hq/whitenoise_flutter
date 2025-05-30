import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/auth_flow/create_profile_screen.dart';
import 'package:whitenoise/ui/auth_flow/info_screen.dart';
import 'package:whitenoise/ui/auth_flow/key_created_screen.dart';
import 'package:whitenoise/ui/auth_flow/logged_screen.dart';
import 'package:whitenoise/ui/auth_flow/login_screen.dart';
import 'package:whitenoise/ui/auth_flow/welcome_screen.dart';
import 'package:whitenoise/ui/chat/chat_screen.dart';
import 'package:whitenoise/ui/settings/general_settings_screen.dart';
import 'package:whitenoise/ui/settings/profile/edit_profile_screen.dart';
import 'package:whitenoise/ui/settings/network/network_screen.dart';
import 'package:whitenoise/ui/settings/nostr_keys/nostr_keys_screen.dart';
import 'package:whitenoise/ui/settings/wallet/wallet_screen.dart';

import '../domain/dummy_data/dummy_messages.dart';
import '../domain/dummy_data/dummy_contacts.dart';
import 'package:whitenoise/ui/contact_list/chat_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.home,
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.home ||
          state.matchedLocation.startsWith('/onboarding');

      if (!isLoggedIn && !isAuthRoute) {
        return Routes.home;
      }
      if (isLoggedIn && isAuthRoute) {
        return Routes.contacts;
      }
      return null;
    },
    routes: [
      // Auth flow
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(path: 'login', builder: (context, state) => const LoginScreen()),
          GoRoute(
            path: 'onboarding',
            builder: (context, state) => const InfoScreen(),
            routes: [
              GoRoute(path: 'create-profile', builder: (context, state) => const CreateProfileScreen()),
              GoRoute(path: 'key-created', builder: (context, state) => const KeyCreatedScreen()),
              GoRoute(path: 'logged-in', builder: (context, state) => const LoggedInScreen()),
            ],
          ),
        ],
      ),
      // Main application (authenticated routes)
      GoRoute(
        path: Routes.contacts,
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final contactId = state.pathParameters['id']!;
              return Scaffold(body: Center(child: Text('Contact Detail: $contactId')));
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.chats,
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              // final chatId = state.pathParameters['id']!;
              // TODO: Pass chatData via state.extra if needed
              return ChatScreen(contact: marekContact, initialMessages: messages);
            },
          ),
        ],
      ),
      // Settings
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const GeneralSettingsScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => EditProfileScreen(profile: dummyContacts.first),
          ),
          GoRoute(
            path: 'network',
            builder: (context, state) => const NetworkScreen(),
          ),
          GoRoute(
            path: 'keys',
            builder: (context, state) => const NostrKeysScreen(),
          ),
          GoRoute(
            path: 'wallet',
            builder: (context, state) => const WalletScreen(),
          ),
        ],
      ),
    ],
  );
});
