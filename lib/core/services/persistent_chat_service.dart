import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../config/supabase_config.dart';

/// Service to maintain persistent Stream Chat connection across app
class PersistentChatService extends ChangeNotifier {
  static const String _baseUrl = 'https://myroxas.ph';
  static const String _conversationIdKey = 'active_conversation_id';
  static const String _streamTokenKey = 'active_stream_token';
  static const String _streamChannelIdKey = 'active_stream_channel_id';
  static const String _tokenExpiresAtKey = 'active_token_expires_at';

  StreamChatClient? _streamChatClient;
  Channel? _streamChannel;
  String? _conversationId;
  String? _streamUserToken;
  String? _streamChannelId;
  DateTime? _tokenExpiresAt;
  bool _isConnected = false;

  StreamChatClient? get streamChatClient => _streamChatClient;
  Channel? get streamChannel => _streamChannel;
  String? get conversationId => _conversationId;
  bool get isConnected => _isConnected;
  DateTime? get tokenExpiresAt => _tokenExpiresAt;

  /// Initialize and restore any existing chat session
  Future<void> initialize() async {
    await _loadSavedSession();
  }

  /// Load saved session from SharedPreferences
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _conversationId = prefs.getString(_conversationIdKey);
      _streamUserToken = prefs.getString(_streamTokenKey);
      _streamChannelId = prefs.getString(_streamChannelIdKey);

      final expiresAtString = prefs.getString(_tokenExpiresAtKey);
      if (expiresAtString != null) {
        _tokenExpiresAt = DateTime.parse(expiresAtString);

        // Check if token is expired
        if (_tokenExpiresAt!.isBefore(DateTime.now())) {
          print('⚠️ Saved session expired, clearing...');
          await clearSession();
          return;
        }
      }

      // If we have valid session data, reconnect
      if (_conversationId != null &&
          _streamUserToken != null &&
          _streamChannelId != null) {
        print('✅ Found saved session, reconnecting...');
        await _reconnectToStreamChat();
      }
    } catch (e) {
      print('⚠️ Error loading saved session: $e');
      await clearSession();
    }
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_conversationId != null) {
        await prefs.setString(_conversationIdKey, _conversationId!);
      }
      if (_streamUserToken != null) {
        await prefs.setString(_streamTokenKey, _streamUserToken!);
      }
      if (_streamChannelId != null) {
        await prefs.setString(_streamChannelIdKey, _streamChannelId!);
      }
      if (_tokenExpiresAt != null) {
        await prefs.setString(
          _tokenExpiresAtKey,
          _tokenExpiresAt!.toIso8601String(),
        );
      }
      print('💾 Session saved');
    } catch (e) {
      print('⚠️ Error saving session: $e');
    }
  }

  /// Clear saved session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conversationIdKey);
      await prefs.remove(_streamTokenKey);
      await prefs.remove(_streamChannelIdKey);
      await prefs.remove(_tokenExpiresAtKey);

      _conversationId = null;
      _streamUserToken = null;
      _streamChannelId = null;
      _tokenExpiresAt = null;
      _isConnected = false;

      print('🗑️ Session cleared');
      notifyListeners();
    } catch (e) {
      print('⚠️ Error clearing session: $e');
    }
  }

  /// Request human agent and establish Stream Chat connection
  Future<bool> requestHumanAgent({
    required String userName,
    required String userEmail,
    required String languagePreference,
    List<Map<String, dynamic>>? chatSummary,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      // Call REST API for agent handoff
      final response = await http.post(
        Uri.parse('$_baseUrl/api/support/conversations/request-agent'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': user.id,
          'user_name': userName,
          'user_email': userEmail,
          'chat_summary': chatSummary ?? [],
          'reason': 'user_requested',
          'language_preference': languagePreference,
          'priority': 5,
          'subject': 'Support Request',
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Request failed');
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        _conversationId = data['conversation_id'] as String?;
        _streamUserToken = data['stream_user_token'] as String?;
        _streamChannelId = data['stream_chat_channel_id'] as String?;
        _tokenExpiresAt = DateTime.now().add(const Duration(hours: 1));

        if (_conversationId == null || _conversationId!.isEmpty) {
          throw Exception('No conversation ID returned from server');
        }

        print('✅ Agent request successful:');
        print('   Conversation ID: $_conversationId');
        print('   Channel ID: $_streamChannelId');

        // Save session
        await _saveSession();

        // Connect to Stream Chat
        await _connectToStreamChat();

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error requesting agent: $e');
      return false;
    }
  }

  /// Connect to Stream Chat with saved credentials
  Future<void> _connectToStreamChat() async {
    try {
      if (_streamUserToken == null || _streamChannelId == null) {
        throw Exception('Missing Stream Chat credentials');
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('🔌 Connecting to Stream Chat...');

      // Initialize Stream Chat client if needed
      if (_streamChatClient == null) {
        _streamChatClient = StreamChatClient(
          SupabaseConfig.streamChatApiKey,
          logLevel: Level.WARNING,
        );
      }

      // Connect user with token
      await _streamChatClient!.connectUser(
        User(
          id: user.id,
          name: user.userMetadata?['full_name'] ?? 'User',
          extraData: {
            'name': user.userMetadata?['full_name'] ?? 'User',
            'email': user.email ?? '',
            // User avatar will be handled by native app, using default for now
          },
        ),
        _streamUserToken!,
      );

      print('✅ Connected to Stream Chat');

      // Watch the channel
      _streamChannel = _streamChatClient!.channel('team', id: _streamChannelId);
      await _streamChannel!.watch();

      print('✅ Channel connected: $_streamChannelId');

      _isConnected = true;
      notifyListeners();
    } catch (e) {
      print('❌ Error connecting to Stream Chat: $e');
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Reconnect to existing Stream Chat session
  Future<void> _reconnectToStreamChat() async {
    try {
      await _connectToStreamChat();
    } catch (e) {
      print('❌ Error reconnecting: $e');
      // Clear invalid session
      await clearSession();
    }
  }

  /// Close conversation
  Future<bool> closeConversation({int? rating}) async {
    if (_conversationId == null) return false;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/support/conversations/$_conversationId/close'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'satisfaction_rating': rating}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to close conversation');
      }

      // Disconnect and clear session
      await disconnect();
      await clearSession();

      print('✅ Conversation closed');
      return true;
    } catch (e) {
      print('❌ Error closing conversation: $e');
      return false;
    }
  }

  /// Disconnect from Stream Chat
  Future<void> disconnect() async {
    if (_streamChatClient != null) {
      await _streamChatClient!.disconnectUser();
      _streamChatClient = null;
      _streamChannel = null;
      _isConnected = false;
      notifyListeners();
      print('🔌 Disconnected from Stream Chat');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
