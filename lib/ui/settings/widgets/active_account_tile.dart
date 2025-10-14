import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/user_profile_tile.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ActiveAccountTile extends ConsumerWidget {
  const ActiveAccountTile({super.key});

  UserProfile _activeAccountProfileData(ActiveAccountState state) {
    return UserProfile.fromMetadata(
      pubkey: state.account?.pubkey ?? '',
      metadata: state.metadata,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccountState = ref.watch(activeAccountProvider);

    return activeAccountState.when(
      data: (state) {
        if (state.account != null) {
          return UserProfileTile(
            userProfile: _activeAccountProfileData(state),
            trailingIcon: WnImage(
              AssetsPaths.icQrCode,
              size: 20.w,
              color: context.colors.primary,
            ),
            onTap: () => context.push('${Routes.settings}/share_profile'),
          );
        } else {
          return Center(child: Text('ui.noAccountsFound'.tr()));
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${'errors.errorOccurred'.tr()}: $error')),
    );
  }
}
