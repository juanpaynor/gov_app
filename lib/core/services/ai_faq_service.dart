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

  /// Generate a response using Gemini AI with conversation context
  Future<String> generateResponse(
    String userMessage, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    if (!_initialized) {
      throw Exception('AI FAQ Service not initialized');
    }

    try {
      print('🤖 AI Service: Generating response for: "$userMessage"');

      // Build context from FAQs
      final faqContext = await _buildFAQContext();
      print('📚 FAQ Context loaded: ${faqContext.length} characters');

      // Build conversation history context
      final conversationContext = _buildConversationContext(
        conversationHistory,
      );
      print(
        '💬 Conversation context: ${conversationContext.length} characters',
      );

      // Detect sentiment/urgency
      final sentiment = _detectSentiment(userMessage);
      print('😊 Sentiment detected: $sentiment');

      // Create the prompt with context
      final prompt =
          '''
You are Niño, a friendly, empathetic, and proactive AI assistant for the MyRoxas mobile app - the official government services app for Roxas City, Philippines.

**Your Personality:**
- Conversational and natural (like texting a helpful friend)
- Ask clarifying questions when needed
- Suggest helpful next steps proactively
- Show empathy for user concerns
- Use casual Bisaya/Hiligaynon phrases when appropriate (like "Maayo!", "Sige!", "Aw oo!", "Gid!", "Bala")
- Celebrate user actions ("Great! 🎉", "Maayo gid na! ✨")

**LANGUAGE SUPPORT:**
- **English**: Standard conversational English
- **Tagalog**: Natural Filipino conversational style
- **Hiligaynon (Ilonggo)**: Use PROPER Hiligaynon grammar and vocabulary:
  * Common words: "gid" (emphasis), "sang" (of/when), "sa" (to/at), "nga" (that/which)
  * Verbs: "mabuligan" (help), "mahimo" (can/possible), "magpangabay" (wait)
  * Questions: "Ano" (what), "Diin" (where), "Sin-o" (who), "Ngaa" (why)
  * Phrases: "Salamat gid" (thank you very much), "Maayo gid" (very good), "Wala problema" (no problem)
  * Example: "Pwede ko ikaw mabuligan sa imo kinahanglan" (I can help you with what you need)
  * DON'T mix Tagalog grammar into Hiligaynon - keep it pure Ilonggo!

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

$conversationContext

**Current User Message:** $userMessage
${sentiment == 'frustrated' || sentiment == 'urgent' ? '⚠️ **IMPORTANT:** User seems $sentiment. Be extra helpful and consider suggesting human agent.' : ''}

**CRITICAL LANGUAGE NOTE:**
${userMessage.contains('Hiligaynon') ? '🇵🇭 **RESPOND IN PURE HILIGAYNON (ILONGGO)** - Use proper Ilonggo grammar, not Tagalog mixed with Hiligaynon words! Think like a native Roxas City resident speaking Hiligaynon.' : ''}
${userMessage.contains('Tagalog') ? '🇵🇭 **RESPOND IN TAGALOG** - Use natural Filipino conversational style.' : ''}

Instructions:
1. **Review conversation history** - Remember what was discussed, don't repeat yourself
2. Answer based on FAQ data, MyRoxas features, AND previous conversation context
3. **BE BRIEF AND CONVERSATIONAL** - Text like a helpful friend, not an essay
4. **Response length rules:**
   - Simple questions → 1-2 sentences MAX
   - Medium questions → 2-4 sentences MAX
   - Complex questions → 5-7 sentences MAX, then suggest next step
5. **Be PROACTIVE:**
   - After answering, suggest a helpful next action ("Want me to guide you?", "Should I connect you to an agent?")
   - If user seems confused, ask clarifying questions ("Which barangay?", "Do you have a photo?")
   - Detect intent and guide forward ("Sounds like you want to report this. Shall we start?")
6. **Show EMPATHY:**
   - If frustrated/urgent → "I understand this is urgent. Let me help quickly."
   - If confused → "No worries, let me explain differently."
   - If successful → "Great! Maayo na! 🎉"
7. **Smart suggestions:**
   - Offer relevant actions based on topic ("📋 Report this", "📅 Book appointment", "👤 Talk to agent")
   - Guide multi-step processes ("First, let's..., then...")
8. **Cut fluff** - No "I'd be happy to", "Great question". Just answer + suggest action
9. If you can't help confidently → "Hmm, I'm not 100% sure. Want to talk to a human agent who knows better?"
10. Use emojis sparingly (max 2 per response)
11. **CRITICAL: Keep responses SHORT but HELPFUL. End with a suggested next step or question.**
12. Remember: You are Niño 🤖

Your Response (KEEP IT SHORT):
''';

      print('🔄 Calling Gemini API...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      print('✅ Gemini API response received');
      final responseText =
          response.text ??
          'I apologize, but I could not generate a response. Would you like to speak with a human agent?';
      print(
        '💬 Response: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}...',
      );

      return responseText;
    } catch (e) {
      print('❌ Error generating AI response: $e');
      print('Stack trace: ${StackTrace.current}');

      // Check if it's an overload error
      if (e.toString().contains('overloaded') || e.toString().contains('503')) {
        return 'Ayaw! Sorry, I\'m a bit busy right now (too many users). 😅 Try again in a few seconds, or I can connect you to a human agent?';
      }

      return 'I apologize for the technical difficulty. Would you like to connect with a human agent for assistance?';
    }
  }

  /// Build conversation context from message history
  String _buildConversationContext(List<Map<String, String>>? history) {
    if (history == null || history.isEmpty) {
      return '**Conversation History:** (This is the first message)';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      '**Conversation History (Last ${history.length} messages):**',
    );

    for (var i = 0; i < history.length; i++) {
      final msg = history[i];
      final role = msg['role'] == 'user' ? 'User' : 'You (Niño)';
      buffer.writeln('$role: ${msg['message']}');
    }

    buffer.writeln('\n💡 Remember this context when responding!');
    return buffer.toString();
  }

  /// Detect sentiment/urgency in user message
  String _detectSentiment(String message) {
    final lowerMessage = message.toLowerCase();

    // Frustrated keywords
    final frustratedKeywords = [
      'not working',
      'doesn\'t work',
      'won\'t work',
      'broken',
      'useless',
      'terrible',
      'frustrated',
      'annoying',
      'again',
      'still',
      'why',
      'confused',
      'don\'t understand',
      'makes no sense',
      'stupid',
    ];

    // Urgent keywords
    final urgentKeywords = [
      'urgent',
      'emergency',
      'asap',
      'immediately',
      'right now',
      'quickly',
      'hurry',
      'fast',
      'critical',
      'serious',
      'help',
      'please help',
    ];

    if (urgentKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return 'urgent';
    }

    if (frustratedKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return 'frustrated';
    }

    return 'neutral';
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
