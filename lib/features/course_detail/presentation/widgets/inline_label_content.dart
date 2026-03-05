import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../course_content/domain/entities/course_content.dart';
import '../../../content_viewer/presentation/pages/html_content_page.dart';

/// Renders label/text-media-area description as rich inline HTML.
/// Resolves @@PLUGINFILE@@ URLs with auth tokens so images & videos display.
class InlineLabelContent extends StatefulWidget {
  final CourseModule module;
  const InlineLabelContent({super.key, required this.module});

  @override
  State<InlineLabelContent> createState() => _InlineLabelContentState();
}

class _InlineLabelContentState extends State<InlineLabelContent> {
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
