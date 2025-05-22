// Build the GoRouter here
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/chat/chat_screen.dart';
import 'package:whitenoise/ui/chat/groupchat_screen.dart';

// import '../ui/auth_flow/welcome_screen.dart';
import './../../domain/dummy_data/dummy_messages.dart';

// import '../ui/chat/chat_screen.dart';

/// The route configuration.
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return ChatScreen(contact: marekContact, initialMessages: messages);
      },
      routes: <RouteBase>[
        // GoRoute(
        //   path: Routes.chats,
        //   builder: (BuildContext context, GoRouterState state) {
        //     //final id = state.pathParameters["id"]!; // Get "id" param from URL
        //     return ChatScreen();
        //   },
        // ),
        GoRoute(
          path: Routes.newChat,
          builder: (BuildContext context, GoRouterState state) {
            return const GroupchatScreen();
          },
        ),
      ],
    ),
  ],
);
