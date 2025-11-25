import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final _supabase = Supabase.instance.client;

  /// Create a new support conversation in Supabase
  Future<String> createConversation({
    required String userId,
    required String userName,
    String? initialMessage,
  }) async {
    try {
      final response = await _supabase
          .from('support_conversations')
          .insert({
            'user_id': userId,
            'user_name': userName,
            'status': 'waiting',
            'initial_message': initialMessage,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Update conversation status
  Future<void> updateConversationStatus({
    required String conversationId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('support_conversations')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to update conversation status: $e');
    }
  }

  /// Assign an agent to a conversation
  Future<void> assignAgent({
    required String conversationId,
    required String agentId,
  }) async {
    try {
      await _supabase
          .from('support_conversations')
          .update({
            'agent_id': agentId,
            'status': 'active',
            'assigned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to assign agent: $e');
    }
  }

  /// Get conversation details
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final response = await _supabase
          .from('support_conversations')
          .select()
          .eq('id', conversationId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching conversation: $e');
      return null;
    }
  }

  /// Get all conversations for a user
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    try {
      final response = await _supabase
          .from('support_conversations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user conversations: $e');
      return [];
    }
  }

  /// Add user to agent queue
  Future<void> addToAgentQueue({
    required String userId,
    required String conversationId,
    int priority = 1,
  }) async {
    try {
      await _supabase.from('agent_queue').insert({
        'user_id': userId,
        'conversation_id': conversationId,
        'priority': priority,
        'status': 'waiting',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add to queue: $e');
    }
  }

  /// Get next user in queue
  Future<Map<String, dynamic>?> getNextInQueue() async {
    try {
      final response = await _supabase
          .from('agent_queue')
          .select()
          .eq('status', 'waiting')
          .order('priority', ascending: false)
          .order('created_at', ascending: true)
          .limit(1)
          .single();

      return response;
    } catch (e) {
      print('No users in queue: $e');
      return null;
    }
  }

  /// Update queue status
  Future<void> updateQueueStatus({
    required String queueId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('agent_queue')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', queueId);
    } catch (e) {
      throw Exception('Failed to update queue status: $e');
    }
  }

  /// Get or create FAQ by question
  Future<Map<String, dynamic>?> getFAQ(String question) async {
    try {
      final response = await _supabase
          .from('support_faqs')
          .select()
          .eq('question', question)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching FAQ: $e');
      return null;
    }
  }

  /// Create a new FAQ
  Future<void> createFAQ({
    required String question,
    required String answer,
    String? category,
  }) async {
    try {
      await _supabase.from('support_faqs').insert({
        'question': question,
        'answer': answer,
        'category': category,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create FAQ: $e');
    }
  }

  /// Close a conversation
  Future<void> closeConversation(String conversationId) async {
    try {
      await _supabase
          .from('support_conversations')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to close conversation: $e');
    }
  }

  /// Listen to conversation status changes
  RealtimeChannel subscribeToConversation(
    String conversationId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return _supabase
        .channel('conversation_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'support_conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: conversationId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }
}
