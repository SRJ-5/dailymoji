// hyun: 여기 있는거 클린아키텍쳐로 data source로 옮겼는데 그렇게 하는게 맞는지 확인 필요

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final supabase = Supabase.instance.client;

// /// FCM 토큰을 Supabase user_tokens 테이블에 저장하는 함수
// Future<void> saveFcmTokenToSupabase(
//     TargetPlatform platform) async {
//   try {
//     final user = supabase.auth.currentUser;
//     if (user == null) {
//       print("⚠️ 유저가 로그인되지 않았습니다. FCM 토큰 저장 스킵");
//       return;
//     }
//     late String token;
//     if (platform == TargetPlatform.iOS) {
//       final iosToken =
//           await FirebaseMessaging.instance.getAPNSToken();
//       if (iosToken == null) {
//         print("⚠️ FCM ios 토큰을 가져올 수 없습니다.");
//         return;
//       }
//       token = iosToken;
//     } else if (platform == TargetPlatform.android) {
//       final androidToken =
//           await FirebaseMessaging.instance.getToken();
//       if (androidToken == null) {
//         print("⚠️ FCM android 토큰을 가져올 수 없습니다.");
//         return;
//       }
//       token = androidToken;
//     }

//     await supabase.from('user_tokens').upsert({
//       'user_id': user.id,
//       'token': token,
//       'updated_at': DateTime.now().toIso8601String(),
//     });

//     print("✅ Supabase에 FCM 토큰 저장 완료: $token");
//   } catch (e) {
//     print("⚠️ FCM 토큰 저장 실패: $e");
//   }
// }
