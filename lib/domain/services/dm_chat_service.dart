import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

class DMChatService {
  static Future<DMChatData?> getDMChatData(String groupId, WidgetRef ref) async {
    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) return null;

      final currentUserHexPubkey = activeAccountData.pubkey;

      final currentUserNpub = await npubFromPublicKey(
        publicKey: await publicKeyFromString(publicKeyString: currentUserHexPubkey),
      );

      final otherMember = ref
          .read(groupsProvider.notifier)
          .getOtherGroupMember(
            groupId,
            currentUserNpub,
          );

      if (otherMember != null) {
        final metadataCacheNotifier = ref.read(metadataCacheProvider.notifier);
        final contactModel = await metadataCacheNotifier.getContactModel(otherMember.publicKey);
        final displayName = contactModel.displayNameOrName;
        final displayImage = contactModel.imagePath ?? (otherMember.imagePath ?? '');
        final nip05 = contactModel.nip05 ?? '';
        final npup = contactModel.publicKey;
        return DMChatData(
          displayName: displayName,
          displayImage: displayImage,
          nip05: nip05,
          publicKey: npup,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

extension DMChatServiceExtension on WidgetRef {
  Future<DMChatData?> getDMChatData(String groupId) {
    return DMChatService.getDMChatData(groupId, this);
  }
}
