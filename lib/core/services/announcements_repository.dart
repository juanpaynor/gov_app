import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/announcement.dart';
import '../../models/announcement_category.dart';

/// Repository for managing announcements with Supabase
class AnnouncementsRepository {
  final SupabaseClient supabase;

  AnnouncementsRepository(this.supabase);

  /// Fetch all active announcement categories
  Future<List<AnnouncementCategory>> getCategories() async {
    try {
      final response = await supabase
          .from('announcement_categories')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List)
          .map((json) => AnnouncementCategory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Fetch all published announcements
  Future<List<Announcement>> getAnnouncements({
    String? categoryId,
    int? limit,
    int? offset,
    bool? isFeatured,
  }) async {
    try {
      final queryBuilder = supabase
          .from('announcements')
          .select('*, category:announcement_categories(*)')
          .eq('is_published', true);

      // Apply category filter if provided
      dynamic filteredQuery = categoryId != null
          ? queryBuilder.eq('category_id', categoryId)
          : queryBuilder;

      // Apply featured filter if provided
      if (isFeatured != null) {
        filteredQuery = filteredQuery.eq('is_featured', isFeatured);
      }

      // Apply ordering
      final orderedQuery = filteredQuery
          .order('is_featured', ascending: false)
          .order('priority', ascending: false)
          .order('published_at', ascending: false);

      // Apply pagination if provided
      dynamic finalQuery = orderedQuery;
      if (limit != null) {
        finalQuery = orderedQuery.limit(limit);
      }
      if (offset != null) {
        finalQuery = orderedQuery.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await finalQuery;

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  /// Fetch featured announcements
  Future<List<Announcement>> getFeaturedAnnouncements({int limit = 5}) async {
    try {
      final response = await supabase
          .from('announcements')
          .select('*, category:announcement_categories(*)')
          .eq('is_published', true)
          .eq('is_featured', true)
          .order('priority', ascending: false)
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured announcements: $e');
    }
  }

  /// Fetch single announcement by ID
  Future<Announcement> getAnnouncementById(String id) async {
    try {
      final response = await supabase
          .from('announcements')
          .select('*, category:announcement_categories(*)')
          .eq('id', id)
          .single();

      return Announcement.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch announcement: $e');
    }
  }

  /// Increment view count for an announcement
  Future<void> incrementViewCount(String announcementId) async {
    try {
      await supabase.rpc('increment_announcement_views', params: {
        'announcement_id': announcementId,
      });
    } catch (e) {
      // Silently fail - view count is not critical
      print('Failed to increment view count: $e');
    }
  }

  /// Search announcements by text
  Future<List<Announcement>> searchAnnouncements(String query) async {
    try {
      final response = await supabase
          .from('announcements')
          .select('*, category:announcement_categories(*)')
          .eq('is_published', true)
          .or('title.ilike.%$query%,content.ilike.%$query%,excerpt.ilike.%$query%')
          .order('published_at', ascending: false);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search announcements: $e');
    }
  }

  /// Get announcements by category slug
  Future<List<Announcement>> getAnnouncementsBySlug(String slug) async {
    try {
      // First get the category by slug
      final categoryResponse = await supabase
          .from('announcement_categories')
          .select('id')
          .eq('slug', slug)
          .eq('is_active', true)
          .single();

      final categoryId = categoryResponse['id'] as String;

      // Then get announcements for that category
      return await getAnnouncements(categoryId: categoryId);
    } catch (e) {
      throw Exception('Failed to fetch announcements by slug: $e');
    }
  }

  /// Stream real-time updates for announcements
  Stream<List<Announcement>> watchAnnouncements() {
    return supabase
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('is_published', true)
        .order('is_featured', ascending: false)
        .order('priority', ascending: false)
        .order('published_at', ascending: false)
        .map((data) => data.map((json) => Announcement.fromJson(json)).toList());
  }

  /// Get recent announcements (last 7 days)
  Future<List<Announcement>> getRecentAnnouncements({int limit = 10}) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await supabase
          .from('announcements')
          .select('*, category:announcement_categories(*)')
          .eq('is_published', true)
          .gte('published_at', sevenDaysAgo.toIso8601String())
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent announcements: $e');
    }
  }
}
