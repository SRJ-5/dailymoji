import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return dotenv.env["API_URL_ANDROID"] ?? "http://10.0.2.2:8000";
    } else {
      return dotenv.env["API_URL_IOS"] ?? "http://127.0.0.1:8000";
    }
  }
}
