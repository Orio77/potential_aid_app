class ClaudeSuggestion {
  final String id;
  final String tableName;
  final String operation; // 'insert' | 'update'
  final String? recordSupabaseId;
  final Map<String, dynamic> payload;
  final String description;
  final String? reasoning;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  const ClaudeSuggestion({
    required this.id,
    required this.tableName,
    required this.operation,
    this.recordSupabaseId,
    required this.payload,
    required this.description,
    this.reasoning,
    required this.status,
    required this.createdAt,
  });

  factory ClaudeSuggestion.fromJson(Map<String, dynamic> json) {
    return ClaudeSuggestion(
      id: json['id'] as String,
      tableName: json['table_name'] as String,
      operation: json['operation'] as String,
      recordSupabaseId: json['record_supabase_id'] as String?,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      description: json['description'] as String,
      reasoning: json['reasoning'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
}
