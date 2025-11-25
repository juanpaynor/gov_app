import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradient_button.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/announcements_repository.dart';
import '../../../models/announcement.dart';
import '../../../models/announcement_category.dart';

/// Announcements screen - city news and advisories
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late final AnnouncementsRepository _repository;
  List<Announcement> _announcements = [];
  List<AnnouncementCategory> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = AnnouncementsRepository(supabase);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _repository.getCategories();
      final announcements = await _repository.getAnnouncements(
        categoryId: _selectedCategoryId,
      );

      setState(() {
        _categories = categories;
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load announcements: $e';
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipBackground = theme.colorScheme.surface.withOpacity(
      theme.brightness == Brightness.dark ? 0.7 : 1,
    );
    final mutedTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);
    final hintColor = theme.textTheme.bodySmall?.color?.withOpacity(0.6);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: const Text('Announcements')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  GradientButton(
                    onPressed: _loadData,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Category filter chips
                if (_categories.isNotEmpty)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) => _filterByCategory(null),
                            backgroundColor: chipBackground,
                            selectedColor: AppColors.capizBlue.withOpacity(0.2),
                          ),
                        ),
                        // Category chips
                        ..._categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (category.icon != null) ...[
                                    Text(
                                      category.icon!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Flexible(
                                    child: Text(
                                      category.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              selected: _selectedCategoryId == category.id,
                              onSelected: (_) => _filterByCategory(category.id),
                              backgroundColor: chipBackground,
                              selectedColor: category.colorValue.withOpacity(
                                0.2,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                // Announcements list
                Expanded(
                  child: _announcements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 80,
                                color: hintColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No announcements yet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back later for updates',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _announcements.length,
                            itemBuilder: (context, index) {
                              final announcement = _announcements[index];
                              return _AnnouncementCard(
                                announcement: announcement,
                                onTap: () {
                                  context.push(
                                    '/announcements/${announcement.id}',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);
    final hintColor = theme.textTheme.bodySmall?.color?.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured image (if available)
              if (announcement.featuredImageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    announcement.featuredImageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge and date
                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: announcement.categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: announcement.categoryColor.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                announcement.categoryIcon,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                announcement.categoryName,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: announcement.categoryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // "New" badge
                        if (announcement.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      announcement.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Excerpt
                    Text(
                      announcement.excerpt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: mutedTextColor,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Date and author
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: hintColor),
                        const SizedBox(width: 4),
                        Text(
                          announcement.formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hintColor,
                          ),
                        ),
                        if (announcement.viewCount > 0) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.visibility, size: 14, color: hintColor),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement.viewCount} views',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
