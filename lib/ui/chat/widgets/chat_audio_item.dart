// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:flutter/material.dart';
// // import 'package:audio_waveforms/audio_waveforms.dart';
// //
// // import '../../core/themes/colors.dart';
// // import '../chat_providers.dart';
// // import '../notifiers/chat_audio_notifier.dart';
// //
// // class ChatAudioItem extends ConsumerStatefulWidget {
// //   final String audioPath;
// //   const ChatAudioItem({super.key, required this.audioPath});
// //
// //   @override
// //   ConsumerState<ChatAudioItem> createState() => _ChatAudioPlayerState();
// // }
// //
// // class _ChatAudioPlayerState extends ConsumerState<ChatAudioItem> {
// //   late final ChatAudioNotifier notifier;
// //   bool _isDisposed = false;
// //   bool _isInitialized = false;
// //   int _retryCount = 0;
// //   static const int maxRetries = 3;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     notifier = ref.read(chatAudioProvider(widget.audioPath).notifier);
// //     // Initialize the player when the widget is created
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (!_isDisposed) {
// //         _initializePlayer();
// //       }
// //     });
// //   }
// //
// //   Future<void> _initializePlayer() async {
// //     if (_isDisposed || _isInitialized) return;
// //
// //     try {
// //       await notifier.preparePlayer();
// //       if (!_isDisposed && mounted) {
// //         setState(() {
// //           _isInitialized = true;
// //         });
// //       }
// //     } catch (e) {
// //       debugPrint('Error initializing audio player: $e');
// //       // Retry initialization if we haven't exceeded max retries
// //       if (_retryCount < maxRetries && !_isDisposed && mounted) {
// //         _retryCount++;
// //         await Future.delayed(Duration(seconds: _retryCount));
// //         _initializePlayer();
// //       }
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     _isDisposed = true;
// //     _cleanup();
// //     super.dispose();
// //   }
// //
// //   Future<void> _cleanup() async {
// //     try {
// //       await notifier.stop();
// //       await notifier.disposeController();
// //     } catch (e) {
// //       debugPrint('Error during ChatAudioItem cleanup: $e');
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final state = ref.watch(chatAudioProvider(widget.audioPath));
// //     final currentlyPlaying = ref.watch(currentlyPlayingAudioProvider);
// //     final isCurrentlyPlaying = currentlyPlaying == widget.audioPath;
// //
// //     // Show loading state if either not initialized or not ready
// //     if (!_isInitialized || !state.isReady) {
// //       return SizedBox(
// //         height: 50,
// //         child: Center(
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               const CircularProgressIndicator(strokeWidth: 2),
// //               if (state.error != null)
// //                 Padding(
// //                   padding: const EdgeInsets.only(top: 4),
// //                   child: Text(
// //                     state.error!,
// //                     style: const TextStyle(
// //                       color: Colors.red,
// //                       fontSize: 12,
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         ),
// //       );
// //     }
// //
// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Container(
// //           width: 40,
// //           height: 40,
// //           decoration: const BoxDecoration(
// //             shape: BoxShape.circle,
// //             color: AppColors.color727772,
// //           ),
// //           child: IconButton(
// //             icon: Icon(
// //               isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
// //               color: AppColors.white,
// //             ),
// //             onPressed: state.isReady ? notifier.togglePlayback : null,
// //           ),
// //         ),
// //         Padding(
// //           padding: const EdgeInsets.only(right: 10),
// //           child: AudioFileWaveforms(
// //             playerController: notifier.playerController,
// //             size: Size(MediaQuery.of(context).size.width * 0.4, 20),
// //             waveformType: WaveformType.fitWidth,
// //             enableSeekGesture: true,
// //             playerWaveStyle: const PlayerWaveStyle(
// //               fixedWaveColor: Colors.grey,
// //               liveWaveColor: Colors.white,
// //               spacing: 6,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }
//
// import 'package:audio_waveforms/audio_waveforms.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import '../../core/themes/colors.dart';
//
// class ChatAudioItem extends StatefulWidget {
//   String audioPath;
//   ChatAudioItem({super.key, required this.audioPath});
//
//   @override
//   State<ChatAudioItem> createState() => _ChatAudioItemState();
// }
//
// class _ChatAudioItemState extends State<ChatAudioItem> {
//   final PlayerController playerController = PlayerController();
//   bool isPlaying = false;
//
//   @override
//   void initState() {
//     preparePlayerController();
//     super.initState();
//   }
//
//   bool isReady = false;
//
//   Future<void> preparePlayerController() async {
//     try {
//       final localPath = await downloadAudioToFile(widget.audioPath);
//       await playerController.preparePlayer(
//         path: localPath,
//         shouldExtractWaveform: true,
//       );
//       playerController.setFinishMode(finishMode: FinishMode.stop);
//       setState(() {
//         isReady = true;
//       });
//     } catch (e) {
//       debugPrint("Audio download/prep error: $e");
//     }
//   }
//
//   Future<String> downloadAudioToFile(String url) async {
//     final dir = await getTemporaryDirectory();
//     final filePath = '${dir.path}/chat-audio-1.m4a';
//
//     final response = await Dio().download(url, filePath);
//
//     if (response.statusCode == 200) {
//       return filePath;
//     } else {
//       throw Exception('Failed to download audio');
//     }
//   }
//
//   @override
//   void dispose() {
//     playerController.dispose();
//     super.dispose();
//   }
//
//   void togglePlayback() async {
//     if (isPlaying) {
//       await playerController.stopPlayer();
//     } else {
//       await playerController.startPlayer(forceRefresh: true);
//     }
//     setState(() => isPlaying = !isPlaying);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!isReady) {
//       return const SizedBox(
//         height: 50,
//         child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
//       );
//     }
//
//     return Row(
//       children: [
//         Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: AppColors.color727772, // optional background color
//           ),
//           child: IconButton(
//             icon: Icon(
//               isPlaying ? Icons.stop : Icons.play_arrow,
//               color: AppColors.white,
//             ),
//             onPressed: togglePlayback,
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(right: 10),
//           child: AudioFileWaveforms(
//             playerController: playerController,
//             size: Size(MediaQuery.of(context).size.width * 0.4, 20),
//             waveformType: WaveformType.fitWidth,
//             enableSeekGesture: true,
//             playerWaveStyle: PlayerWaveStyle(
//               fixedWaveColor:  Colors.grey,
//               liveWaveColor: Colors.white,
//               spacing: 6,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }


//==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
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
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
            color: AppColors.color727772,
          ),
          child: IconButton(
            icon: Icon(
              isThisPlaying ? Icons.stop : Icons.play_arrow,
              color: AppColors.white,
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
              fixedWaveColor: Colors.grey,
              liveWaveColor: Colors.white,
              spacing: 6,
            ),
          ),
        ),
      ],
    );
  }
}



