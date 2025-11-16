import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Use --dart-define to pass these values at build time:
  // flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
  static String supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'https://your-supabase-url.supabase.co';
  static String supabaseAnonKey =
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';

  // Helper method to validate configuration
  static bool get isConfigured =>
      supabaseUrl != 'https://your-supabase-url.supabase.co' &&
      supabaseAnonKey != 'your-anon-key';
}
