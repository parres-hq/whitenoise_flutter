class DMChatData {
  final String displayName;
  final String? displayImage;
  final String? nip05;
  final String? publicKey;

  const DMChatData({
    required this.displayName,
    this.displayImage,
    this.nip05,
    this.publicKey,
  });

  DMChatData copyWith({
    String? displayName,
    String? displayImage,
    String? nip05,
    String? publicKey,
  }) {
    return DMChatData(
      displayName: displayName ?? this.displayName,
      displayImage: displayImage ?? this.displayImage,
      nip05: nip05 ?? this.nip05,
      publicKey: publicKey ?? this.publicKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DMChatData &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          displayImage == other.displayImage &&
          nip05 == other.nip05 &&
          publicKey == other.publicKey;

  @override
  int get hashCode =>
      displayName.hashCode ^ displayImage.hashCode ^ nip05.hashCode ^ publicKey.hashCode;

  @override
  String toString() {
    return 'DMChatData{displayName: $displayName, displayImage: $displayImage, nip05: $nip05, publicKey: $publicKey}';
  }
}
