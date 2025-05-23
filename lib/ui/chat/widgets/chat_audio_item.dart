import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import '../../core/themes/colors.dart';
import '../notifiers/chat_audio_notifier.dart';

class ChatAudioItem extends ConsumerWidget {
  final String audioPath;
  const ChatAudioItem({super.key, required this.audioPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatAudioProvider(audioPath));
    final notifier = ref.read(chatAudioProvider(audioPath).notifier);

    final currentlyPlaying = ref.watch(currentlyPlayingAudioProvider);

    final isThisPlaying = currentlyPlaying == audioPath && state.isPlaying;

    if (!state.isReady) {
      if (state.error != null) {
        return SizedBox(
          height: 50,
          child: Center(
            child: Text(
              state.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        );
      }
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.glitch50)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glitch600,
          ),
          child: IconButton(
            icon: Icon(
              isThisPlaying ? CarbonIcons.pause_filled : CarbonIcons.play_filled, color: AppColors.glitch50,
            ),
            onPressed: () => notifier.togglePlayback(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: AudioFileWaveforms(
            playerController: state.playerController!,
            size: Size(MediaQuery.of(context).size.width * 0.4, 20),
            waveformType: WaveformType.fitWidth,
            enableSeekGesture: true,
            playerWaveStyle: const PlayerWaveStyle(
              fixedWaveColor: AppColors.glitch400,
              liveWaveColor: AppColors.glitch50,
              spacing: 6,
            ),
          ),
        ),
      ],
    );
  }
}
