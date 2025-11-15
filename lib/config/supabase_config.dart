class SupabaseConfig {
  // Use --dart-define to pass these values at build time:
  // flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-supabase-url.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // Helper method to validate configuration
  static bool get isConfigured =>
      supabaseUrl != 'https://your-supabase-url.supabase.co' &&
      supabaseAnonKey != 'your-anon-key';
}
