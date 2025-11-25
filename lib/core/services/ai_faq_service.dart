import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIFaqService {
  static final AIFaqService _instance = AIFaqService._internal();
  factory AIFaqService() => _instance;
  AIFaqService._internal();

  late final GenerativeModel _model;
  bool _initialized = false;

  /// Initialize the Gemini AI model
  Future<void> initialize(String apiKey) async {
    if (_initialized) {
      print('⚠️ AI service already initialized');
      return;
    }

    print('🔧 Creating Gemini model...');
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.9,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      _initialized = true;
      print('✅ Gemini model created successfully');
    } catch (e) {
      print('❌ Failed to create Gemini model: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Get FAQ data from Supabase
  Future<List<Map<String, dynamic>>> _getFAQs() async {
    try {
      final response = await Supabase.instance.client
          .from('support_faqs')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching FAQs: $e');
      return [];
    }
  }

  /// Build context from FAQs for AI
  Future<String> _buildFAQContext() async {
    final faqs = await _getFAQs();
    
    if (faqs.isEmpty) {
      return 'No FAQ data available.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Available FAQs:');
    
    for (var faq in faqs) {
      buffer.writeln('\nQ: ${faq['question']}');
      buffer.writeln('A: ${faq['answer']}');
      if (faq['category'] != null) {
        buffer.writeln('Category: ${faq['category']}');
      }
    }

    return buffer.toString();
  }

  /// Generate a response using Gemini AI
  Future<String> generateResponse(String userMessage) async {
    if (!_initialized) {
      throw Exception('AI FAQ Service not initialized');
    }

    try {
      print('🤖 AI Service: Generating response for: "$userMessage"');
      
      // Build context from FAQs
      final faqContext = await _buildFAQContext();
      print('📚 FAQ Context loaded: ${faqContext.length} characters');

      // Create the prompt with context
      final prompt = '''
You are Niño, a friendly and knowledgeable AI assistant for the MyRoxas mobile app - the official government services app for Roxas City, Philippines.

**MyRoxas App Features:**

1. **Report Issues** 📋
   - Citizens can report problems like potholes, broken streetlights, illegal dumping, etc.
   - Submit reports with photos, location, and descriptions
   - Track report status and get updates
   - Help the city respond faster to community issues

2. **Book Appointments** 📅
   - Schedule appointments with city government offices
   - Choose service type, date, and time
   - Get appointment confirmations and reminders
   - Avoid long queues by booking ahead

3. **Emergency Hotlines** 📞
   - Quick access to important emergency numbers
   - Police, fire department, medical emergency contacts
   - City hall and government office numbers
   - One-tap calling for emergencies

4. **City Announcements & News** 📰
   - Latest updates from Roxas City government
   - Official announcements from the Mayor's office
   - Community events and public notices
   - Stay informed about city activities

5. **AI Chat Support (Me!)** 💬
   - Get instant answers about city services
   - Ask questions in English, Tagalog, or Hiligaynon
   - Connect to human agents when needed
   - Available 24/7 to help citizens

**How to Guide Users:**
- If they ask how to report something → Tell them about the Report feature
- If they need appointments → Explain the Appointments feature
- If they need emergency help → Direct them to Hotlines
- For city news → Point them to Announcements section
- Complex issues → Offer to connect them with a human agent

$faqContext

User Question: $userMessage

Instructions:
1. Answer based on the FAQ data and MyRoxas app features above
2. **BE BRIEF AND CONVERSATIONAL** - Imagine you're texting a friend, not writing an essay
3. **Response length rules (STRICTLY FOLLOW)**:
   - Simple questions → 1-2 sentences MAX (e.g., "What is this?" → "It's [answer].")
   - Medium questions → 2-4 sentences MAX
   - Complex questions → 5-7 sentences MAX
4. **Cut out fluff** - No "I'd be happy to help", "Great question", etc. Just answer directly
5. When users ask "what can you do" → List features in bullet points, 1 line each
6. If asked about real-time info → "I don't have live data, but [brief general info]"
7. If you can't help → "I'm not sure about that. Want to talk to a human agent?"
8. Use emojis sparingly (max 1-2 per response)
9. **IMPORTANT: Keep responses SHORT. Citizens prefer quick answers over detailed explanations.**
10. Remember: You are Niño, the AI assistant for MyRoxas app

Your Response (KEEP IT SHORT):
''';

      print('🔄 Calling Gemini API...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      print('✅ Gemini API response received');
      final responseText = response.text ?? 'I apologize, but I could not generate a response. Would you like to speak with a human agent?';
      print('💬 Response: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}...');
      
      return responseText;
    } catch (e) {
      print('❌ Error generating AI response: $e');
      print('Stack trace: ${StackTrace.current}');
      return 'I apologize for the technical difficulty. Would you like to connect with a human agent for assistance?';
    }
  }

  /// Check if a message requires human intervention
  Future<bool> requiresHumanAgent(String message) async {
    final lowerMessage = message.toLowerCase();
    
    // Keywords that trigger human handoff
    final handoffKeywords = [
      'speak to agent',
      'talk to agent',
      'connect to agent',
      'human agent',
      'real agent',
      'talk to human',
      'speak to human',
      'real person',
      'human support',
      'representative',
      'talk to someone',
      'speak to someone',
      'connect me to',
      'transfer me',
      'complaint',
      'urgent',
      'emergency',
      'escalate',
      'agent',
      'representative',
      'customer service',
      'support team',
      'not helpful',
      'can\'t help',
    ];

    return handoffKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Dispose the service
  void dispose() {
    _initialized = false;
  }
}
