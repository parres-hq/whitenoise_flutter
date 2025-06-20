class User {
  final String id;
  final String name;
  final String nip05;
  final String publicKey;
  final String? imagePath;
  final String? username;

  User({
    required this.id,
    required this.name,
    required this.nip05,
    required this.publicKey,
    this.imagePath,
    this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      nip05: json['nip05'],
      publicKey: json['publicKey'],
      imagePath: json['image_path'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nip05': nip05,
      'publicKey': publicKey,
      'image_path': imagePath,
      'username': username,
    };
  }
}
