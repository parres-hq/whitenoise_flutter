import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/chat/notifiers/chat_audio_notifier.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class AudioPlayerWidget extends ConsumerWidget {
  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.onDelete,
  });

  final String audioPath;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatAudioProvider(audioPath));
    final notifier = ref.read(chatAudioProvider(audioPath).notifier);
    final currentlyPlaying = ref.watch(currentlyPlayingAudioProvider);

    final isThisPlaying = currentlyPlaying == audioPath && state.isPlaying;

    // Handle loading and error states
    if (!state.isReady) {
      if (state.error != null) {
        return SizedBox(
          height: 50.h,
          child: Center(child: Text(state.error!, style: TextStyle(color: Colors.red, fontSize: 12.sp))),
        );
      }
      return SizedBox(
        height: 50.h,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.glitch50)),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      color: AppColors.glitch200,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.glitch600),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                isThisPlaying ? CarbonIcons.pause_filled : CarbonIcons.play_filled_alt,
                color: AppColors.glitch50,
                size: 14.w,
              ),
              onPressed: () => notifier.togglePlayback(),
            ),
          ),
          SizedBox(width: 8.w),

          // Audio waveform
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: AudioFileWaveforms(
                playerController: state.playerController!,
                size: Size(MediaQuery.of(context).size.width * 0.4, 20.h),
                waveformType: WaveformType.fitWidth,
                enableSeekGesture: true,
                playerWaveStyle: PlayerWaveStyle(
                  fixedWaveColor: AppColors.glitch400,
                  liveWaveColor: AppColors.glitch50,
                  spacing: 6.w,
                  scaleFactor: 0.8,
                  showSeekLine: true,
                  seekLineColor: AppColors.glitch500,
                ),
              ),
            ),
          ),

          // Delete button
          IconButton(
            icon: Icon(CarbonIcons.close, size: 20.w, color: AppColors.glitch500),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
