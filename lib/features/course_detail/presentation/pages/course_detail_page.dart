import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../course_content/domain/entities/course_content.dart';
import '../../../course_content/presentation/bloc/course_content_bloc.dart';
import '../../data/datasources/course_detail_remote_datasource.dart';

class CourseDetailPage extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final String? imageUrl;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.imageUrl,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  Course? _course;
  bool _courseLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    try {
      final ds = sl<CourseDetailRemoteDataSource>();
      final course = await ds.getCourseDetail(widget.courseId);
      if (mounted)
        setState(() {
          _course = course;
          _courseLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _courseLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) =>
          sl<CourseContentBloc>()
            ..add(LoadCourseContent(courseId: widget.courseId)),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ─── Hero App Bar ───
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.courseTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ),
                    // Gradient overlay for readability
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () {
                    // Share course link
                  },
                ),
              ],
            ),

            // ─── Course Info Card ───
            SliverToBoxAdapter(
              child: _courseLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _course != null
                  ? FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: _CourseInfoCard(course: _course!),
                    )
                  : const SizedBox(),
            ),

            // ─── Tab-like section: Content ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  tr('courses.course_content'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ─── Course Content Sections ───
            BlocBuilder<CourseContentBloc, CourseContentState>(
              builder: (context, state) {
                if (state is CourseContentLoading) {
                  return const SliverToBoxAdapter(child: _DetailShimmer());
                }

                if (state is CourseContentError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 8),
                            Text(state.message),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: Text(tr('common.retry')),
                              onPressed: () =>
                                  context.read<CourseContentBloc>().add(
                                    LoadCourseContent(
                                      courseId: widget.courseId,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (state is CourseContentLoaded) {
                  if (state.sections.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: AppColors.textTertiaryLight,
                              ),
                              const SizedBox(height: 8),
                              Text(tr('content.no_content')),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final section = state.sections[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: index * 60),
                        child: _DetailSectionCard(
                          section: section,
                          courseId: widget.courseId,
                          initiallyExpanded: index == 0,
                        ),
                      );
                    }, childCount: state.sections.length),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

// ─── Course Info Card ───
class _CourseInfoCard extends StatelessWidget {
  final Course course;
  const _CourseInfoCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = course.progress ?? 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full name
            Text(
              course.fullName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (course.summary != null && course.summary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _stripHtml(course.summary!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: LinearPercentIndicator(
                    lineHeight: 8,
                    percent: (progress / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${progress.toInt()}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Meta chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (course.categoryName != null)
                  _InfoChip(icon: Icons.category, label: course.categoryName!),
                if (course.shortName.isNotEmpty)
                  _InfoChip(icon: Icons.code, label: course.shortName),
                if (course.enrolledUserCount != null)
                  _InfoChip(
                    icon: Icons.people,
                    label:
                        '${course.enrolledUserCount} ${tr("courses.students")}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─── Section Card with Modules ───
class _DetailSectionCard extends StatefulWidget {
  final CourseSection section;
  final int courseId;
  final bool initiallyExpanded;

  const _DetailSectionCard({
    required this.section,
    required this.courseId,
    this.initiallyExpanded = false,
  });

  @override
  State<_DetailSectionCard> createState() => _DetailSectionCardState();
}

class _DetailSectionCardState extends State<_DetailSectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = widget.section.modules
        .where((m) => m.completionState == 1)
        .length;
    final totalModules = widget.section.modules.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _expanded ? AppColors.primarySurface : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.section.sectionNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.name.isNotEmpty
                              ? widget.section.name
                              : tr('content.section_unnamed'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (totalModules > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount / $totalModules ${tr("content.activities")}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: widget.section.modules.map((module) {
                return _DetailModuleItem(
                  module: module,
                  courseId: widget.courseId,
                );
              }).toList(),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ─── Module Item with Navigation ───
class _DetailModuleItem extends StatelessWidget {
  final CourseModule module;
  final int courseId;

  const _DetailModuleItem({required this.module, required this.courseId});

  IconData _getModuleIcon() {
    if (module.isQuiz) return Icons.quiz_rounded;
    if (module.isAssignment) return Icons.assignment_rounded;
    if (module.isForum) return Icons.forum_rounded;
    if (module.isResource || module.isFolder) return Icons.folder_rounded;
    if (module.isUrl) return Icons.link_rounded;
    if (module.isPage) return Icons.article_rounded;
    if (module.isLabel) return Icons.label_rounded;
    if (module.isVideo) return Icons.play_circle_rounded;
    if (module.isScorm) return Icons.smart_display_rounded;
    if (module.isH5P) return Icons.extension_rounded;
    if (module.isBBB) return Icons.video_camera_front_rounded;
    if (module.isBook) return Icons.menu_book_rounded;
    if (module.isLesson) return Icons.school_rounded;
    return Icons.extension_rounded;
  }

  Color _getModuleColor() {
    if (module.isQuiz) return AppColors.accent;
    if (module.isAssignment) return AppColors.warning;
    if (module.isForum) return AppColors.info;
    if (module.isVideo) return Colors.deepPurple;
    if (module.isBBB) return Colors.red;
    if (module.isResource || module.isFolder) return AppColors.secondary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getModuleColor();
    final isCompleted = module.completionState == 1;

    if (module.isLabel) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          module.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _onModuleTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getModuleIcon(), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.modName.replaceAll('_', ' ').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (module.completionState != null)
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isCompleted ? AppColors.success : AppColors.divider,
                size: 22,
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _onModuleTap(BuildContext context) {
    // Determine content type and navigate
    if (module.isResource || module.isFolder) {
      _openResourceContent(context);
    } else if (module.isPage || module.isBook || module.isLesson) {
      context.push(
        '/content/html',
        extra: {
          'title': module.name,
          'url': module.url,
          'description': module.description,
          'contents': module.contents,
        },
      );
    } else if (module.isUrl) {
      context.push(
        '/content/html',
        extra: {
          'title': module.name,
          'url': module.url,
          'description': module.description,
          'contents': module.contents,
        },
      );
    } else if (module.isScorm) {
      context.push(
        '/content/scorm',
        extra: {
          'title': module.name,
          'url': module.url,
          'instance': module.instance,
          'courseId': courseId,
        },
      );
    } else if (module.isH5P) {
      context.push(
        '/content/h5p',
        extra: {
          'title': module.name,
          'url': module.url,
          'instance': module.instance,
        },
      );
    } else if (module.isQuiz) {
      // TODO: Phase 3 — Quiz
      _showComingSoon(context);
    } else if (module.isAssignment) {
      // TODO: Phase 3 — Assignment
      _showComingSoon(context);
    } else if (module.isForum) {
      // TODO: Phase 5 — Forum
      _showComingSoon(context);
    } else if (module.isBBB) {
      // TODO: Phase 5 — BigBlueButton
      _showComingSoon(context);
    } else {
      // Generic: try to open URL or show description
      if (module.url != null) {
        context.push(
          '/content/html',
          extra: {
            'title': module.name,
            'url': module.url,
            'description': module.description,
            'contents': module.contents,
          },
        );
      } else {
        _showComingSoon(context);
      }
    }
  }

  void _openResourceContent(BuildContext context) {
    if (module.contents.isEmpty) {
      _showComingSoon(context);
      return;
    }

    final content = module.contents.first;

    if (content.isVideo || module.isVideo) {
      context.push(
        '/content/video',
        extra: {'title': module.name, 'videoUrl': content.fileUrl ?? ''},
      );
    } else if (content.isPdf) {
      context.push(
        '/content/pdf',
        extra: {'title': module.name, 'pdfUrl': content.fileUrl ?? ''},
      );
    } else if (content.isImage) {
      context.push(
        '/content/html',
        extra: {
          'title': module.name,
          'contents': module.contents,
          'description': module.description,
        },
      );
    } else {
      // Generic file — open in HTML viewer / download
      context.push(
        '/content/html',
        extra: {
          'title': module.name,
          'url': content.fileUrl,
          'description': module.description,
          'contents': module.contents,
        },
      );
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('common.coming_soon')),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Shimmer ───
class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
