class RelayValidation {
  static final RegExp _domainRegex = RegExp(
    r'^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]+(:[0-9]+)?(/.*)?$',
  );

  /// Validates a relay URL and returns an error message if invalid, null if valid
  static String? validateRelayUrl(String url) {
    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
      return 'URL must start with wss:// or ws://';
    }

    final String domain =
        url.startsWith('wss://')
            ? url.substring(6) // Remove 'wss://'
            : url.substring(5); // Remove 'ws://'

    if (domain.isEmpty) {
      return 'Domain name is required';
    }

    if (domain.contains(' ')) {
      return 'Domain cannot contain spaces';
    }

    if (!_domainRegex.hasMatch(domain)) {
      return 'Invalid domain format';
    }

    return null;
  }

  /// Checks if a URL should be skipped during validation (empty or just prefix)
  static bool shouldSkipValidation(String url) {
    return url.isEmpty || url == 'wss://' || url == 'ws://';
  }
}
