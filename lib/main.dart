import 'package:dailymoji/core/routers/router.dart';
import 'package:dailymoji/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 앱이 백그라운드일 때 도착한 알림을 처리하는 함수
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 백그라운드 알림 수신: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // .env 불러오기
  await dotenv.load(fileName: ".env");

  // Supabase 초기화 (Firebase 초기화보다 먼저)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Firebase 초기화
  await Firebase.initializeApp();

  // 백그라운드 알림 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 포그라운드 알림 수신 (앱 켜져 있을 때)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📨 포그라운드 알림 수신!");
    print("제목: ${message.notification?.title}");
    print("내용: ${message.notification?.body}");
  });

  // 앱이 종료된 상태에서 클릭으로 열릴 때
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("🪄 사용자가 알림을 클릭하여 앱 열었음!");
  });

  // // 알림 권한 요청 (iOS용)
  // await FirebaseMessaging.instance.requestPermission();

  // await initializeDateFormatting('ko_KR', null);

  //세로 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return const MyApp();
        },
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,

      // textScaler가 textField, BottomNavigationBar, TableCalendar내에서 사용 불가
      //(TableCalendar는 헤더 부분 기본 설정으로는 불가능, 커스텀 시 가능)
      // 앱 전체에 textScalerFactor를 1.0으로 고정 (즉, TextScaler.noScaling으로 사용)
      // 나중에 버전이 올라가 main에서 textScaleFactor가 사용이 불가능 하고 textField, BottomNavigationBar, TableCalendar에서 textScaler를 사용 가능할 때 변경해 줘야함
      // 나머지 text, text.rich 등은 AppText으로 변경이 완료된 상태
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}
