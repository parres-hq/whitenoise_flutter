import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
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
          height: 50,
          child: Center(
            child: Text(
              state.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        );
      }
      return SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.primaryForeground,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isMe ? context.colors.primary : context.colors.baseMuted,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? context.colors.primaryForeground : context.colors.primary,
            ),
            child: IconButton(
              icon: Icon(
                isThisPlaying ? CarbonIcons.pause_filled : CarbonIcons.play_filled_alt,
                color: isMe ? context.colors.primary : context.colors.primaryForeground,
                size: 20,
              ),
              onPressed: () => notifier.togglePlayback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: (isMe ? context.colors.primaryForeground : context.colors.primary)
                        .withOpacity(0.3),
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
                const SizedBox(height: 4),
                // Duration text
                Text(
                  _formatDuration(state.position ?? Duration.zero, state.duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: (isMe ? context.colors.primaryForeground : context.colors.primary)
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Audio icon
          Icon(
            CarbonIcons.microphone,
            size: 16,
            color: (isMe ? context.colors.primaryForeground : context.colors.primary).withOpacity(
              0.7,
            ),
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
