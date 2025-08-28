import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/utils/string_extensions.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

class GroupWelcomeInvitationSheet extends StatelessWidget {
  final Welcome welcome;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const GroupWelcomeInvitationSheet({
    super.key,
    required this.welcome,
    this.onAccept,
    this.onDecline,
  });

  static Future<String?> show({
    required BuildContext context,
    required Welcome welcome,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    return WnBottomSheet.show<String>(
      context: context,
      title: welcome.memberCount > 2 ? 'Group Invitation' : 'Chat Invitation',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => GroupWelcomeInvitationSheet(
            welcome: welcome,
            onAccept: onAccept,
            onDecline: onDecline,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirectMessage = welcome.memberCount <= 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(24.h),
              if (isDirectMessage)
                DirectMessageAvatar(welcome: welcome)
              else
                WnAvatar(
                  imageUrl: '',
                  size: 96.w,
                ),
              Gap(16.h),
              if (isDirectMessage)
                DirectMessageInviteCard(welcome: welcome)
              else
                GroupMessageInvite(welcome: welcome),
            ],
          ),
        ),
        const Spacer(),
        WnFilledButton(
          visualState: WnButtonVisualState.secondary,
          onPressed: () {
            Navigator.of(context).pop();
            if (onDecline != null) {
              onDecline!();
            }
          },
          label: 'Decline',
        ),
        Gap(8.h),
        WnFilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onAccept != null) {
              onAccept!();
            }
          },
          label: 'Accept',
        ),
      ],
    );
  }
}

class GroupMessageInvite extends ConsumerStatefulWidget {
  const GroupMessageInvite({
    super.key,
    required this.welcome,
  });

  final Welcome welcome;

  @override
  ConsumerState<GroupMessageInvite> createState() => _GroupMessageInviteState();
}

class _GroupMessageInviteState extends ConsumerState<GroupMessageInvite> {
  Future<FlutterMetadata?> _fetchInviterMetadata() async {
    try {
      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;
      if (activeAccount == null) {
        ref.showErrorToast('No active account found');
        return null;
      }
      return await fetchMetadataFrom(
        pubkey: widget.welcome.welcomer,
        nip65Relays: activeAccount.nip65Relays,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String> _getDisplayablePublicKey() async {
    try {
      final npub = await npubFromHexPubkey(hexPubkey: widget.welcome.nostrGroupId);
      return npub;
    } catch (e) {
      return widget.welcome.nostrGroupId.formatPublicKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.welcome.groupName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        Gap(12.h),
        if (widget.welcome.groupDescription.isNotEmpty) ...[
          Text(
            'Group Description:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.mutedForeground,
            ),
          ),
          Text(
            widget.welcome.groupDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.primary,
            ),
          ),
        ],
        Gap(32.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Invited by:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
            ),
            Gap(8.w),
            FutureBuilder<FlutterMetadata?>(
              future: _fetchInviterMetadata(),
              builder: (context, snapshot) {
                final displayName =
                    snapshot.data?.displayName ?? snapshot.data?.name ?? 'Unknown User';
                return Row(
                  children: [
                    WnAvatar(
                      imageUrl: snapshot.data?.picture ?? '',
                      size: 18.w,
                    ),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        Gap(16.h),
        FutureBuilder<String>(
          future: _getDisplayablePublicKey(),
          builder: (context, npubSnapshot) {
            final displayKey = npubSnapshot.data ?? widget.welcome.welcomer;
            return Text(
              displayKey.formatPublicKey(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: context.colors.mutedForeground,
              ),
            );
          },
        ),
      ],
    );
  }
}

class DirectMessageAvatar extends ConsumerStatefulWidget {
  const DirectMessageAvatar({
    super.key,
    required this.welcome,
  });

  final Welcome welcome;

  @override
  ConsumerState<DirectMessageAvatar> createState() => _DirectMessageAvatarState();
}

class _DirectMessageAvatarState extends ConsumerState<DirectMessageAvatar> {
  Future<FlutterMetadata?> _fetchInviterMetadata() async {
    try {
      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;
      if (activeAccount == null) {
        ref.showErrorToast('No active account found');
        return null;
      }
      return await fetchMetadataFrom(
        pubkey: widget.welcome.welcomer,
        nip65Relays: activeAccount.nip65Relays,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlutterMetadata?>(
      future: _fetchInviterMetadata(),
      builder: (context, snapshot) {
        final metadata = snapshot.data;
        final profileImageUrl = metadata?.picture ?? '';

        return WnAvatar(
          imageUrl: profileImageUrl,
          size: 96.w,
        );
      },
    );
  }
}

class DirectMessageInviteCard extends ConsumerStatefulWidget {
  const DirectMessageInviteCard({
    super.key,
    required this.welcome,
  });

  final Welcome welcome;

  @override
  ConsumerState<DirectMessageInviteCard> createState() => _DirectMessageInviteCardState();
}

class _DirectMessageInviteCardState extends ConsumerState<DirectMessageInviteCard> {
  Future<FlutterMetadata?> _fetchInviterMetadata() async {
    try {
      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;
      if (activeAccount == null) {
        ref.showErrorToast('No active account found');
        return null;
      }
      return fetchMetadataFrom(
        pubkey: widget.welcome.welcomer,
        nip65Relays: activeAccount.nip65Relays,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String> _getDisplayablePublicKey() async {
    try {
      final npub = await npubFromHexPubkey(hexPubkey: widget.welcome.welcomer);
      return npub;
    } catch (e) {
      return widget.welcome.welcomer.formatPublicKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlutterMetadata?>(
      future: _fetchInviterMetadata(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  color: context.colors.primary,
                ),
              ),
              Gap(8.h),
              Text(
                'Loading inviter info...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(16.h),
            ],
          );
        }

        final metadata = snapshot.data;
        final displayName = metadata?.displayName ?? metadata?.name;
        final nip05 = metadata?.nip05;

        return Column(
          children: [
            Text(
              displayName ?? 'Unknown User',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
            if (nip05 != null && nip05.isNotEmpty) ...[
              Gap(2.h),
              Text(
                nip05,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.mutedForeground,
                ),
              ),
            ],

            Gap(32.h),
            FutureBuilder<String>(
              future: _getDisplayablePublicKey(),
              builder: (context, npubSnapshot) {
                final displayKey = npubSnapshot.data ?? widget.welcome.welcomer;
                return Text(
                  displayKey.formatPublicKey(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.mutedForeground,
                  ),
                );
              },
            ),
            Gap(8.h),
          ],
        );
      },
    );
  }
}
