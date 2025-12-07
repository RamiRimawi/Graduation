import 'package:flutter/material.dart';
import 'supabase_config.dart';
import 'Mobile/LoginMobile.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const DolphinApp());
}
