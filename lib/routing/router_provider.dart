import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/auth_flow/create_profile_screen.dart';
import 'package:whitenoise/ui/auth_flow/info_screen.dart';
import 'package:whitenoise/ui/auth_flow/login_screen.dart';
import 'package:whitenoise/ui/auth_flow/qr_scanner_screen.dart';
import 'package:whitenoise/ui/auth_flow/welcome_screen.dart';
import 'package:whitenoise/ui/chat/chat_info/add_group_members_screen.dart';
import 'package:whitenoise/ui/chat/chat_info/chat_info_screen.dart';
import 'package:whitenoise/ui/chat/chat_info/edit_group_screen.dart';
import 'package:whitenoise/ui/chat/chat_management/add_to_group_screen.dart';
import 'package:whitenoise/ui/chat/chat_screen.dart';
import 'package:whitenoise/ui/settings/app_settings/app_settings_screen.dart';
import 'package:whitenoise/ui/settings/developer/developer_settings_screen.dart';
import 'package:whitenoise/ui/settings/donate/donate_screen.dart';
import 'package:whitenoise/ui/settings/general_settings_screen.dart';
import 'package:whitenoise/ui/settings/network/network_screen.dart';
import 'package:whitenoise/ui/settings/profile/edit_profile_screen.dart';
import 'package:whitenoise/ui/settings/profile/share_profile_qr_scan_screen.dart';
import 'package:whitenoise/ui/settings/profile/share_profile_screen.dart';
import 'package:whitenoise/ui/settings/profile_keys/profile_keys_screen.dart';
import 'package:whitenoise/ui/settings/wallet/wallet_screen.dart';
import 'package:whitenoise/ui/user_profile_list/chat_list_screen.dart';

/// Navigation observer that dismisses toasts when routes change
class _NavigationObserver extends NavigatorObserver {
  final Ref ref;

  _NavigationObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _dismissToasts();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _dismissToasts();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _dismissToasts();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _dismissToasts();
  }

  void _dismissToasts() {
    // Dismiss all toasts when navigation occurs
    // Use Future.microtask to avoid modifying provider during widget tree building
    Future.microtask(() {
      ref.read(toastMessageProvider.notifier).dismissAll();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.home,
    observers: [
      _NavigationObserver(ref),
    ],
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
        final protectedRoutes = [Routes.chats, Routes.users, Routes.settings];
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
        path: Routes.createProfile,
        builder: (context, state) => const CreateProfileScreen(),
      ),

      GoRoute(
        path: Routes.qrScanner,
        builder: (context, state) => const QRScannerScreen(),
      ),

      GoRoute(
        path: Routes.users,
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final userId = state.pathParameters['id']!;
              return Scaffold(
                body: Center(child: Text('User Detail: $userId')),
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
              final inviteId = state.extra as String?;
              return ChatScreen(groupId: groupId, inviteId: inviteId);
            },
          ),
          GoRoute(
            path: ':id/info',
            builder: (context, state) {
              final groupId = state.pathParameters['id']!;
              return ChatInfoScreen(groupId: groupId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final groupId = state.pathParameters['id']!;
                  return EditGroupScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: 'add-members',
                builder: (context, state) {
                  final groupId = state.pathParameters['id']!;
                  final existingMemberPubkeys = state.extra as List<String>? ?? [];
                  return AddGroupMembersScreen(
                    groupId: groupId,
                    existingMemberPubkeys: existingMemberPubkeys,
                  );
                },
              ),
            ],
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
            builder: (context, state) => const ProfileKeysScreen(),
          ),
          GoRoute(
            path: 'wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: 'developer',
            builder: (context, state) => const DeveloperSettingsScreen(),
          ),
          GoRoute(
            path: 'app_settings',
            builder: (context, state) => const AppSettingsScreen(),
          ),
          GoRoute(
            path: 'donate',
            builder: (context, state) => const DonateScreen(),
          ),
          GoRoute(
            path: 'share_profile',
            builder: (context, state) => const ShareProfileScreen(),
            routes: [
              GoRoute(
                path: 'qr_scan',
                builder: (context, state) => const ShareProfileQrScanScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.userProfileQrScan,
        builder: (context, state) => const ShareProfileQrScanScreen(hideViewQrButton: true),
      ),
      GoRoute(
        path: Routes.addUserToGroup,
        builder: (context, state) {
          final userNpub = state.pathParameters['id']!;
          return AddToGroupScreen(userNpub: userNpub);
        },
      ),
    ],
  );
});
