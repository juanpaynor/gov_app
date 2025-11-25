import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradient_button.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/announcements_repository.dart';
import '../../../models/announcement.dart';

/// Announcement detail screen - full article view
class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late final AnnouncementsRepository _repository;
  Announcement? _announcement;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = AnnouncementsRepository(supabase);
    _loadAnnouncement();
  }

  Future<void> _loadAnnouncement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final announcement = await _repository.getAnnouncementById(
        widget.announcementId,
      );

      // Increment view count
      await _repository.incrementViewCount(widget.announcementId);

      setState(() {
        _announcement = announcement;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load announcement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: const Text('Announcement')),
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
                    onPressed: _loadAnnouncement,
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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image
                  if (_announcement!.featuredImageUrl != null)
                    Image.network(
                      _announcement!.featuredImageUrl!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _announcement!.categoryColor.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _announcement!.categoryColor.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _announcement!.categoryIcon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _announcement!.categoryName,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: _announcement!.categoryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          _announcement!.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Meta information
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _announcement!.author,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(_announcement!.publishedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                            if (_announcement!.viewCount > 0) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.visibility,
                                size: 16,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${_announcement!.viewCount} views',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Divider(),

                        const SizedBox(height: 24),

                        // HTML Content
                        Html(
                          data: _announcement!.content,
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              fontSize: FontSize(16),
                              lineHeight: const LineHeight(1.6),
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            'p': Style(margin: Margins.only(bottom: 16)),
                            'h1, h2, h3, h4, h5, h6': Style(
                              fontWeight: FontWeight.bold,
                              margin: Margins.only(top: 20, bottom: 12),
                            ),
                            'ul, ol': Style(
                              margin: Margins.only(bottom: 16, left: 20),
                            ),
                            'li': Style(margin: Margins.only(bottom: 8)),
                            'a': Style(
                              color: theme.colorScheme.primary,
                              textDecoration: TextDecoration.underline,
                            ),
                            'strong': Style(fontWeight: FontWeight.bold),
                            'em': Style(fontStyle: FontStyle.italic),
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
