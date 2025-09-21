import 'package:dailymoji/core/routers/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // API_URL_ANDROID, API_URL_IOS 불러오기
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: Size(375, 812), // Figma 기준 사이즈 (iPhone X 예시)
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MyApp();
        },
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        fontFamily: "Pretendard",
      ),
    );
  }
}
