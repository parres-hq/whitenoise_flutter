import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final currentlyPlayingAudioProvider = StateProvider<String?>((ref) => null);

class ChatAudioState {
  final AudioPlayer? audioPlayer;
  final bool isReady;
  final bool isPlaying;
  final Duration? duration;
  final Duration? position;
  final String? error;

  ChatAudioState({
    this.audioPlayer,
    this.isReady = false,
    this.isPlaying = false,
    this.duration,
    this.position,
    this.error,
  });

  ChatAudioState copyWith({
    AudioPlayer? audioPlayer,
    bool? isReady,
    bool? isPlaying,
    Duration? duration,
    Duration? position,
    String? error,
  }) {
    return ChatAudioState(
      audioPlayer: audioPlayer ?? this.audioPlayer,
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      error: error,
    );
  }
}

class ChatAudioNotifier extends FamilyNotifier<ChatAudioState, String> {
  final _logger = Logger('ChatAudioNotifier');
  late final String audioUrl;
  bool _hasListeners = false;

  @override
  ChatAudioState build(String arg) {
    audioUrl = arg;

    // Setup cleanup when the notifier is disposed
    ref.onDispose(() {
      _cleanup();
    });

    _init();
    return ChatAudioState();
  }

  Future<void> _init() async {
    try {
      final player = AudioPlayer();

      // Download audio to local file
      final localPath = await _downloadAudioToFile(audioUrl);

      // Set audio source with error handling
      try {
        // Check if localPath is actually a local file or URL
        if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
          await player.setUrl(localPath);
        } else {
          await player.setFilePath(localPath);
        }
      } catch (e) {
        // If setting audio source fails, try the original URL
        _logger.warning('Failed to set audio source, trying original URL: $e');
        try {
          await player.setUrl(audioUrl);
        } catch (urlError) {
          _logger.severe('Failed to set audio URL as well: $urlError');
          throw Exception('Cannot play audio: $urlError');
        }
      }

      // Initialize audio session after player is ready
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Setup listeners
      if (!_hasListeners) {
        _hasListeners = true;

        // Listen to player state changes
        player.playerStateStream.listen((playerState) {
          final isPlaying = playerState.playing;
          final processingState = playerState.processingState;

          state = state.copyWith(isPlaying: isPlaying);

          // Handle completion
          if (processingState == ProcessingState.completed) {
            _logger.info('Playback completed for $audioUrl');
            player.seek(Duration.zero);
            state = state.copyWith(isPlaying: false);
            ref.read(currentlyPlayingAudioProvider.notifier).state = null;
          }
        });

        // Listen to duration changes
        player.durationStream.listen((duration) {
          if (duration != null) {
            state = state.copyWith(duration: duration);
          }
        });

        // Listen to position changes
        player.positionStream.listen((position) {
          state = state.copyWith(position: position);
        });
      }

      state = state.copyWith(audioPlayer: player, isReady: true);
    } catch (e) {
      _logger.severe('Error initializing audio player: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String> _downloadAudioToFile(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${url.hashCode}.m4a';

      final response = await Dio().download(url, filePath);
      if (response.statusCode == 200) {
        return filePath;
      } else {
        throw Exception('Failed to download audio: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error downloading audio file: $e');
      // Return the original URL if download fails
      // The player will try to play directly from URL
      return url;
    }
  }

  Future<void> togglePlayback() async {
    final player = state.audioPlayer;
    if (player == null || !state.isReady) return;

    try {
      final currentPlayingUrl = ref.read(currentlyPlayingAudioProvider);

      if (state.isPlaying) {
        await player.pause();
        ref.read(currentlyPlayingAudioProvider.notifier).state = null;
      } else {
        // Stop any other currently playing audio
        if (currentPlayingUrl != null && currentPlayingUrl != audioUrl) {
          final previousNotifier = ref.read(
            chatAudioProvider(currentPlayingUrl).notifier,
          );
          await previousNotifier.stopPlaybackSilently();
        }

        // Activate audio session before playing
        final session = await AudioSession.instance;
        await session.setActive(true);

        // Seek to start and play
        await player.seek(Duration.zero);
        await player.play();
        ref.read(currentlyPlayingAudioProvider.notifier).state = audioUrl;
      }
    } catch (e) {
      _logger.severe('Error during playback toggle: $e');
      state = state.copyWith(error: 'Playback error: ${e.toString()}');
      ref.read(currentlyPlayingAudioProvider.notifier).state = null;
    }
  }

  Future<void> stopPlaybackSilently() async {
    final player = state.audioPlayer;
    if (player == null || !state.isPlaying) return;

    try {
      await player.pause();
      _logger.info('Stopping playback silently for $audioUrl');
    } catch (e) {
      _logger.warning('Error stopping playback silently: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    final player = state.audioPlayer;
    if (player == null || !state.isReady) return;

    try {
      await player.seek(position);
    } catch (e) {
      _logger.warning('Error seeking to position: $e');
    }
  }

  void _cleanup() {
    _hasListeners = false;
    final player = state.audioPlayer;
    if (player != null) {
      // Stop and dispose player asynchronously
      player
          .stop()
          .then((_) {
            player.dispose();
          })
          .catchError((e) {
            _logger.warning('Error disposing audio player: $e');
            return null; // Return null to indicate the operation failed
          });
    }

    // Deactivate audio session
    AudioSession.instance.then((session) {
      session.setActive(false).catchError((e) {
        _logger.warning('Error deactivating audio session: $e');
        return false; // Return false to indicate the operation failed
      });
    });
  }
}

final chatAudioProvider = NotifierProvider.family<ChatAudioNotifier, ChatAudioState, String>(
  ChatAudioNotifier.new,
);
