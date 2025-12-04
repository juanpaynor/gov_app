import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Fallback values for web (since .env doesn't work well on web)
  // IMPORTANT: For production web builds, use environment variables or Firebase Remote Config
  // These fallback values should be set during build time, not committed to repo
  static const String _webSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _webSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String _webStreamChatApiKey = String.fromEnvironment(
    'STREAM_CHAT_API_KEY',
    defaultValue: '',
  );
  static const String _webStreamChatSecret = String.fromEnvironment(
    'STREAM_CHAT_SECRET',
    defaultValue: '',
  );
  static const String _webGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static String get supabaseUrl => kIsWeb
      ? _webSupabaseUrl
      : (dotenv.env['SUPABASE_URL'] ?? _webSupabaseUrl);
  static String get supabaseAnonKey => kIsWeb
      ? _webSupabaseAnonKey
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? _webSupabaseAnonKey);
  static String get streamChatApiKey => kIsWeb
      ? _webStreamChatApiKey
      : (dotenv.env['STREAM_CHAT_API_KEY'] ?? _webStreamChatApiKey);
  static String get streamChatSecret => kIsWeb
      ? _webStreamChatSecret
      : (dotenv.env['STREAM_CHAT_SECRET'] ?? _webStreamChatSecret);
  static String get geminiApiKey => kIsWeb
      ? _webGeminiApiKey
      : (dotenv.env['GEMINI_API_KEY'] ?? _webGeminiApiKey);
}
