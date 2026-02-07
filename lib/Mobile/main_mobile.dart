import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'LoginMobile.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';


const String _oneSignalAppId = '9b9120d7-ce4a-4693-9023-0f469f02f9e0';

Future<void> _initOneSignal() async {
  OneSignal.initialize(_oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await _initOneSignal();
  runApp(const DolphinApp());
}
