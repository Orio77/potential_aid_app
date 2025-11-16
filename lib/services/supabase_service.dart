import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:potential_aid_app/config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  final Connectivity _connectivity = Connectivity();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  bool get isInitialized => Supabase.instance.isInitialized;

  /// Initialize Supabase client
  Future<void> initialize() async {
    if (isInitialized) return;

    if (!SupabaseConfig.isConfigured) {
      throw Exception(
        'Supabase configuration not found. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
      );
    }

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.isNotEmpty &&
        connectivityResult.first != ConnectivityResult.none;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Sign in anonymously (for basic sync without user accounts)
  Future<void> signInAnonymously() async {
    if (isAuthenticated) return;

    final response = await client.auth.signInAnonymously();
    if (response.user == null) {
      throw Exception('Failed to authenticate with Supabase');
    }
  }

  /// Get current user ID for data partitioning
  String? get currentUserId => client.auth.currentUser?.id;

  /// Generic method to fetch records from any table
  Future<List<Map<String, dynamic>>> fetchRecords(
    String tableName, {
    String? userId,
    DateTime? lastSyncTime,
  }) async {
    var query = client.from(tableName).select();

    // Add user filter if provided (for multi-user support)
    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    // Add timestamp filter for incremental sync
    if (lastSyncTime != null) {
      query = query.gte('last_modified', lastSyncTime.toIso8601String());
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Generic method to upsert records to any table
  Future<List<Map<String, dynamic>>> upsertRecords(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return [];

    final response = await client
        .from(tableName)
        .upsert(records, onConflict: 'supabase_id')
        .select();

    return List<Map<String, dynamic>>.from(response);
  }

  /// Generic method to delete records from any table
  Future<void> deleteRecords(String tableName, List<String> supabaseIds) async {
    if (supabaseIds.isEmpty) return;

    await client.from(tableName).delete().inFilter('supabase_id', supabaseIds);
  }

  /// Check connectivity to Supabase
  Future<bool> checkConnectivity() async {
    try {
      // Simple query to test connection
      await client.rpc('ping').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
