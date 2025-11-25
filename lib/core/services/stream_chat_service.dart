import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../config/supabase_config.dart';

class StreamChatService {
  static final StreamChatService _instance = StreamChatService._internal();
  factory StreamChatService() => _instance;
  StreamChatService._internal();

  late final StreamChatClient client;
  bool _initialized = false;

  /// Initialize the Stream Chat client
  Future<void> initialize() async {
    if (_initialized) return;

    client = StreamChatClient(
      SupabaseConfig.streamChatApiKey,
      logLevel: Level.INFO,
    );

    _initialized = true;
  }

  /// Generate a Stream Chat token for a user (server-side logic)
  /// In production, this should be done on your backend
  String _generateToken(String userId) {
    final secret = SupabaseConfig.streamChatSecret;
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };
    final payload = {
      'user_id': userId,
    };

    final headerEncoded = base64Url.encode(utf8.encode(json.encode(header)));
    final payloadEncoded = base64Url.encode(utf8.encode(json.encode(payload)));
    final message = '$headerEncoded.$payloadEncoded';

    final hmacSha256 = Hmac(sha256, utf8.encode(secret));
    final signature = hmacSha256.convert(utf8.encode(message));
    final signatureEncoded = base64Url.encode(signature.bytes);

    return '$message.$signatureEncoded';
  }

  /// Connect a user to Stream Chat
  Future<void> connectUser({
    required String userId,
    required String userName,
    String? userImage,
    Map<String, dynamic>? extraData,
  }) async {
    if (!_initialized) await initialize();

    final token = _generateToken(userId);
    
    await client.connectUser(
      User(
        id: userId,
        name: userName,
        image: userImage,
        extraData: extraData ?? {},
      ),
      token,
    );
  }

  /// Disconnect the current user
  Future<void> disconnectUser() async {
    if (!_initialized) return;
    await client.disconnectUser();
  }

  /// Create or get an existing channel for AI chat
  Future<Channel> getOrCreateAIChannel({
    required String userId,
  }) async {
    final channel = client.channel(
      'messaging',
      id: 'support_$userId',
      extraData: {
        'name': 'Support Chat',
        'type': 'ai_support',
        'members': [userId],
      },
    );

    await channel.watch();
    return channel;
  }

  /// Create or get a channel with a human agent
  Future<Channel> getOrCreateAgentChannel({
    required String userId,
    required String agentId,
    String? conversationId,
  }) async {
    final channelId = conversationId ?? 'agent_${userId}_$agentId';
    
    final channel = client.channel(
      'messaging',
      id: channelId,
      extraData: {
        'name': 'Support with Agent',
        'type': 'agent_support',
        'members': [userId, agentId],
        'conversation_id': conversationId,
      },
    );

    await channel.watch();
    return channel;
  }

  /// Send a message to a channel
  Future<void> sendMessage({
    required Channel channel,
    required String text,
    Map<String, dynamic>? extraData,
  }) async {
    final message = Message(
      text: text,
      extraData: extraData ?? {},
    );

    await channel.sendMessage(message);
  }

  /// Get the current user
  User? get currentUser => client.state.currentUser;

  /// Check if user is connected
  bool get isConnected => client.wsConnectionStatus == ConnectionStatus.connected;

  /// Dispose the service
  void dispose() {
    if (_initialized) {
      client.dispose();
      _initialized = false;
    }
  }
}
