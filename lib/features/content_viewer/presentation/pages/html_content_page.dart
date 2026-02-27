import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../course_content/domain/entities/course_content.dart';

/// Displays HTML content, page resources, or URLs.
/// Uses flutter_widget_from_html for inline HTML and WebView for full URLs.
class HtmlContentPage extends StatefulWidget {
  final String title;
  final String? url;
  final String? description;
  final List<ModuleContent>? contents;

  const HtmlContentPage({
    super.key,
    required this.title,
    this.url,
    this.description,
    this.contents,
  });

  @override
  State<HtmlContentPage> createState() => _HtmlContentPageState();
}

class _HtmlContentPageState extends State<HtmlContentPage> {
  bool _useWebView = false;
  late final WebViewController _webViewController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If we have a URL and no inline description, use WebView
    if (widget.url != null &&
        (widget.description == null || widget.description!.isEmpty)) {
      _useWebView = true;
      _initWebView();
    }
    // If we have file contents with a URL, also use WebView
    if (!_useWebView &&
        widget.contents != null &&
        widget.contents!.isNotEmpty) {
      final firstContent = widget.contents!.first;
      if (firstContent.fileUrl != null &&
          firstContent.type == 'file' &&
          (widget.description == null || widget.description!.isEmpty)) {
        _useWebView = true;
        _initWebView();
      }
    }
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    final targetUrl = widget.url ?? widget.contents?.first.fileUrl ?? '';
    if (targetUrl.isNotEmpty) {
      _webViewController.loadRequest(Uri.parse(targetUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                final uri = Uri.parse(widget.url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: _useWebView
          ? Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HTML description content
                  if (widget.description != null &&
                      widget.description!.isNotEmpty)
                    HtmlWidget(
                      widget.description!,
                      textStyle: theme.textTheme.bodyLarge,
                      onTapUrl: (url) async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                        return true;
                      },
                    ),

                  // File attachments
                  if (widget.contents != null &&
                      widget.contents!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      tr('content.attachments'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.contents!.map(
                      (content) => _FileAttachment(content: content),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _FileAttachment extends StatelessWidget {
  final ModuleContent content;
  const _FileAttachment({required this.content});

  IconData _getIcon() {
    if (content.isPdf) return Icons.picture_as_pdf;
    if (content.isVideo) return Icons.play_circle;
    if (content.isImage) return Icons.image;
    if (content.isAudio) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getIcon(), color: AppColors.primary),
        ),
        title: Text(
          content.fileName ?? tr('content.file'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: content.fileSize != null
            ? Text(_formatSize(content.fileSize!))
            : null,
        trailing: const Icon(Icons.download_rounded),
        onTap: () async {
          if (content.fileUrl == null) return;
          final uri = Uri.parse(content.fileUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  String _formatSize(String sizeStr) {
    final bytes = int.tryParse(sizeStr) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
