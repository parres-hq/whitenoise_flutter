import 'dart:async';
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
  static Completer<void>? _initCompleter;

  static Future<void> initialize() async {
    if (_initCompleter?.isCompleted == true) {
      _logger.fine('Whitenoise already initialized, skipping');
      return;
    }

    if (_initCompleter != null) {
      _logger.fine('Whitenoise initialization in progress, awaiting');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

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

      _initCompleter!.complete();
      _logger.info('Whitenoise initialized successfully 🦫🚀');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize Whitenoise: $e', e, stackTrace);
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  static bool get isInitialized => _initCompleter?.isCompleted == true;
}
