import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class GroupWelcomeInvitationSheet extends StatelessWidget {
  final WelcomeData welcomeData;
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
    required WelcomeData welcomeData,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    return CustomBottomSheet.show<String>(
      context: context,
      title: welcomeData.memberCount > 2 ? 'Group Invitation' : 'Chat Invitation',
      heightFactor: 0.7,
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
    final isDirectMessage = welcomeData.memberCount <= 2;
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
                ContactAvatar(
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
        AppFilledButton(
          visualState: AppButtonVisualState.secondary,
          onPressed: () {
            Navigator.of(context).pop();
            if (onDecline != null) {
              onDecline!();
            }
          },
          title: 'Decline',
        ),
        Gap(8.h),
        AppFilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onAccept != null) {
              onAccept!();
            }
          },
          title: 'Accept',
        ),
        Gap(16.h),
      ],
    );
  }
}

class GroupMessageInvite extends StatefulWidget {
  const GroupMessageInvite({
    super.key,
    required this.welcomeData,
  });

  final WelcomeData welcomeData;

  @override
  State<GroupMessageInvite> createState() => _GroupMessageInviteState();
}

class _GroupMessageInviteState extends State<GroupMessageInvite> {
  Future<MetadataData?> _fetchInviterMetadata() async {
    try {
      final publicKey = await publicKeyFromString(publicKeyString: widget.welcomeData.welcomer);
      return await fetchMetadata(pubkey: publicKey);
    } catch (e) {
      return null;
    }
  }

  Future<String> _getDisplayablePublicKey() async {
    try {
      final npub = await npubFromHexPubkey(hexPubkey: widget.welcomeData.nostrGroupId);
      return npub;
    } catch (e) {
      return widget.welcomeData.nostrGroupId.formatPublicKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.welcomeData.groupName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        Gap(12.h),
        if (widget.welcomeData.groupDescription.isNotEmpty) ...[
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
            widget.welcomeData.groupDescription,
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
            FutureBuilder<MetadataData?>(
              future: _fetchInviterMetadata(),
              builder: (context, snapshot) {
                final userName =
                    snapshot.data?.displayName ?? snapshot.data?.name ?? 'Unknown User';
                return Row(
                  children: [
                    ContactAvatar(
                      imageUrl: snapshot.data?.picture ?? '',
                      size: 18.w,
                    ),
                    Text(
                      userName,
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
            final displayKey = npubSnapshot.data ?? widget.welcomeData.welcomer;
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

class DirectMessageAvatar extends StatelessWidget {
  const DirectMessageAvatar({
    super.key,
    required this.welcomeData,
  });

  final WelcomeData welcomeData;

  Future<MetadataData?> _fetchInviterMetadata() async {
    try {
      final publicKey = await publicKeyFromString(publicKeyString: welcomeData.welcomer);
      return await fetchMetadata(pubkey: publicKey);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MetadataData?>(
      future: _fetchInviterMetadata(),
      builder: (context, snapshot) {
        final metadata = snapshot.data;
        final profileImageUrl = metadata?.picture ?? '';

        return ContactAvatar(
          imageUrl: profileImageUrl,
          size: 96.w,
        );
      },
    );
  }
}

class DirectMessageInviteCard extends StatelessWidget {
  const DirectMessageInviteCard({
    super.key,
    required this.welcomeData,
  });

  final WelcomeData welcomeData;

  Future<MetadataData?> _fetchInviterMetadata() async {
    try {
      final publicKey = await publicKeyFromString(publicKeyString: welcomeData.welcomer);
      return await fetchMetadata(pubkey: publicKey);
    } catch (e) {
      return null;
    }
  }

  Future<String> _getDisplayablePublicKey() async {
    try {
      final npub = await npubFromHexPubkey(hexPubkey: welcomeData.welcomer);
      return npub;
    } catch (e) {
      return welcomeData.welcomer.formatPublicKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MetadataData?>(
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
                final displayKey = npubSnapshot.data ?? welcomeData.welcomer;
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
