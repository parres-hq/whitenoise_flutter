import 'package:whitenoise/src/rust/api/users.dart';

/// Utility class for User operations like sorting and filtering
class UserUtils {
  static List<User> sortUsersByName(List<User> users) {
    final sortedUsers = List<User>.from(users);

    sortedUsers.sort((a, b) {
      final aName = _getDisplayName(a);
      final bName = _getDisplayName(b);

      if (aName == 'Unknown User' && bName != 'Unknown User') return 1;
      if (bName == 'Unknown User' && aName != 'Unknown User') return -1;
      if (aName == 'Unknown User' && bName == 'Unknown User') return 0;

      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return sortedUsers;
  }

  static List<User> filterUsers(List<User> users, String searchQuery) {
    if (searchQuery.isEmpty) return users;

    final query = searchQuery.toLowerCase();
    final results = <User>[];

    // Use for loop instead of where().toList() for better performance
    for (final user in users) {
      final displayName = _getDisplayName(user).toLowerCase();

      // Check display name first (most common match)
      if (displayName.contains(query)) {
        results.add(user);
        continue;
      }

      // Only check nip05 if display name doesn't match
      final nip05 = user.metadata.nip05?.toLowerCase();
      if (nip05 != null && nip05.contains(query)) {
        results.add(user);
        continue;
      }

      // Only check pubkey if neither display name nor nip05 match
      if (user.pubkey.toLowerCase().contains(query)) {
        results.add(user);
      }
    }

    return results;
  }

  static String _getDisplayName(User user) {
    final metadata = user.metadata;

    if (metadata.displayName != null && metadata.displayName!.isNotEmpty) {
      return metadata.displayName!;
    }

    if (metadata.name != null && metadata.name!.isNotEmpty) {
      return metadata.name!;
    }

    return 'Unknown User';
  }

  static String getDisplayName(User user) {
    return _getDisplayName(user);
  }

  static bool hasValidDisplayName(User user) {
    final metadata = user.metadata;
    return (metadata.displayName != null && metadata.displayName!.isNotEmpty) ||
        (metadata.name != null && metadata.name!.isNotEmpty);
  }

  static String? getProfilePicture(User user) {
    return user.metadata.picture;
  }

  static String? getNip05(User user) {
    return user.metadata.nip05;
  }

  static String? getAbout(User user) {
    return user.metadata.about;
  }

  static String? getWebsite(User user) {
    return user.metadata.website;
  }

  static String? getLightningAddress(User user) {
    return user.metadata.lud16 ?? user.metadata.lud06;
  }
}
