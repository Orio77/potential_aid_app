import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client;
  final Connectivity _connectivity = Connectivity();

  SupabaseService(this._client);
  SupabaseClient get client => _client;

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.isNotEmpty &&
        connectivityResult.first != ConnectivityResult.none;
  }
}
