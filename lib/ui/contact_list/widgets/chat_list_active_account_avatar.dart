import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';

class ChatListActiveAccountAvatar extends ConsumerStatefulWidget {
  const ChatListActiveAccountAvatar({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  ConsumerState<ChatListActiveAccountAvatar> createState() => _ChatListActiveAccountAvatarState();
}

class _ChatListActiveAccountAvatarState extends ConsumerState<ChatListActiveAccountAvatar> {
  ProviderSubscription<AsyncValue<ActiveAccountState>>? _activeAccountSubscription;
  ContactModel? _profileData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
      _activeAccountSubscription = ref.listenManual(
        activeAccountProvider,
        (previous, next) {
          if (next is AsyncData) {
            _loadProfileData();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _activeAccountSubscription?.close();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final AsyncValue<ActiveAccountState> activeAccountState = ref.read(activeAccountProvider);
      final String? pubkey = activeAccountState.valueOrNull?.account?.pubkey;
      if (pubkey == null || pubkey.isEmpty) return;
      final ContactModel profileData = await ref
          .read(userProfileDataProvider.notifier)
          .getUserProfileData(pubkey);
      if (!mounted) return;
      final String? currentPubkey = ref.read(activeAccountProvider).valueOrNull?.account?.pubkey;
      if (currentPubkey != pubkey) return;
      setState(() {
        _profileData = profileData;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileData = null;
      });
    }
  }

  Widget _buildAvatar({
    String imageUrl = '',
    String? displayName,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap:
          widget.onTap ??
          () {
            context.push(Routes.settings);
          },
      child: WnAvatar(
        imageUrl: imageUrl,
        displayName: displayName,
        size: 36.r,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountState = ref.watch(activeAccountProvider);

    return activeAccountState.when(
      data: (state) {
        if (state.account != null && _profileData != null) {
          return _buildAvatar(
            imageUrl: _profileData?.imagePath ?? '',
            displayName: _profileData?.displayName,
          );
        }
        return _buildAvatar();
      },
      loading: () => _buildAvatar(),
      error: (error, stack) => _buildAvatar(),
    );
  }
}
