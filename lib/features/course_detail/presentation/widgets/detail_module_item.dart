import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../course_content/domain/entities/course_content.dart';
import '../../../content_viewer/presentation/pages/html_content_page.dart';
import 'inline_label_content.dart';

/// Single course-module row inside a section card: icon, name, completion,
/// and all the navigation logic for different module types.
class DetailModuleItem extends StatelessWidget {
  final CourseModule module;
  final int courseId;
  final bool editMode;

  const DetailModuleItem({
    super.key,
    required this.module,
    required this.courseId,
    this.editMode = false,
  });

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
      return InlineLabelContent(module: module);
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
            if (editMode)
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  final loc = GoRouterState.of(context).matchedLocation;
                  final prefix = loc.startsWith('/admin')
                      ? '/admin'
                      : loc.startsWith('/teacher')
                      ? '/teacher'
                      : '/student';
                  context.push(
                    '$prefix/edit-activity/${module.id}?module=${Uri.encodeComponent(module.modName)}&name=${Uri.encodeComponent(module.name)}&courseId=$courseId',
                  );
                },
              )
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<String> _getBaseUrl() async {
    return await sl<MoodleApiClient>().getBaseUrl() ?? '';
  }

  void _onModuleTap(BuildContext context) {
    if (module.isSubSection) return;
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
      if (module.description != null && module.description!.isNotEmpty) {
        context.push(
          '/content/html',
          extra: {'title': module.name, 'description': module.description},
        );
      }
    } else {
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
        _getBaseUrl().then((baseUrl) {
          if (context.mounted) {
            final fallbackUrl =
                '$baseUrl/mod/${module.modName}/view.php?id=${module.id}';
            context.push(
              '/content/html',
              extra: {'title': module.name, 'url': fallbackUrl},
            );
          }
        });
      } else {
        _showComingSoon(context);
      }
    }
  }

  /// Authenticate pluginfile URLs by appending the user's REST token.
  String _authPluginFileUrls(String html, String token) {
    return html.replaceAllMapped(
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

  /// Resolve @@PLUGINFILE@@ placeholders using file metadata + token.
  Future<String> _resolvePluginFiles(
    String content,
    String token,
    List<dynamic> allFiles,
  ) async {
    if (!content.contains('@@PLUGINFILE@@')) return content;

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
          content = content.replaceAll('@@PLUGINFILE@@/$filename', authedUrl);
          final enc = Uri.encodeComponent(filename);
          if (enc != filename) {
            content = content.replaceAll('@@PLUGINFILE@@/$enc', authedUrl);
          }
        }
      }
    }

    // Remaining unresolved @@PLUGINFILE@@ — build from context id
    if (content.contains('@@PLUGINFILE@@')) {
      final baseUrl = await sl<MoodleApiClient>().getBaseUrl();
      if (baseUrl != null) {
        String? ctxId;
        for (final f in allFiles) {
          if (f is Map<String, dynamic>) {
            final furl = f['fileurl'] as String?;
            if (furl != null) {
              final m = RegExp(r'pluginfile\.php/(\d+)/').firstMatch(furl);
              if (m != null) {
                ctxId = m.group(1);
                break;
              }
            }
          }
        }
        ctxId ??= module.id.toString();
        content = content.replaceAllMapped(RegExp(r'@@PLUGINFILE@@/([^"<\s]+)'), (
          match,
        ) {
          final path = match.group(1)!;
          return '$baseUrl/webservice/pluginfile.php/$ctxId/mod_page/content/0/$path?token=$token';
        });
      }
    }

    return content;
  }

  /// Navigate to inline HTML page content viewer.
  void _showPageContent(BuildContext context, String content) {
    if (!context.mounted) return;
    context.push(
      '/content/html',
      extra: {
        'title': module.name,
        'description': HtmlContentPage.preprocessVideoLinks(content),
      },
    );
  }

  Future<void> _fetchAndShowPage(BuildContext context) async {
    final apiClient = sl<MoodleApiClient>();
    final token = await sl<FlutterSecureStorage>().read(
      key: AppConstants.tokenKey,
    );

    // ── Attempt 1: Custom MDF endpoint (returns pre-resolved content) ──
    try {
      final customResponse = await apiClient.call(
        MoodleApiEndpoints.mdfGetPageContent,
        params: {'cmid': module.id},
      );

      if (customResponse is Map<String, dynamic>) {
        var content = (customResponse['content'] as String? ?? '').trim();
        final intro = (customResponse['intro'] as String? ?? '').trim();

        if (content.isEmpty) {
          content = intro;
        } else if (intro.isNotEmpty) {
          content = '$intro\n$content';
        }

        if (token != null && content.isNotEmpty) {
          content = _authPluginFileUrls(content, token);
        }

        if (content.isNotEmpty) {
          _showPageContent(context, content);
          return;
        }
      }
    } catch (e) {
      debugPrint('[Page] Custom endpoint failed: $e');
    }

    // ── Attempt 2: Standard Moodle mod_page_get_pages_by_courses ──
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getPages,
        params: {'courseids[0]': courseId},
      );

      if (response is Map<String, dynamic> && response.containsKey('pages')) {
        final pages = response['pages'] as List<dynamic>;
        Map<String, dynamic>? pageData;
        for (final p in pages) {
          if (p is Map<String, dynamic> && p['coursemodule'] == module.id) {
            pageData = p;
            break;
          }
        }

        if (pageData != null && token != null) {
          var content = pageData['content'] as String? ?? '';
          final allFiles = [
            ...(pageData['contentfiles'] as List<dynamic>? ?? []),
            ...(pageData['introfiles'] as List<dynamic>? ?? []),
          ];

          content = await _resolvePluginFiles(content, token, allFiles);
          content = _authPluginFileUrls(content, token);

          if (content.isNotEmpty) {
            _showPageContent(context, content);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[Page] Standard endpoint failed: $e');
    }

    if (!context.mounted) return;

    // ── Attempt 3: Show module description/intro (already in memory) ──
    final desc = module.description ?? '';
    if (desc.isNotEmpty) {
      var html = desc;
      if (token != null) html = _authPluginFileUrls(html, token);
      _showPageContent(context, html);
      return;
    }

    // ── No content available — show error message ──
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('content.page_load_error')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
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
      if (module.modName.isNotEmpty) {
        _getBaseUrl().then((baseUrl) {
          if (context.mounted) {
            final fallbackUrl =
                '$baseUrl/mod/${module.modName}/view.php?id=${module.id}';
            context.push(
              '/content/html',
              extra: {'title': module.name, 'url': fallbackUrl},
            );
          }
        });
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
