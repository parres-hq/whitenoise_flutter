class User {
  final String id;
  final String name;
  final String email;
  final String publicKey;
  final String? imagePath;
  final String? username;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.publicKey,
    this.imagePath,
    this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      publicKey: json['publicKey'],
      imagePath: json['image_path'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'publicKey': publicKey,
      'image_path': imagePath,
      'username': username,
    };
  }
}
