import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// FCM 토큰을 Supabase user_tokens 테이블에 저장하는 함수
Future<void> saveFcmTokenToSupabase() async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    print("⚠️ 유저가 로그인되지 않았습니다. FCM 토큰 저장 스킵");
    return;
  }

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) {
    print("⚠️ FCM 토큰을 가져올 수 없습니다.");
    return;
  }

  await supabase.from('user_tokens').upsert({
    'user_id': user.id,
    'token': token,
    'updated_at': DateTime.now().toIso8601String(),
  });

  print("✅ Supabase에 FCM 토큰 저장 완료: $token");
}
