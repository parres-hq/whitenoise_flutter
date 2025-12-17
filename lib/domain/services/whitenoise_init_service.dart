import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/src/rust/api.dart' show createWhitenoiseConfig, initializeWhitenoise;

/// Service responsible for initializing the Whitenoise Rust backend.
///
/// This service ensures idempotent initialization - calling [initialize] multiple
/// times is safe and will only perform initialization once.
class WhitenoiseInitService {
  static final _logger = Logger('WhitenoiseInitService');
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.fine('Whitenoise already initialized, skipping');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';

      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      final config = await createWhitenoiseConfig(
        dataDir: dataDir,
        logsDir: logsDir,
      );

      await initializeWhitenoise(config: config);

      _isInitialized = true;
      _logger.info('Whitenoise initialized successfully 🦫🚀');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize Whitenoise: $e', e, stackTrace);
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;
}
