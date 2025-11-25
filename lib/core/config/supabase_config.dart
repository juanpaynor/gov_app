import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Fallback values for web (since .env doesn't work well on web)
  static const String _webSupabaseUrl = 'https://tkgjbddrdrzljfjsgtyl.supabase.co';
  static const String _webSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrZ2piZGRyZHJ6bGpmanNndHlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0NTE3OTUsImV4cCI6MjA3OTAyNzc5NX0.eo46eubeYAR_4LR6zUU-7kk4AZOPZSd9DHaFoNEGgUE';
  static const String _webStreamChatApiKey = '8pggmzbbj58a';
  static const String _webStreamChatSecret = '2v3xftdbeqpkhbp9edke9ps9k82e2tthyft7zcnzs2yauygs8w62f63dqyzz5cph';
  static const String _webGeminiApiKey = '***REMOVED***';
  
  static String get supabaseUrl => kIsWeb ? _webSupabaseUrl : (dotenv.env['SUPABASE_URL'] ?? _webSupabaseUrl);
  static String get supabaseAnonKey => kIsWeb ? _webSupabaseAnonKey : (dotenv.env['SUPABASE_ANON_KEY'] ?? _webSupabaseAnonKey);
  static String get streamChatApiKey => kIsWeb ? _webStreamChatApiKey : (dotenv.env['STREAM_CHAT_API_KEY'] ?? _webStreamChatApiKey);
  static String get streamChatSecret => kIsWeb ? _webStreamChatSecret : (dotenv.env['STREAM_CHAT_SECRET'] ?? _webStreamChatSecret);
  static String get geminiApiKey => kIsWeb ? _webGeminiApiKey : (dotenv.env['GEMINI_API_KEY'] ?? _webGeminiApiKey);
}
