import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/auth_flow/create_profile_screen.dart';
import 'package:whitenoise/ui/auth_flow/info_screen.dart';
import 'package:whitenoise/ui/auth_flow/login_screen.dart';
import 'package:whitenoise/ui/auth_flow/welcome_screen.dart';
import 'package:whitenoise/ui/chat/chat_screen.dart';
import 'package:whitenoise/ui/contact_list/chat_list_screen.dart';
import 'package:whitenoise/ui/settings/developer/dev.dart';
import 'package:whitenoise/ui/settings/general_settings_screen.dart';
import 'package:whitenoise/ui/settings/network/network_screen.dart';
import 'package:whitenoise/ui/settings/nostr_keys/nostr_keys_screen.dart';
import 'package:whitenoise/ui/settings/profile/edit_profile_screen.dart';
import 'package:whitenoise/ui/settings/wallet/wallet_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.home,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentLocation = state.uri.path;

      // If user is authenticated and trying to access welcome/login pages,
      // redirect to chats
      if (authState.isAuthenticated && !authState.isLoading) {
        if (currentLocation == Routes.home || currentLocation == Routes.login) {
          return Routes.chats;
        }
      }

      // If user is not authenticated and trying to access protected routes,
      // redirect to home
      if (!authState.isAuthenticated && !authState.isLoading) {
        final protectedRoutes = [Routes.chats, Routes.contacts, Routes.settings];
        if (protectedRoutes.any((route) => currentLocation.startsWith(route))) {
          return Routes.home;
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'onboarding',
            builder: (context, state) => const InfoScreen(),
            routes: [
              GoRoute(
                path: 'create-profile',
                builder: (context, state) => const CreateProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: Routes.contacts,
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final contactId = state.pathParameters['id']!;
              return Scaffold(
                body: Center(child: Text('Contact Detail: $contactId')),
              );
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
              final groupId = state.pathParameters['id']!;
              return ChatScreen(groupId: groupId);
            },
          ),
        ],
      ),

      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const GeneralSettingsScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const EditProfileScreen(),
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
          GoRoute(
            path: 'developer',
            builder: (context, state) => const DeveloperScreen(),
          ),
        ],
      ),
    ],
  );
});
