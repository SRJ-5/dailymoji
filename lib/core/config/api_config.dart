import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String getBaseUrl() {
  if (Platform.isAndroid) {
    return dotenv.env["API_URL_ANDROID"]!;
  } else {
    return dotenv.env["API_URL_IOS"]!;
  }
}
