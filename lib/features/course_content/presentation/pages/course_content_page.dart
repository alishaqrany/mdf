import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/course_content.dart';
import '../bloc/course_content_bloc.dart';
import '../../../content_viewer/presentation/pages/html_content_page.dart';

class CourseContentPage extends StatelessWidget {
  final int courseId;
  final String courseTitle;

  const CourseContentPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CourseContentBloc>()..add(LoadCourseContent(courseId: courseId)),
      child: _CourseContentView(courseTitle: courseTitle, courseId: courseId),
    );
  }
}

class _CourseContentView extends StatelessWidget {
  final String courseTitle;
  final int courseId;

  const _CourseContentView({required this.courseTitle, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(courseTitle), centerTitle: true),
      body: BlocBuilder<CourseContentBloc, CourseContentState>(
        builder: (context, state) {
          if (state is CourseContentLoading) {
            return const _ContentShimmer();
          }

          if (state is CourseContentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(tr('common.retry')),
                    onPressed: () {
                      // Reload
                    },
                  ),
                ],
              ),
            );
          }

          if (state is CourseContentLoaded) {
            if (state.sections.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('content.no_content'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.sections.length,
              itemBuilder: (context, index) => FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: index * 60),
                child: _SectionWidget(
                  section: state.sections[index],
                  courseId: courseId,
                  isExpanded: index == 0,
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

// ─── Section Widget ───
class _SectionWidget extends StatefulWidget {
  final CourseSection section;
  final int courseId;
  final bool isExpanded;

  const _SectionWidget({
    required this.section,
    required this.courseId,
    this.isExpanded = false,
  });

  @override
  State<_SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<_SectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = widget.section.modules
        .where((m) => m.completionState == 1)
        .length;
    final totalCount = widget.section.modules.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Section Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isExpanded ? AppColors.primarySurface : null,
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
                        if (totalCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount / $totalCount ${tr("content.activities")}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
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

          // Modules
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: widget.section.modules.map((module) {
                if (module.isSubSection) {
                  return _SubSectionExpander(
                    module: module,
                    courseId: widget.courseId,
                  );
                }
                return _ModuleItem(module: module, courseId: widget.courseId);
              }).toList(),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ─── Module Item ───
class _ModuleItem extends StatelessWidget {
  final CourseModule module;
  final int courseId;

  const _ModuleItem({required this.module, required this.courseId});

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
    if (module.modName == 'chat') return Icons.chat_rounded;
    if (module.modName == 'wiki') return Icons.public_rounded;
    if (module.modName == 'glossary') return Icons.abc_rounded;
    if (module.modName == 'choice') return Icons.poll_rounded;
    if (module.modName == 'feedback') return Icons.feedback_rounded;
    if (module.modName == 'survey') return Icons.assessment_rounded;
    if (module.modName == 'workshop') return Icons.handshake_rounded;
    if (module.modName == 'data') return Icons.storage_rounded;
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

    // Labels are small dividers, render differently
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
      onTap: () => _navigateToContent(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon
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
            // Title & Type
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
            // Completion Indicator
            if (module.completionState != null)
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isCompleted ? AppColors.success : AppColors.divider,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToContent(BuildContext context) {
    if (module.isSubSection) return; // Handled by _SubSectionExpander
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
        },
      );
    } else if (module.isScorm) {
      context.push(
        '/content/scorm',
        extra: {
          'title': module.name,
          'url': module.url,
          'instance': module.instance,
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
      if (module.description != null && module.description!.isNotEmpty) {
        context.push(
          '/content/html',
          extra: {'title': module.name, 'description': module.description},
        );
      }
    } else if (module.url != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('common.coming_soon')),
          duration: const Duration(seconds: 2),
        ),
      );
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
              // Try to extract contextid from file URLs
              // e.g. .../pluginfile.php/1234/mod_page/content/...
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
      }
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
    } else {
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
}

// ─── SubSection Expander ───
class _SubSectionExpander extends StatefulWidget {
  final CourseModule module;
  final int courseId;

  const _SubSectionExpander({required this.module, required this.courseId});

  @override
  State<_SubSectionExpander> createState() => _SubSectionExpanderState();
}

class _SubSectionExpanderState extends State<_SubSectionExpander> {
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
                  .map((m) => _ModuleItem(module: m, courseId: widget.courseId))
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
class _ContentShimmer extends StatelessWidget {
  const _ContentShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
