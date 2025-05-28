import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/core/ui/skeleton_box.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/colors.dart';
import '../../notifiers/chat_audio_notifier.dart';

class ChatAudioItem extends ConsumerWidget {
  final String audioPath;
  final bool isMe;
  const ChatAudioItem({super.key, required this.audioPath, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatAudioProvider(audioPath));
    final notifier = ref.read(chatAudioProvider(audioPath).notifier);

    final currentlyPlaying = ref.watch(currentlyPlayingAudioProvider);

    final isThisPlaying = currentlyPlaying == audioPath && state.isPlaying;

    if (!state.isReady) {
      if (state.error != null) {
        return SizedBox(
          height: 40.h,
          child: Center(child: Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        );
      }
      
      // Skeleton loading state
      return SizedBox(
        height: 40.h,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(40.w, 40.h, shape: BoxShape.circle),
            SizedBox(width: 10),
            SkeletonBox(
              160.w,
              20.h,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isMe ? AppColors.glitch600 : AppColors.glitch800),
          child: IconButton(
            icon: Icon(
              isThisPlaying ? CarbonIcons.pause_filled : CarbonIcons.play_filled_alt,
              color: AppColors.glitch50,
            ),
            onPressed: () => notifier.togglePlayback(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: AudioFileWaveforms(
            playerController: state.playerController!,
            size: Size(160.w, 20.h),
            waveformType: WaveformType.fitWidth,
            enableSeekGesture: true,
            playerWaveStyle: PlayerWaveStyle(
              fixedWaveColor: AppColors.glitch400,
              liveWaveColor: isMe ? AppColors.glitch50 : AppColors.glitch800,
              spacing: 6,
            ),
          ),
        ),
      ],
    );
  }
}
