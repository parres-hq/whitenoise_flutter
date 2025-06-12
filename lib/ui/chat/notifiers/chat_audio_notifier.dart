import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final currentlyPlayingAudioProvider = StateProvider<String?>((ref) => null);

class ChatAudioState {
  final PlayerController? playerController;
  final bool isReady;
  final bool isPlaying;
  final String? error;

  ChatAudioState({
    this.playerController,
    this.isReady = false,
    this.isPlaying = false,
    this.error,
  });

  ChatAudioState copyWith({
    PlayerController? playerController,
    bool? isReady,
    bool? isPlaying,
    String? error,
  }) {
    return ChatAudioState(
      playerController: playerController ?? this.playerController,
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      error: error,
    );
  }
}

class ChatAudioNotifier extends StateNotifier<ChatAudioState> {
  final Ref ref;
  final String audioUrl;
  bool _hasCompletionListener = false;
  ChatAudioNotifier(this.ref, this.audioUrl) : super(ChatAudioState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = PlayerController();

      final localPath = await _downloadAudioToFile(audioUrl);

      await controller.preparePlayer(
        path: localPath,
      );

      controller.setFinishMode();

      if (!_hasCompletionListener) {
        _hasCompletionListener = true;
        controller.onCompletion.listen((_) async {
          debugPrint('Playback completed for $audioUrl');
          await controller.seekTo(0); // Reset for replay
          state = state.copyWith(isPlaying: false);
          ref.read(currentlyPlayingAudioProvider.notifier).state = null;
        });
      }

      state = state.copyWith(playerController: controller, isReady: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String> _downloadAudioToFile(String url) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${url.hashCode}.m4a';

    final response = await Dio().download(url, filePath);
    if (response.statusCode == 200) {
      return filePath;
    } else {
      throw Exception('Failed to download audio');
    }
  }

  Future<void> togglePlayback() async {
    final controller = state.playerController;
    if (controller == null || !state.isReady) return;

    final currentPlayingUrl = ref.read(currentlyPlayingAudioProvider);

    if (state.isPlaying) {
      await controller.stopPlayer();
      state = state.copyWith(isPlaying: false);
      ref.read(currentlyPlayingAudioProvider.notifier).state = null;
    } else {
      if (currentPlayingUrl != null && currentPlayingUrl != audioUrl) {
        final previousNotifier = ref.read(
          chatAudioProvider(currentPlayingUrl).notifier,
        );
        await previousNotifier.stopPlaybackSilently();
      }

      // Always seek to start before play
      await controller.seekTo(0);

      await controller.startPlayer();
      state = state.copyWith(isPlaying: true);
      ref.read(currentlyPlayingAudioProvider.notifier).state = audioUrl;
    }
  }

  Future<void> stopPlaybackSilently() async {
    final controller = state.playerController;
    if (controller == null || !state.isPlaying) return;

    await controller.stopPlayer();
    state = state.copyWith(isPlaying: false);
    debugPrint('Stopping playback silently for $audioUrl');
  }

  @override
  void dispose() {
    _hasCompletionListener = false;
    state.playerController?.dispose();
    super.dispose();
  }
}

final chatAudioProvider =
    StateNotifierProvider.family<ChatAudioNotifier, ChatAudioState, String>(
      (ref, audioUrl) => ChatAudioNotifier(ref, audioUrl),
    );
