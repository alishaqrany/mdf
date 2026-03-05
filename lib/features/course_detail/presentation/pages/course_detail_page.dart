import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../app/theme/colors.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../course_content/presentation/bloc/course_content_bloc.dart';
import '../../data/datasources/course_detail_remote_datasource.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/course_info_card.dart';
import '../widgets/course_action_chip.dart';
import '../widgets/detail_section_card.dart';
import '../widgets/detail_shimmer.dart';

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
  bool _editMode = false;
  bool _isEnrolled = true; // assume enrolled until checked
  bool _enrolLoading = false;

  /// Whether the current user can manage content in this course.
  bool get _canManage {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return false;
    final user = authState.user;
    return user.isAdmin || user.isTeacherInCourse(widget.courseId);
  }

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id;
    try {
      final api = sl<MoodleApiClient>();
      final result = await api.call(
        MoodleApiEndpoints.getUsersCourses,
        params: {'userid': userId},
      );
      if (result is List) {
        final ids = result
            .cast<Map<String, dynamic>>()
            .map((c) => c['id'] as int)
            .toSet();
        if (mounted) setState(() => _isEnrolled = ids.contains(widget.courseId));
      }
    } catch (_) {}
  }

  Future<void> _toggleEnrolment() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id;
    final ds = sl<CourseDetailRemoteDataSource>();

    setState(() => _enrolLoading = true);
    try {
      if (_isEnrolled) {
        if (_canManage) {
          await ds.manualUnenrol(widget.courseId, userId);
        }
      } else {
        // Try self-enrol first, fallback to manual enrol for admins
        try {
          await ds.selfEnrol(widget.courseId);
        } catch (_) {
          if (_canManage) {
            await ds.manualEnrol(widget.courseId, userId);
          } else {
            rethrow;
          }
        }
      }
      if (mounted) {
        setState(() {
          _isEnrolled = !_isEnrolled;
          _enrolLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(_isEnrolled ? 'enrolment.enrolled_success' : 'enrolment.unenrolled_success'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enrolLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('enrolment.error'))),
        );
      }
    }
  }

  Future<void> _loadCourseDetails() async {
    try {
      final ds = sl<CourseDetailRemoteDataSource>();
      final course = await ds.getCourseDetail(widget.courseId);
      if (mounted) {
        setState(() {
          _course = course;
          _courseLoading = false;
        });
      }
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
                          errorWidget: (_, _, _) => Container(
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
                  if (_canManage)
                    IconButton(
                      icon: Icon(
                        _editMode ? Icons.edit_off : Icons.edit_note,
                        color: _editMode ? Colors.amber : null,
                      ),
                      tooltip: tr('course_mgmt.edit_mode'),
                      onPressed: () => setState(() => _editMode = !_editMode),
                    ),
                  if (_canManage && _editMode)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        final loc = GoRouterState.of(context).matchedLocation;
                        final prefix = loc.startsWith('/admin')
                            ? '/admin'
                            : loc.startsWith('/teacher')
                            ? '/teacher'
                            : '/student';
                        switch (action) {
                          case 'add_section':
                            context.push(
                              '$prefix/course/${widget.courseId}/manage-sections',
                            );
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'add_section',
                          child: ListTile(
                            leading: const Icon(Icons.playlist_add),
                            title: Text(tr('course_mgmt.add_section')),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () async {
                      final baseUrl = await sl<MoodleApiClient>().getBaseUrl() ?? '';
                      final url =
                          '$baseUrl/course/view.php?id=${widget.courseId}';
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${tr("common.link_copied")}: $url'),
                          ),
                        );
                      }
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
                        child: CourseInfoCard(course: _course!),
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
                      CourseActionChip(
                        icon: Icons.quiz_rounded,
                        label: tr('quizzes.title'),
                        onTap: () =>
                            context.push('/quiz/list/${widget.courseId}'),
                      ),
                      const SizedBox(width: 8),
                      CourseActionChip(
                        icon: Icons.assignment_rounded,
                        label: tr('assignments.title'),
                        onTap: () =>
                            context.push('/assignment/list/${widget.courseId}'),
                      ),
                      const SizedBox(width: 8),
                      CourseActionChip(
                        icon: Icons.grade_rounded,
                        label: tr('grades.title'),
                        onTap: () => context.push('/grades/${widget.courseId}'),
                      ),
                      const SizedBox(width: 8),
                      CourseActionChip(
                        icon: Icons.forum_rounded,
                        label: tr('forums.title'),
                        onTap: () =>
                            context.push('/forum/list/${widget.courseId}'),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Enrol / Unenrol Button ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _enrolLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          icon: Icon(
                            _isEnrolled ? Icons.logout_rounded : Icons.login_rounded,
                          ),
                          label: Text(
                            tr(_isEnrolled ? 'enrolment.unenrol' : 'enrolment.enrol'),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isEnrolled
                                ? AppColors.error
                                : AppColors.primary,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: _toggleEnrolment,
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
                    return const SliverToBoxAdapter(child: DetailShimmer());
                  }

                  if (state is CourseContentError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
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
                    // Filter out sections that are subsections
                    final subSectionNames = <String>{};
                    for (final s in state.sections) {
                      for (final m in s.modules) {
                        if (m.isSubSection) subSectionNames.add(m.name);
                      }
                    }
                    final topLevelSections = state.sections
                        .where((s) => !subSectionNames.contains(s.name))
                        .toList();

                    if (topLevelSections.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
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
                        final section = topLevelSections[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 60),
                          child: DetailSectionCard(
                            section: section,
                            courseId: widget.courseId,
                            initiallyExpanded: index == 0,
                            editMode: _editMode,
                          ),
                        );
                      }, childCount: topLevelSections.length),
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

