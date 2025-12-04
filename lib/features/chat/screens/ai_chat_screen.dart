import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/services/ai_faq_service.dart';
import '../../../core/services/persistent_chat_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradient_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:go_router/go_router.dart';

class AIChatScreen extends StatefulWidget {
  final bool isModal;

  const AIChatScreen({super.key, this.isModal = false});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _aiFaqService = AIFaqService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  bool _requestedAgent = false;
  String _userLanguage = '';
  bool _isConnectingAgent = false;
  bool _isClosing = false;
  bool _conversationEnded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedMessages();
    _initializeChat();
    _checkExistingAgentConnection();
  }

  /// Check if there's an existing agent connection
  void _checkExistingAgentConnection() {
    final chatService = context.read<PersistentChatService>();
    if (chatService.isConnected) {
      setState(() {
        _requestedAgent = true;
      });
    }
  }

  /// Load saved messages from SharedPreferences
  Future<void> _loadSavedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Check if conversation was ended - if so, don't load messages
      final conversationEnded = prefs.getBool('chat_ended_${user.id}') ?? false;
      if (conversationEnded) {
        print('🆕 Previous conversation was ended - starting fresh');
        // Clear the ended flag now that we've acknowledged it
        await prefs.remove('chat_ended_${user.id}');
        await prefs.remove('chat_messages_${user.id}');
        return;
      }

      final savedMessagesJson = prefs.getString('chat_messages_${user.id}');
      if (savedMessagesJson != null) {
        final List<dynamic> messagesList = jsonDecode(savedMessagesJson);
        final messages = messagesList
            .map((m) => ChatMessage.fromJson(m))
            .toList();

        if (mounted) {
          setState(() {
            _messages.addAll(messages);
            _isLoading = false;
          });
        }
        print('✅ Loaded ${messages.length} saved messages');
      }
    } catch (e) {
      print('⚠️ Error loading saved messages: $e');
    }
  }

  /// Save messages to SharedPreferences
  Future<void> _saveMessages() async {
    // Don't save if conversation was ended
    if (_conversationEnded) {
      print('⏭️ Skipping save - conversation ended');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Only save non-system messages
      final messagesToSave = _messages.where((m) => !m.isSystem).toList();
      final messagesJson = jsonEncode(
        messagesToSave.map((m) => m.toJson()).toList(),
      );
      await prefs.setString('chat_messages_${user.id}', messagesJson);
      print('💾 Saved ${messagesToSave.length} messages');
    } catch (e) {
      print('⚠️ Error saving messages: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      print('🔧 Initializing chat...');
      final user = Supabase.instance.client.auth.currentUser;

      // Handle guest users
      if (user == null) {
        print('⚠️ User not authenticated - showing guest message');
        setState(() {
          _isLoading = false;
          _messages.add(
            ChatMessage(
              text:
                  '👋 Hello!\n\nTo use the chat support, please log in or create an account first.\n\n'
                  'This allows us to:\n'
                  '• Save your conversation history\n'
                  '• Connect you with our support team\n'
                  '• Provide personalized assistance',
              isUser: false,
              isSystem: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        return;
      }

      print('✅ User authenticated: ${user.id}');

      // Get Gemini API key
      final apiKey = SupabaseConfig.geminiApiKey;

      // Initialize AI FAQ service with Gemini API key
      print('🤖 Initializing AI FAQ service...');
      await _aiFaqService.initialize(apiKey);
      print('✅ AI FAQ service initialized successfully');

      setState(() {
        _isLoading = false;
        // Only add welcome message if no saved messages
        if (_messages.isEmpty) {
          _messages.add(
            ChatMessage(
              text:
                  'Hello! 👋 Kumusta!\n\nI\'m Niño, your AI assistant for Roxas City services.\n\nWhat language would you prefer?\n\n🇬🇧 English\n🇵🇭 Tagalog\n🇵🇭 Hiligaynon (Ilonggo)',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        }
      });
      print('✅ Chat initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing chat: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            text:
                '⚠️ AI service failed to initialize. You can still request a human agent.',
            isUser: false,
            isSystem: true,
            timestamp: DateTime.now(),
          ),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize chat: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    print('📤 Sending message: "$text"');

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _saveMessages();
    _messageController.clear();
    _scrollToBottom();

    try {
      // Check if this is language selection (first interaction)
      if (_userLanguage.isEmpty && _messages.length == 2) {
        final lowerText = text.toLowerCase();
        if (lowerText.contains('english') || lowerText.contains('eng')) {
          _userLanguage = 'English';
        } else if (lowerText.contains('tagalog') || lowerText.contains('tag')) {
          _userLanguage = 'Tagalog';
        } else if (lowerText.contains('hiligaynon') ||
            lowerText.contains('ilonggo') ||
            lowerText.contains('hilig')) {
          _userLanguage = 'Hiligaynon';
        }

        if (_userLanguage.isNotEmpty) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: _getGreetingInLanguage(_userLanguage),
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isTyping = false;
          });
          _saveMessages();
          _scrollToBottom();
          return;
        }
      }

      print('🔍 Checking if message requires human agent...');
      // Check if user wants to talk to human agent
      final needsAgent = await _aiFaqService.requiresHumanAgent(text);
      print('🤔 Requires agent: $needsAgent');

      if (needsAgent && !_requestedAgent) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  'I understand you\'d like to speak with a human agent. Let me connect you to our support team.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _saveMessages();
        _scrollToBottom();

        // Show dialog to confirm
        if (mounted) {
          await _showAgentRequestDialog();
        }
      } else {
        print('🤖 Generating AI response...');

        // Build conversation history (last 10 messages, excluding system messages)
        final conversationHistory = _messages
            .where((m) => !m.isSystem)
            .toList()
            .reversed
            .take(10)
            .toList()
            .reversed
            .map(
              (m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'message': m.text,
              },
            )
            .toList();

        // Generate AI response with language preference and conversation history
        final languageContext = _userLanguage.isNotEmpty
            ? '\n\nIMPORTANT: User prefers $_userLanguage language. Respond primarily in $_userLanguage.'
            : '';
        final aiResponse = await _aiFaqService.generateResponse(
          text + languageContext,
          conversationHistory: conversationHistory,
        );
        print(
          '✅ AI response received: "${aiResponse.substring(0, aiResponse.length > 50 ? 50 : aiResponse.length)}..."',
        );

        setState(() {
          _messages.add(
            ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _saveMessages();
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error handling message: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  String _getGreetingInLanguage(String language) {
    switch (language) {
      case 'Tagalog':
        return 'Salamat! 🇵🇭 Ako si Niño, at magtanong ka lang kung may kailangan ka. Paano kita matutulungan ngayon?';
      case 'Hiligaynon':
        return 'Salamat gid! 🇵🇭 Ako si Niño, kag pamangkot lang kung ano ang imo kinahanglan. Paano ko ikaw mabuligan subong?';
      default:
        return 'Great! 🇬🇧 I\'m Niño, and I\'m here to help. Feel free to ask me anything. How can I help you today?';
    }
  }

  Future<void> _showAgentRequestDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Human Agent'),
        content: const Text(
          'Would you like to open a chat room with our human support team? '
          'You can start typing right away and an agent will reply as soon as they are available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          GradientButton(
            onPressed: () {
              Navigator.pop(context);
              _requestHumanAgent();
            },
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Text('Connect to Agent'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestHumanAgent() async {
    setState(() {
      _requestedAgent = true;
      _messages.add(
        ChatMessage(
          text:
              '🔄 Opening a chat room with our support team...\n\nYou can start typing your concern and an agent will reply as soon as they are available.',
          isUser: false,
          isSystem: true,
          timestamp: DateTime.now(),
        ),
      );
      _isConnectingAgent = true;
    });
    _scrollToBottom();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Prepare chat summary for handoff
      final chatSummary = _messages
          .where((m) => !m.isSystem)
          .map(
            (m) => {
              'role': m.isUser ? 'user' : 'ai',
              'message': m.text,
              'timestamp': m.timestamp.toIso8601String(),
            },
          )
          .toList();

      // Use persistent chat service
      final chatService = context.read<PersistentChatService>();
      final success = await chatService.requestHumanAgent(
        userName: user.userMetadata?['full_name'] ?? 'User',
        userEmail: user.email ?? '',
        languagePreference: _userLanguage.isEmpty ? 'English' : _userLanguage,
        chatSummary: chatSummary,
      );

      if (success) {
        setState(() {
          _isConnectingAgent = false;
          _messages.add(
            ChatMessage(
              text:
                  '✅ Chat room created!\n\n'
                  'Connected to live chat with agent...',
              isUser: false,
              isSystem: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to agent!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to request agent');
      }
    } catch (e) {
      print('❌ Error requesting agent: $e');
      setState(() {
        _requestedAgent = false;
        _isConnectingAgent = false;
        _messages.add(
          ChatMessage(
            text:
                '❌ Failed to connect to support team. Please try again or contact us directly.',
            isUser: false,
            isSystem: true,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _closeConversation({int? rating}) async {
    final chatService = context.read<PersistentChatService>();

    setState(() {
      _isClosing = true;
    });

    try {
      // Close agent connection if it exists
      if (chatService.isConnected) {
        await chatService.closeConversation(rating: rating);
      }

      // Always clear messages regardless of agent connection
      print('🧹 Starting conversation cleanup...');

      // Clear messages from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final key = 'chat_messages_${user.id}';
        final beforeClear = prefs.getString(key);
        print('📝 Messages before clear: ${beforeClear?.substring(0, 50)}...');

        await prefs.remove(key);
        // Set a flag so next time we load, we know conversation was ended
        await prefs.setBool('chat_ended_${user.id}', true);

        final afterClear = prefs.getString(key);
        print(
          '🧹 Cleared saved messages from SharedPreferences - verified: ${afterClear == null}',
        );
      }

      // Clear all messages and reset to fresh state
      if (mounted) {
        setState(() {
          _isClosing = false;
          _requestedAgent = false;
          _messages.clear();
          _userLanguage = '';
          _conversationEnded = true; // Mark conversation as ended
          print(
            '✅ Messages cleared in memory: ${_messages.length} messages remaining',
          );
        });

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation ended successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Close the chat screen after a brief delay
        print('🚪 Closing chat screen...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
          print('✅ Chat screen closed');
        }
      }
    } catch (e) {
      print('❌ Error closing conversation: $e');
      if (mounted) {
        setState(() {
          _isClosing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCloseDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Flexible(child: Text('End Conversation?')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '⚠️ Warning: This will permanently end the conversation.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Typically, the agent closes the conversation when your case is resolved. Closing now may interrupt active support.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Text(
                  '💡 Better option: Just minimize or navigate away. Your conversation stays active and the agent can still help you.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Open'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _closeConversation();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('End Anyway'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final user = Supabase.instance.client.auth.currentUser;

    // Show login button for guest users
    if (user == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close chat modal
              context.push('/login');
            },
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.login),
                SizedBox(width: 8),
                Text('Log In to Chat'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close chat modal
              context.push('/signup');
            },
            child: const Text('Don\'t have an account? Sign Up'),
          ),
        ],
      );
    }

    // Regular message input for logged-in users
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardDark
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.gray700
                    : AppColors.gray200,
              ),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isTyping,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.capizBlue,
                AppColors.capizBlue.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.capizBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isTyping ? null : _sendMessage,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.send_rounded,
                  color: _isTyping ? Colors.white54 : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<PersistentChatService>();
    print(
      '🔍 Build called - isConnected: ${chatService.isConnected}, streamChannel: ${chatService.streamChannel != null}, streamChatClient: ${chatService.streamChatClient != null}',
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: widget.isModal
            ? Colors.transparent
            : Theme.of(context).colorScheme.background,
        appBar: widget.isModal
            ? null
            : AppBar(
                title: const Text('AI Support Chat'),
                backgroundColor: AppColors.capizBlue,
                foregroundColor: Colors.white,
              ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show Stream Chat UI when agent is connected
    if (chatService.isConnected &&
        chatService.streamChannel != null &&
        chatService.streamChatClient != null) {
      return StreamChat(
        client: chatService.streamChatClient!,
        child: StreamChatTheme(
          data: StreamChatThemeData.light().copyWith(
            colorTheme: StreamColorTheme.light().copyWith(
              accentPrimary: AppColors.capizBlue,
            ),
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              // Show warning dialog before closing
              final shouldClose = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Minimize Chat?'),
                  content: const Text(
                    'You have an active conversation with an agent. '
                    'Closing will disconnect you from the chat.\n\n'
                    'To keep the conversation active, use the app normally and return here later.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Stay in Chat'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Close Anyway'),
                    ),
                  ],
                ),
              );

              if (shouldClose == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: StreamChannel(
              channel: chatService.streamChannel!,
              child: Scaffold(
                backgroundColor: widget.isModal
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.background,
                appBar: widget.isModal
                    ? null
                    : AppBar(
                        title: const Text('Chat with Agent'),
                        backgroundColor: AppColors.capizBlue,
                        foregroundColor: Colors.white,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'End Chat Session',
                            onPressed: _showCloseDialog,
                          ),
                        ],
                      ),
                body: Column(
                  children: [
                    // Header for modal
                    if (widget.isModal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.capizBlue,
                              AppColors.capizBlue.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chat with Agent',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Live support',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: _showCloseDialog,
                            ),
                          ],
                        ),
                      ),
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.success.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Connected with support agent. You\'ll get a response shortly.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stream Chat Messages with gray background
                    Expanded(
                      child: Container(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.backgroundDark
                            : AppColors.gray50,
                        child: StreamMessageListView(
                          showScrollToBottom: true,
                          messageBuilder:
                              (context, details, messages, defaultMessage) {
                                return defaultMessage.copyWith(
                                  showUserAvatar: DisplayWidget.gone,
                                  borderRadiusGeometry: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      details.isMyMessage ? 20 : 4,
                                    ),
                                    topRight: Radius.circular(
                                      details.isMyMessage ? 4 : 20,
                                    ),
                                    bottomLeft: const Radius.circular(20),
                                    bottomRight: const Radius.circular(20),
                                  ),
                                  messageTheme: StreamMessageThemeData(
                                    messageBackgroundColor: details.isMyMessage
                                        ? AppColors.capizBlue
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? AppColors.cardDark
                                        : Colors.white,
                                    messageTextStyle: TextStyle(
                                      color: details.isMyMessage
                                          ? Colors.white
                                          : Theme.of(context).brightness ==
                                                Brightness.dark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                    createdAtStyle: TextStyle(
                                      color: details.isMyMessage
                                          ? Colors.white.withOpacity(0.7)
                                          : Theme.of(context).brightness ==
                                                Brightness.dark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                    ),
                    // Stream Chat Input (text only, no extra buttons)
                    StreamMessageInput(
                      disableAttachments: true,
                      actionsBuilder: (context, defaultActions) => [],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Show AI Chat UI (original interface)
    return Scaffold(
      backgroundColor: widget.isModal
          ? Colors.transparent
          : Theme.of(context).colorScheme.background,
      appBar: widget.isModal
          ? null
          : AppBar(
              title: const Text('AI Support Chat'),
              backgroundColor: AppColors.capizBlue,
              foregroundColor: Colors.white,
              actions: [
                if (!_requestedAgent)
                  IconButton(
                    icon: const Icon(Icons.support_agent),
                    tooltip: 'Request Human Agent',
                    onPressed: _requestHumanAgent,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close Chat',
                  onPressed: _showCloseDialog,
                ),
              ],
            ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header (only for modal)
              if (widget.isModal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.capizBlue,
                        AppColors.capizBlue.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Support Assistant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Online • Ready to help',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_requestedAgent)
                        IconButton(
                          icon: const Icon(
                            Icons.support_agent,
                            color: Colors.white,
                          ),
                          tooltip: 'Request Human Agent',
                          onPressed: _requestHumanAgent,
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close Chat',
                        onPressed: _showCloseDialog,
                      ),
                    ],
                  ),
                ),
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _requestedAgent
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.info.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: _requestedAgent
                          ? AppColors.warning.withOpacity(0.3)
                          : AppColors.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _requestedAgent ? Icons.schedule : Icons.info_outline,
                      color: _requestedAgent
                          ? AppColors.warning
                          : AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _requestedAgent
                            ? 'Waiting for a human agent... We\'ll connect you shortly.'
                            : 'Ask me anything! I\'m here to help with city services.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Message list
              Expanded(
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.backgroundDark
                      : AppColors.gray50,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
              ),
              // Typing indicator
              if (_isTyping)
                Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.backgroundDark
                      : AppColors.gray50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.cardDark
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTypingDot(0),
                            const SizedBox(width: 4),
                            _buildTypingDot(1),
                            const SizedBox(width: 4),
                            _buildTypingDot(2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Message input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(child: _buildMessageInput()),
              ),
              // Loading overlay when connecting to agent
              if (_isConnectingAgent)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.cardDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.capizBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting to agent chat...',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Loading overlay during conversation close
              if (_isClosing)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.cardDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.capizBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ending conversation...',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: message.isSystem
                    ? LinearGradient(
                        colors: [
                          AppColors.info,
                          AppColors.info.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.capizGold,
                          AppColors.capizGold.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: message.isSystem
                        ? AppColors.info.withOpacity(0.3)
                        : AppColors.capizGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                message.isSystem ? Icons.info_rounded : Icons.smart_toy_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [
                          AppColors.capizBlue,
                          AppColors.capizBlue.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUser
                    ? null
                    : message.isSystem
                    ? AppColors.info.withOpacity(0.08)
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.cardDark
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isUser ? 20 : 4),
                  topRight: Radius.circular(message.isUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: message.isUser
                    ? [
                        BoxShadow(
                          color: AppColors.capizBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.capizBlue,
                    AppColors.capizBlue.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.capizBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value + delay) % 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.capizBlue.withOpacity(0.3 + (animValue * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // Clear saved messages if conversation was ended (do async work)
    if (_conversationEnded) {
      _clearMessagesAsync();
    }

    super.dispose();
  }

  Future<void> _clearMessagesAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await prefs.remove('chat_messages_${user.id}');
        print('🗑️ Cleared saved messages on dispose');
      }
    } catch (e) {
      print('⚠️ Error clearing messages on dispose: $e');
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isSystem;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isSystem = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'isSystem': isSystem,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      isSystem: json['isSystem'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
