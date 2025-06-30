import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    String? displayName,
    String? about,
    String? picture,
    String? nip05,
    ProfileState? initialProfile,
    @Default(false) bool isSaving,
    Object? error,
    StackTrace? stackTrace,
  }) = _ProfileState;

  const ProfileState._();

  bool get isDirty {
    if (initialProfile == null) {
      return false;
    }

    final dName =
        displayName == initialProfile!.displayName ||
        (displayName == null && initialProfile!.displayName == '') ||
        (displayName == '' && initialProfile!.displayName == null);
    final abt =
        about == initialProfile!.about ||
        (about == null && initialProfile!.about == '') ||
        (about == '' && initialProfile!.about == null);
    final pic =
        picture == initialProfile!.picture ||
        (picture == null && initialProfile!.picture == '') ||
        (picture == '' && initialProfile!.picture == null);
    final nip =
        nip05 == initialProfile!.nip05 ||
        (nip05 == null && initialProfile!.nip05 == '') ||
        (nip05 == '' && initialProfile!.nip05 == null);

    return !(dName && abt && pic && nip);
  }
}
