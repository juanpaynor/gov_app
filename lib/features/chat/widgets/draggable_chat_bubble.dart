import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../screens/ai_chat_screen.dart';

class DraggableChatBubble extends StatefulWidget {
  const DraggableChatBubble({super.key});

  @override
  State<DraggableChatBubble> createState() => _DraggableChatBubbleState();
}

class _DraggableChatBubbleState extends State<DraggableChatBubble>
    with SingleTickerProviderStateMixin {
  late Offset _position;
  late Size _screenSize;
  bool _isDragging = false;
  int _unreadCount = 0; // TODO: Connect to actual message count
  late AnimationController _pulseController;

  static const double _bubbleSize = 56.0;
  static const String _positionKeyX = 'chat_bubble_x';
  static const String _positionKeyY = 'chat_bubble_y';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadSavedPosition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    // Initialize position if not loaded yet
    if (_position == Offset.zero) {
      _position = Offset(
        _screenSize.width - _bubbleSize - 16,
        _screenSize.height - _bubbleSize - 100,
      );
    }
  }

  Future<void> _loadSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_positionKeyX);
    final y = prefs.getDouble(_positionKeyY);

    if (x != null && y != null && mounted) {
      setState(() {
        _position = Offset(x, y);
      });
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_positionKeyX, _position.dx);
    await prefs.setDouble(_positionKeyY, _position.dy);
  }

  void _snapToEdge() {
    final centerX = _position.dx + _bubbleSize / 2;
    final snapToLeft = centerX < _screenSize.width / 2;

    setState(() {
      _position = Offset(
        snapToLeft ? 16 : _screenSize.width - _bubbleSize - 16,
        _position.dy,
      );
    });

    _savePosition();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = Offset(
        (_position.dx + details.delta.dx).clamp(
          0,
          _screenSize.width - _bubbleSize,
        ),
        (_position.dy + details.delta.dy).clamp(
          0,
          _screenSize.height - _bubbleSize,
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _snapToEdge();
  }

  void _openChat() {
    setState(() {
      _unreadCount = 0; // Reset badge on open
    });

    // Determine if bubble is on left or right side
    final isOnLeft = _position.dx < _screenSize.width / 2;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: isOnLeft ? Alignment.bottomLeft : Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
              left: isOnLeft ? 16 : 0,
              right: isOnLeft ? 0 : 16,
              bottom: 100,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: _screenSize.width - 32,
                height: _screenSize.height * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  child: AIChatScreen(isModal: true),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Slide and fade animation from bubble position
        final slideAnimation =
            Tween<Offset>(
              begin: Offset(isOnLeft ? -0.3 : 0.3, 0.3),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: _openChat,
        child: AnimatedScale(
          scale: _isDragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final shouldPulse = _unreadCount > 0 && !_isDragging;
              final scale = shouldPulse
                  ? 1.0 + (_pulseController.value * 0.1)
                  : 1.0;

              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: _bubbleSize,
              height: _bubbleSize,
              decoration: BoxDecoration(
                color: AppColors.capizBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDragging ? 0.3 : 0.2),
                    blurRadius: _isDragging ? 16 : 8,
                    offset: Offset(0, _isDragging ? 6 : 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Chat icon
                  const Center(
                    child: Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  // Badge for unread messages
                  if (_unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
