import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/announcement.dart';
import 'announcements_repository.dart';
import 'supabase_service.dart';

/// Service for managing in-app notifications for important announcements
class InAppNotificationService extends ChangeNotifier {
  static const String _seenAnnouncementsKey = 'seen_announcement_ids';
  static const Duration _pollInterval = Duration(minutes: 5);

  final AnnouncementsRepository _repository = AnnouncementsRepository(supabase);
  Timer? _pollTimer;
  List<String> _seenAnnouncementIds = [];
  Announcement? _currentNotification;
  bool _isActive = false;

  /// Current notification to display
  Announcement? get currentNotification => _currentNotification;

  /// Check if service is actively polling
  bool get isActive => _isActive;

  InAppNotificationService() {
    _loadSeenAnnouncements();
  }

  /// Load seen announcements from local storage
  Future<void> _loadSeenAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seenAnnouncementIds = prefs.getStringList(_seenAnnouncementsKey) ?? [];
    } catch (e) {
      debugPrint('Error loading seen announcements: $e');
      _seenAnnouncementIds = [];
    }
  }

  /// Save seen announcements to local storage
  Future<void> _saveSeenAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenAnnouncementsKey, _seenAnnouncementIds);
    } catch (e) {
      debugPrint('Error saving seen announcements: $e');
    }
  }

  /// Start polling for important announcements
  void startPolling() {
    if (_isActive) return;

    _isActive = true;

    // Check immediately
    _checkForImportantAnnouncements();

    // Then check periodically
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _checkForImportantAnnouncements();
    });
  }

  /// Stop polling
  void stopPolling() {
    _isActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Check for new important announcements
  Future<void> _checkForImportantAnnouncements() async {
    try {
      // Get high-priority announcements published in last 24 hours
      final announcements = await _repository.getAnnouncements(limit: 10);

      final importantAnnouncements = announcements.where((a) {
        // Check if priority > 0, published, and not seen
        if (a.priority <= 0 || !a.isPublished) return false;
        if (_seenAnnouncementIds.contains(a.id)) return false;

        // Only show announcements from last 24 hours
        final hoursSincePublished = DateTime.now()
            .difference(a.publishedAt)
            .inHours;
        return hoursSincePublished <= 24;
      }).toList();

      // Sort by priority (highest first) and take the first one
      if (importantAnnouncements.isNotEmpty) {
        importantAnnouncements.sort((a, b) => b.priority.compareTo(a.priority));
        _showNotification(importantAnnouncements.first);
      }
    } catch (e) {
      debugPrint('Error checking for important announcements: $e');
    }
  }

  /// Show notification banner
  void _showNotification(Announcement announcement) {
    _currentNotification = announcement;
    notifyListeners();
  }

  /// Mark announcement as seen and dismiss notification
  void dismissNotification(String announcementId) {
    if (!_seenAnnouncementIds.contains(announcementId)) {
      _seenAnnouncementIds.add(announcementId);
      _saveSeenAnnouncements();
    }

    _currentNotification = null;
    notifyListeners();
  }

  /// Get count of unseen important announcements
  Future<int> getUnseenCount() async {
    try {
      final announcements = await _repository.getAnnouncements(limit: 50);

      final unseenCount = announcements.where((a) {
        if (a.priority <= 0 || !a.isPublished) return false;
        if (_seenAnnouncementIds.contains(a.id)) return false;

        final hoursSincePublished = DateTime.now()
            .difference(a.publishedAt)
            .inHours;
        return hoursSincePublished <= 168; // Last 7 days
      }).length;

      return unseenCount;
    } catch (e) {
      debugPrint('Error getting unseen count: $e');
      return 0;
    }
  }

  /// Clear all seen announcements (for testing)
  Future<void> clearSeenAnnouncements() async {
    _seenAnnouncementIds.clear();
    await _saveSeenAnnouncements();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
