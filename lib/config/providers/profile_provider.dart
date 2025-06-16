import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/src/rust/api.dart';

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    return const ProfileState();
  }

  Future<void> fetchProfileData() async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authProvider);
      if (authState.whitenoise == null || !authState.isAuthenticated) {
        state = AsyncValue.error(
          'Not authenticated or Whitenoise not initialized',
          StackTrace.current,
        );
        return;
      }

      final account = await ref.read(authProvider.notifier).getCurrentActiveAccount();

      if (account == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final metadata = await fetchMetadata(whitenoise: authState.whitenoise!, pubkey: publicKey);

      final metadataData = await convertMetadataToData(metadata: metadata);

      final profileState = ProfileState(
        name: metadataData?.name,
        displayName: metadataData?.displayName,
        about: metadataData?.about,
        picture: metadataData?.picture,
        banner: metadataData?.banner,
        nip05: metadataData?.nip05,
        lud16: metadataData?.lud16,
        npub: npub,
      );
      
      state = AsyncValue.data(profileState);
    } catch (e, st) {
      debugPrintStack(label: 'ProfileNotifier.loadProfileData', stackTrace: st);
      state = AsyncValue.error(e.toString(), st);
    }
  }


  Future<void> updateProfileData({
    String? name,
    String? displayName,
    String? about,
    String? picture,
    String? banner,
    String? website,
    String? nip05,
    String? lud16,
  }) async {
    try {
      //TODO: TBD next
    } catch (e, st) {
      debugPrintStack(label: 'ProfileNotifier.updateProfileData', stackTrace: st);
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
