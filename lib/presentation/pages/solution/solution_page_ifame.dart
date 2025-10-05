// import 'package:flutter/material.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
// import 'package:flutter/services.dart';

// class SolutionPageIframe extends StatefulWidget {
//   const SolutionPageIframe({super.key});

//   @override
//   State<SolutionPageIframe> createState() => _SolutionPageIframeState();
// }

// class _SolutionPageIframeState extends State<SolutionPageIframe> {
//   late YoutubePlayerController _controller;
//   bool _showControls = false; // 내가 만든 위젯 보이기 여부
//   bool _isMuted = false; // 음소거 상태 관리

//   @override
//   void initState() {
//     super.initState();
//     // 가로 모드 고정
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     // 전체화면 몰입 모드 (상태바 + 네비게이션 바 숨김)
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     _controller = YoutubePlayerController.fromVideoId(
//       videoId: 'XYcyAjNe7Jw', // 원하는 유튜브 영상 ID
//       autoPlay: true,
//       startSeconds: 498,
//       endSeconds: 618,
//       params: const YoutubePlayerParams(
//         showControls: false, // 기본 컨트롤러 제거
//         showFullscreenButton: false, // 전체화면 버튼 제거
//         showVideoAnnotations: false, // 카드/추천 제거
//         enableCaption: false, // 자막 제거
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.close();

//     // 원래 세로/가로 전환 자유롭게 복구
//     SystemChrome.setPreferredOrientations(DeviceOrientation.values);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     return YoutubePlayerControllerProvider(
//       controller: _controller,
//       child: Stack(
//         children: [
//           Positioned.fill(
//             child: AbsorbPointer(
//               absorbing: true, //유튜브 터치 완전히 차단
//               child: SizedBox.expand(
//                 child: FittedBox(
//                   fit: BoxFit.cover, // 가로 기준으로 화면 꽉 채움 //안됨;;
//                   alignment: Alignment.center, // 위아래 넘치는 부분은 가운데 기준으로 잘림 //안됨;;
//                   child: SizedBox(
//                     width: screenSize.width,
//                     height: screenSize.height,
//                     child: YoutubePlayer(
//                       controller: _controller,
//                       aspectRatio: 16 / 9,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // 터치 영역 (내가 만든 위젯을 띄우는 trigger)
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _showControls = !_showControls; // 터치할 때 위젯 on/off
//                 });
//               },
//               child: Container(
//                 color: Colors.transparent, // 투명 터치 영역
//               ),
//             ),
//           ),

//           // 내가 만든 커스텀 위젯
//           if (_showControls)
//             Positioned.fill(
//               child: Stack(
//                 children: [
//                   // 종료 버튼
//                   Positioned(
//                     top: 16,
//                     right: 16,
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.close,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                       onPressed: () {
//                         Navigator.of(
//                           context,
//                         ).pop(); //값을 돌려주고 싶으면: Navigator.pop(context, result);
//                       },
//                     ),
//                   ),

//                   // 볼륨 버튼 & 슬라이더
//                   Positioned(
//                     top: 16,
//                     left: 16,
//                     child: IconButton(
//                       icon: Icon(
//                         _isMuted ? Icons.volume_off : Icons.volume_up,
//                         color: Colors.white,
//                         size: 28,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           if (_isMuted) {
//                             _controller.unMute();
//                           } else {
//                             _controller.mute();
//                           }
//                           _isMuted = !_isMuted;
//                         });
//                       },
//                     ),
//                   ),

//                   //  커스텀 Play/Pause 버튼
//                   Center(
//                     child: YoutubeValueBuilder(
//                       controller: _controller,
//                       builder: (context, value) {
//                         final isPlaying =
//                             value.playerState == PlayerState.playing;
//                         return IconButton(
//                           iconSize: 64,
//                           color: Colors.white,
//                           icon: Icon(
//                             isPlaying
//                                 ? Icons.pause_circle_filled
//                                 : Icons.play_circle_fill,
//                           ),
//                           onPressed: () {
//                             if (isPlaying) {
//                               context.ytController.pauseVideo();
//                             } else {
//                               context.ytController.playVideo();
//                             }
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
