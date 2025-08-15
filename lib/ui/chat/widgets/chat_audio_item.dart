import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

import '../notifiers/chat_audio_notifier.dart';

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
          height: 50.h,
          child: Center(
            child: Text(
              state.error!,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
        );
      }
      return SizedBox(
        height: 50.h,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            color: context.colors.primaryForeground,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: isMe ? context.colors.primary : context.colors.baseMuted,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? context.colors.primaryForeground : context.colors.primary,
            ),
            child: IconButton(
              icon: SvgPicture.asset(
                isThisPlaying ? AssetsPaths.icPauseFilled : AssetsPaths.icPlayFilled,
                colorFilter: ColorFilter.mode(
                  isMe ? context.colors.primary : context.colors.primaryForeground,
                  BlendMode.srcIn,
                ),
                width: 20.sp,
                height: 20.sp,
              ),
              onPressed: () => notifier.togglePlayback(),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio progress bar
                Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.r),
                    color: (isMe ? context.colors.primaryForeground : context.colors.primary)
                        .withValues(alpha: 0.3),
                  ),
                  child:
                      state.duration != null
                          ? LinearProgressIndicator(
                            value:
                                state.position != null && state.duration != null
                                    ? (state.position!.inMilliseconds /
                                            state.duration!.inMilliseconds)
                                        .clamp(0.0, 1.0)
                                    : 0.0,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isMe ? context.colors.primaryForeground : context.colors.primary,
                            ),
                          )
                          : Container(),
                ),
                SizedBox(height: 4.h),
                // Duration text
                Text(
                  _formatDuration(state.position ?? Duration.zero, state.duration),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: (isMe ? context.colors.primaryForeground : context.colors.primary)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Audio icon
          SvgPicture.asset(
            AssetsPaths.icMicrophone,
            colorFilter: ColorFilter.mode(
              (isMe ? context.colors.primaryForeground : context.colors.primary).withValues(
                alpha: 0.7,
              ),
              BlendMode.srcIn,
            ),
            width: 16.sp,
            height: 16.sp,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration position, Duration? duration) {
    String formatTime(Duration d) {
      final minutes = d.inMinutes.remainder(60);
      final seconds = d.inSeconds.remainder(60);
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    if (duration != null) {
      return '${formatTime(position)} / ${formatTime(duration)}';
    } else {
      return formatTime(position);
    }
  }
}
