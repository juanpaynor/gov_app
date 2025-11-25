import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/announcements_repository.dart';
import '../../../models/announcement.dart';

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();

  static _NewsCarouselState? of(BuildContext context) {
    return context.findAncestorStateOfType<_NewsCarouselState>();
  }
}

class _NewsCarouselState extends State<NewsCarousel> {
  final PageController _pageController = PageController();
  final AnnouncementsRepository _repository = AnnouncementsRepository(supabase);
  int _currentPage = 0;
  Timer? _timer;
  List<Announcement> _featuredAnnouncements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedAnnouncements();
  }

  Future<void> _loadFeaturedAnnouncements() async {
    try {
      final announcements = await _repository.getAnnouncements(
        isFeatured: true,
      );
      if (mounted) {
        setState(() {
          _featuredAnnouncements = announcements
              .where((a) => a.featuredImageUrl != null)
              .toList();
          _isLoading = false;
        });

        if (_featuredAnnouncements.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Public method to reload carousel data
  Future<void> refresh() async {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });
    await _loadFeaturedAnnouncements();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _featuredAnnouncements.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_featuredAnnouncements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _featuredAnnouncements.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final announcement = _featuredAnnouncements[index];
              return GestureDetector(
                onTap: () => context.push('/announcements/${announcement.id}'),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.capizBlue.withOpacity(0.2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        announcement.featuredImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: AppColors.gray200),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            announcement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_featuredAnnouncements.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.capizBlue
                    : AppColors.capizBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }
}
