import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../course_content/domain/entities/course_content.dart';
import '../../../course_content/presentation/bloc/course_content_bloc.dart';
import '../../../content_viewer/presentation/pages/html_content_page.dart';
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
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<CourseContentBloc>().add(
              LoadCourseContent(courseId: widget.courseId),
            );
            _loadCourseDetails();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
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
                      if (widget.imageUrl != null &&
                          widget.imageUrl!.isNotEmpty)
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
                      final url =
                          'https://ecoursesdesgin.com/moodle/course/view.php?id=${widget.courseId}';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${tr("common.link_copied")}: $url'),
                        ),
                      );
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

              // ─── Course Quick Actions ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      _ActionChip(
                        icon: Icons.quiz_rounded,
                        label: tr('quizzes.title'),
                        onTap: () =>
                            context.push('/quiz/list/${widget.courseId}'),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.assignment_rounded,
                        label: tr('assignments.title'),
                        onTap: () =>
                            context.push('/assignment/list/${widget.courseId}'),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.grade_rounded,
                        label: tr('grades.title'),
                        onTap: () => context.push('/grades/${widget.courseId}'),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.forum_rounded,
                        label: tr('forums.title'),
                        onTap: () =>
                            context.push('/forum/list/${widget.courseId}'),
                      ),
                    ],
                  ),
                ),
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

            // Instructor(s)
            if (course.contacts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    tr('courses.instructor'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...course.contacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: contact.profileImageUrl != null
                            ? NetworkImage(contact.profileImageUrl!)
                            : null,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: contact.profileImageUrl == null
                            ? Text(
                                contact.fullName.isNotEmpty
                                    ? contact.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contact.fullName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: AppColors.primary),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onTap,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
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
                if (module.isSubSection) {
                  return _DetailSubSectionExpander(
                    module: module,
                    courseId: widget.courseId,
                  );
                }
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

    // Labels (Text and Media Area) — render rich HTML inline
    if (module.isLabel) {
      return _InlineLabelContent(module: module);
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
    if (module.isSubSection) return; // Handled by _DetailSubSectionExpander
    // Determine content type and navigate
    if (module.isResource || module.isFolder) {
      _openResourceContent(context);
    } else if (module.isPage) {
      _fetchAndShowPage(context);
    } else if (module.isBook || module.isLesson) {
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
      context.push(
        '/quiz/list/$courseId?title=${Uri.encodeComponent(module.name)}',
      );
    } else if (module.isAssignment) {
      context.push('/assignment/list/$courseId');
    } else if (module.isForum) {
      context.push('/forum/list/$courseId');
    } else if (module.isBBB) {
      context.push(
        '/content/html',
        extra: {
          'title': module.name,
          'url': module.url,
          'description': module.description,
        },
      );
    } else if (module.isLabel) {
      // Labels are inline text — show description if available
      if (module.description != null && module.description!.isNotEmpty) {
        context.push(
          '/content/html',
          extra: {'title': module.name, 'description': module.description},
        );
      }
    } else {
      // Generic: try to open URL, description or contents
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
      } else if (module.description != null && module.description!.isNotEmpty) {
        context.push(
          '/content/html',
          extra: {
            'title': module.name,
            'description': module.description,
            'contents': module.contents,
          },
        );
      } else if (module.contents.isNotEmpty) {
        _openResourceContent(context);
      } else if (module.modName.isNotEmpty) {
        // Construct a fallback Moodle URL from modName + id
        final fallbackUrl =
            'https://ecoursesdesgin.com/moodle/mod/${module.modName}/view.php?id=${module.id}';
        context.push(
          '/content/html',
          extra: {'title': module.name, 'url': fallbackUrl},
        );
      } else {
        _showComingSoon(context);
      }
    }
  }

  /// Fetch page content via API and display with resolved media URLs.
  /// Images, videos and iframes load correctly because the WebView renders
  /// the HTML with fully-authenticated pluginfile URLs.
  Future<void> _fetchAndShowPage(BuildContext context) async {
    try {
      final apiClient = sl<MoodleApiClient>();
      final token = await sl<FlutterSecureStorage>().read(
        key: AppConstants.tokenKey,
      );

      final response = await apiClient.call(
        MoodleApiEndpoints.getPages,
        params: {'courseids[0]': courseId},
      );

      if (response is Map<String, dynamic> && response.containsKey('pages')) {
        final pages = response['pages'] as List<dynamic>;

        // Find the page matching this module's cmid
        Map<String, dynamic>? pageData;
        for (final p in pages) {
          if (p is Map<String, dynamic> && p['coursemodule'] == module.id) {
            pageData = p;
            break;
          }
        }

        if (pageData != null) {
          var content = pageData['content'] as String? ?? '';
          final contentFiles = pageData['contentfiles'] as List<dynamic>? ?? [];
          final introFiles = pageData['introfiles'] as List<dynamic>? ?? [];
          final allFiles = [...contentFiles, ...introFiles];

          // Resolve @@PLUGINFILE@@ with token-authenticated URLs
          if (token != null && content.contains('@@PLUGINFILE@@')) {
            for (final file in allFiles) {
              if (file is Map<String, dynamic>) {
                final filename = file['filename'] as String?;
                final fileurl = file['fileurl'] as String?;
                if (filename != null && fileurl != null) {
                  var cleanUrl = fileurl.replaceAll(
                    RegExp(r'[?&]forcedownload=[^&]*'),
                    '',
                  );
                  final sep = cleanUrl.contains('?') ? '&' : '?';
                  final authedUrl = '$cleanUrl${sep}token=$token';

                  content = content.replaceAll(
                    '@@PLUGINFILE@@/$filename',
                    authedUrl,
                  );
                  final encodedName = Uri.encodeComponent(filename);
                  if (encodedName != filename) {
                    content = content.replaceAll(
                      '@@PLUGINFILE@@/$encodedName',
                      authedUrl,
                    );
                  }
                }
              }
            }

            // Fallback: extract contextid from first file URL and use it
            final baseUrl = await apiClient.getBaseUrl();
            if (baseUrl != null) {
              String? contextId;
              for (final file in allFiles) {
                if (file is Map<String, dynamic>) {
                  final furl = file['fileurl'] as String?;
                  if (furl != null) {
                    final m = RegExp(
                      r'pluginfile\.php/(\d+)/',
                    ).firstMatch(furl);
                    if (m != null) {
                      contextId = m.group(1);
                      break;
                    }
                  }
                }
              }
              contextId ??= module.id.toString();

              content = content.replaceAllMapped(
                RegExp(r'@@PLUGINFILE@@/([^"<\s]+)'),
                (match) {
                  final path = match.group(1)!;
                  return '$baseUrl/webservice/pluginfile.php/'
                      '$contextId/mod_page/content/0/$path?token=$token';
                },
              );
            }
          }

          // Also authenticate any absolute pluginfile URLs that Moodle's
          // editor may have embedded directly (without @@PLUGINFILE@@)
          if (token != null) {
            content = content.replaceAllMapped(
              RegExp(r'(https?://[^"\s<>]*pluginfile\.php/[^"\s<>]+)'),
              (match) {
                var url = match.group(1)!;
                if (url.contains('token=')) return url;
                url = url.replaceAll(RegExp(r'[?&]forcedownload=[^&]*'), '');
                final sep = url.contains('?') ? '&' : '?';
                return '$url${sep}token=$token';
              },
            );
          }

          if (content.isNotEmpty && context.mounted) {
            // Convert video links to <video> tags for inline playback
            content = HtmlContentPage.preprocessVideoLinks(content);
            context.push(
              '/content/html',
              extra: {'title': module.name, 'description': content},
            );
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to URL-based fallback
    }

    // Fallback: open URL directly
    if (context.mounted) {
      final pageUrl =
          module.url ??
          'https://ecoursesdesgin.com/moodle/mod/page/view.php?id=${module.id}';
      context.push(
        '/content/html',
        extra: {'title': module.name, 'url': pageUrl},
      );
    }
  }

  void _openResourceContent(BuildContext context) {
    if (module.contents.isEmpty) {
      // Try to open via URL if available
      if (module.url != null) {
        context.push(
          '/content/html',
          extra: {'title': module.name, 'url': module.url},
        );
        return;
      }
      // Construct fallback URL from modName + id
      if (module.modName.isNotEmpty) {
        final fallbackUrl =
            'https://ecoursesdesgin.com/moodle/mod/${module.modName}/view.php?id=${module.id}';
        context.push(
          '/content/html',
          extra: {'title': module.name, 'url': fallbackUrl},
        );
        return;
      }
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

// ─── SubSection Expander ───
class _DetailSubSectionExpander extends StatefulWidget {
  final CourseModule module;
  final int courseId;

  const _DetailSubSectionExpander({
    required this.module,
    required this.courseId,
  });

  @override
  State<_DetailSubSectionExpander> createState() =>
      _DetailSubSectionExpanderState();
}

class _DetailSubSectionExpanderState extends State<_DetailSubSectionExpander> {
  bool _expanded = false;

  CourseSection? _findLinkedSection() {
    final state = context.read<CourseContentBloc>().state;
    if (state is! CourseContentLoaded) return null;

    // Find the parent section (the one containing this subsection module)
    CourseSection? parentSection;
    for (final s in state.sections) {
      if (s.modules.any((m) => m.id == widget.module.id)) {
        parentSection = s;
        break;
      }
    }

    // Match by name among non-parent sections
    for (final s in state.sections) {
      if (identical(s, parentSection)) continue;
      if (s.name == widget.module.name) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkedSection = _findLinkedSection();
    final modules = linkedSection?.modules ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_special_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.module.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (modules.isNotEmpty)
                        Text(
                          '${modules.length} ${tr("content.activities")}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(left: 24),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.info.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: modules
                  .map(
                    (m) =>
                        _DetailModuleItem(module: m, courseId: widget.courseId),
                  )
                  .toList(),
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
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

// ─── Inline Label (Text and Media Area) ───
/// Renders label/text-media-area description as rich inline HTML.
/// Resolves @@PLUGINFILE@@ URLs with auth tokens so images & videos display.
class _InlineLabelContent extends StatefulWidget {
  final CourseModule module;
  const _InlineLabelContent({required this.module});

  @override
  State<_InlineLabelContent> createState() => _InlineLabelContentState();
}

class _InlineLabelContentState extends State<_InlineLabelContent> {
  String? _resolvedHtml;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveDescription();
  }

  Future<void> _resolveDescription() async {
    var html = widget.module.description ?? '';
    if (html.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final token = await sl<FlutterSecureStorage>().read(
        key: AppConstants.tokenKey,
      );
      final apiClient = sl<MoodleApiClient>();
      final baseUrl = await apiClient.getBaseUrl();

      if (token != null) {
        // Resolve @@PLUGINFILE@@ URLs for label (intro area)
        if (html.contains('@@PLUGINFILE@@') && baseUrl != null) {
          String? contextId;
          for (final c in widget.module.contents) {
            if (c.fileUrl != null) {
              final m = RegExp(
                r'pluginfile\.php/(\d+)/',
              ).firstMatch(c.fileUrl!);
              if (m != null) {
                contextId = m.group(1);
                break;
              }
            }
          }
          contextId ??= widget.module.id.toString();

          html = html.replaceAllMapped(RegExp(r'@@PLUGINFILE@@/([^"<\s]+)'), (
            match,
          ) {
            final path = match.group(1)!;
            return '$baseUrl/webservice/pluginfile.php/'
                '$contextId/mod_label/intro/0/$path?token=$token';
          });
        }

        // Authenticate absolute pluginfile URLs
        html = html.replaceAllMapped(
          RegExp(r'(https?://[^"\s<>]*pluginfile\.php/[^"\s<>]+)'),
          (match) {
            var url = match.group(1)!;
            if (url.contains('token=')) return url;
            url = url.replaceAll(RegExp(r'[?&]forcedownload=[^&]*'), '');
            final sep = url.contains('?') ? '&' : '?';
            return '$url${sep}token=$token';
          },
        );
      }

      html = HtmlContentPage.preprocessVideoLinks(html);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _resolvedHtml = html;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = widget.module.description;

    if (description == null || description.isEmpty) {
      if (widget.module.name.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.module.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: HtmlWidget(
          _resolvedHtml ?? description,
          textStyle: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          customStylesBuilder: (element) {
            final tag = element.localName;
            if (tag == 'img') {
              return {
                'max-width': '100%',
                'height': 'auto',
                'border-radius': '8px',
                'margin': '8px 0',
              };
            }
            if (tag == 'video' || tag == 'iframe') {
              return {'max-width': '100%', 'border-radius': '8px'};
            }
            if (tag == 'table') {
              return {'border-collapse': 'collapse', 'width': '100%'};
            }
            if (tag == 'td' || tag == 'th') {
              return {'border': '1px solid #ddd', 'padding': '8px'};
            }
            return null;
          },
          customWidgetBuilder: (element) {
            if (element.localName == 'div') {
              final videoSrc = element.attributes['data-video-src'];
              if (videoSrc != null && videoSrc.isNotEmpty) {
                return _buildVideoPlaceholder(videoSrc);
              }
            }
            if (element.localName == 'video') {
              String? src = element.attributes['src'];
              if (src == null || src.isEmpty) {
                for (final child in element.children) {
                  if (child.localName == 'source') {
                    src = child.attributes['src'];
                    if (src != null && src.isNotEmpty) break;
                  }
                }
              }
              if (src != null && src.isNotEmpty) {
                return _buildVideoPlaceholder(src);
              }
            }
            if (element.localName == 'a') {
              final href = element.attributes['href'];
              if (href != null &&
                  HtmlContentPage.videoExtensions.hasMatch(href)) {
                return _buildVideoPlaceholder(href);
              }
            }
            return null;
          },
          onTapUrl: (url) async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return true;
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(String videoUrl) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(videoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text(
                'اضغط لتشغيل الفيديو',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
