import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' as wnMetadataApi;
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class GroupWelcomeInvitationSheet extends StatelessWidget {
  final Welcome welcomeData;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const GroupWelcomeInvitationSheet({
    super.key,
    required this.welcomeData,
    this.onAccept,
    this.onDecline,
  });

  static Future<String?> show({
    required BuildContext context,
    required Welcome welcomeData,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    return WnBottomSheet.show<String>(
      context: context,
      title:
          'Chat Invitation', // TODO big plans: user Welcome Group type ... welcomeData.memberCount > 2 ? 'Group Invitation' : 'Chat Invitation',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => GroupWelcomeInvitationSheet(
            welcomeData: welcomeData,
            onAccept: onAccept,
            onDecline: onDecline,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirectMessage =
        true; // TODO big plans. User Welcome group type ... welcomeData.memberCount <= 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(24.h),
              if (isDirectMessage)
                DirectMessageAvatar(welcomeData: welcomeData)
              else
                WnAvatar(
                  imageUrl: '',
                  size: 96.w,
                ),
              Gap(16.h),
              if (isDirectMessage)
                DirectMessageInviteCard(welcomeData: welcomeData)
              else
                GroupMessageInvite(welcomeData: welcomeData),
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
    required this.welcomeData,
  });

  final Welcome welcomeData;

  @override
  ConsumerState<GroupMessageInvite> createState() => _GroupMessageInviteState();
}

class _GroupMessageInviteState extends ConsumerState<GroupMessageInvite> {
  Future<wnMetadataApi.FlutterMetadata?> _fetchInviterMetadata() async {
    // TODO big plans: fetch inviter metadata
    // try {
    //   final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccount();
    //   if (activeAccountData == null) {
    //     ref.showErrorToast('No active account found');
    //     return null;
    //   }
    //   return await fetchMetadataFrom(
    //     pubkey: widget.welcomeData.welcomer
    //     nip65Relays: activeAccountData.nip65Relays,
    //   );
    // } catch (e) {
    //   return null;
    // }
    ref.showErrorToast('No active account found');
    return null;
  }

  Future<String> _getDisplayablePublicKey() async {
    // TODO big plans: get group public key
    // try {
    //   final npub = await npubFromHexPubkey(hexPubkey: widget.welcomeData.nostrGroupId);
    //   return npub;
    // } catch (e) {
    //   return widget.welcomeData.nostrGroupId.formatPublicKey();
    // }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Unknown Group', // TODO: show gorup name from Welcome widget.welcomeData.groupName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        Gap(12.h),
        if (true) ...[
          // TODO: use Welcome group description (widget.welcomeData.groupDescription.isNotEmpty) ...[
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
            'Unknown group description', // TODO big plans use grou description _> widget.welcomeData.groupDescription,
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
            FutureBuilder<wnMetadataApi.FlutterMetadata?>(
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
            final displayKey =
                npubSnapshot.data ?? ''; // use Wemcome data ...widget.welcomeData.welcomer;
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
    required this.welcomeData,
  });

  final Welcome welcomeData;

  @override
  ConsumerState<DirectMessageAvatar> createState() => _DirectMessageAvatarState();
}

class _DirectMessageAvatarState extends ConsumerState<DirectMessageAvatar> {
  Future<wnMetadataApi.FlutterMetadata?> _fetchInviterMetadata() async {
    // TODO big plans: fetch inviter metadata
    // try {
    //   final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccount();
    //   if (activeAccountData == null) {
    //     ref.showErrorToast('No active account found');
    //     return null;
    //   }
    //   return await fetchMetadataFrom(
    //     pubkey: widget.welcomeData.welcomer,
    //     nip65Relays: activeAccountData.nip65Relays,
    //   );
    // } catch (e) {
    //   return null;
    // }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<wnMetadataApi.FlutterMetadata?>(
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
    required this.welcomeData,
  });

  final Welcome welcomeData;

  @override
  ConsumerState<DirectMessageInviteCard> createState() => _DirectMessageInviteCardState();
}

class _DirectMessageInviteCardState extends ConsumerState<DirectMessageInviteCard> {
  Future<wnMetadataApi.FlutterMetadata?> _fetchInviterMetadata() async {
    // TODO big plans: fetch inviter metadata
    // try {
    //   final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccount();
    //   if (activeAccountData == null) {
    //     ref.showErrorToast('No active account found');
    //     return null;
    //   }
    //   return fetchMetadataFrom(
    //     pubkey: widget.welcomeData.welcomer,
    //     nip65Relays: activeAccountData.nip65Relays,
    //   );
    // } catch (e) {
    //   return null;
    // }
    return null;
  }

  Future<String> _getDisplayablePublicKey() async {
    // TODO big plans:  user welcomer public key
    // try {
    //   final npub = await npubFromHexPubkey(hexPubkey: widget.welcomeData.welcomer);
    //   return npub;
    // } catch (e) {
    //   return widget.welcomeData.welcomer.formatPublicKey();
    // }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<wnMetadataApi.FlutterMetadata?>(
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
                final displayKey =
                    npubSnapshot.data ??
                    ''; // TODO big plans: use welcomer public key ... widget.welcomeData.welcomer;
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
