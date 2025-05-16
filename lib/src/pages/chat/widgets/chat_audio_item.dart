import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_colors.dart';
import '../states/chat_audio_state.dart';

class ChatAudioItem extends StatelessWidget {
  final String audioPath;

  const ChatAudioItem({super.key, required this.audioPath});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ChatAudioCubit();
        cubit.preparePlayer(audioPath);
        return cubit;
      },
      child: BlocBuilder<ChatAudioCubit, ChatAudioState>(
        builder: (context, state) {
          final cubit = context.read<ChatAudioCubit>();
          final playerController = cubit.playerController;

          if (!state.isReady) {
            return const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.color727772,
                ),
                child: IconButton(
                  icon: Icon(
                    state.isPlaying ? Icons.stop : Icons.play_arrow,
                    color: AppColors.white,
                  ),
                  onPressed: cubit.togglePlayback,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AudioFileWaveforms(
                  playerController: playerController,
                  size: Size(MediaQuery.of(context).size.width * 0.4, 20),
                  waveformType: WaveformType.fitWidth,
                  enableSeekGesture: true,
                  playerWaveStyle: const PlayerWaveStyle(
                    fixedWaveColor: Colors.grey,
                    liveWaveColor: Colors.white,
                    spacing: 6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
