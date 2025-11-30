import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = "https://xwfvdalvmxcrhevaymkm.supabase.co";
  static const String anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3ZnZkYWx2bXhjcmhldmF5bWttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTgyODAsImV4cCI6MjA3OTkzNDI4MH0.M_ZFiZ-HdkauCD2rsAE3uwC6WWpE-VaZDCfUDOnD2Do";

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}

final supabase = Supabase.instance.client;
