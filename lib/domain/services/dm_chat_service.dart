import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/src/rust/api/users.dart' as wn_users_api;
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class DMChatService {
  static Future<DMChatData?> getDMChatData(String groupId, WidgetRef ref) async {
    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) return null;

      final currentUserNpub = npubFromHexPubkey(
        hexPubkey: activePubkey,
      );

      final otherMember = ref
          .read(groupsProvider.notifier)
          .getOtherGroupMember(
            groupId,
            currentUserNpub,
          );

      if (otherMember != null) {
        final user = await wn_users_api.getUser(pubkey: otherMember.publicKey);
        final otherMemberPubkey = otherMember.publicKey;
        String otherMemberNpubPubkey = otherMemberPubkey;
        if (otherMemberPubkey.isValidHexPublicKey) {
          otherMemberNpubPubkey = npubFromHexPubkey(hexPubkey: otherMemberPubkey);
        }
        final contactModel = ContactModel.fromMetadata(
          pubkey: otherMemberNpubPubkey,
          metadata: user.metadata,
        );
        final displayName = contactModel.displayName;
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
