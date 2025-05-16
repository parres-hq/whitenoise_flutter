import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

class ChatAudioState {
  final bool isPlaying;
  final bool isReady;

  ChatAudioState({required this.isPlaying, required this.isReady});

  ChatAudioState copyWith({bool? isPlaying, bool? isReady}) {
    return ChatAudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isReady: isReady ?? this.isReady,
    );
  }
}

class ChatAudioCubit extends Cubit<ChatAudioState> {
  ChatAudioCubit() : super(ChatAudioState(isPlaying: false, isReady: false));

  final playerController = PlayerController();

  Future<void> preparePlayer(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/chat-audio-1.m4a';

      final response = await Dio().download(url, filePath);
      if (response.statusCode != 200) throw Exception('Download failed');

      await playerController.preparePlayer(
        path: filePath,
        shouldExtractWaveform: true,
      );

      //playerController.setFinishMode(finishMode: FinishMode.stop);
      playerController.setFinishMode(finishMode: FinishMode.pause);


      emit(state.copyWith(isReady: true));
    } catch (e) {
      // handle error
    }
  }

  Future<void> togglePlayback() async {
    if (state.isPlaying) {
      await playerController.stopPlayer();
      emit(state.copyWith(isPlaying: false));
    } else {
      await playerController.startPlayer(forceRefresh: true);
      emit(state.copyWith(isPlaying: true));

      // Wait for audio duration to end
      final duration = await playerController.getDuration();
      Future.delayed(Duration(milliseconds: duration), () {
        // Stop and reset when finished
        emit(state.copyWith(isPlaying: false));
      });
    }
  }


  void dispose() {
    playerController.dispose();
  }
}
