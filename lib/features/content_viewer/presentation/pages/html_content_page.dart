import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../course_content/domain/entities/course_content.dart';

/// Displays HTML content, page resources, or URLs.
/// Uses HtmlWidget for inline HTML (images, video via Chewie, iframes via
/// embedded WebView) and a full WebView only for URL-based navigation.
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

  /// Video file extensions that should be rendered as inline players.
  static final videoExtensions = RegExp(
    r'\.(mp4|m4v|webm|ogv|mov|avi|mkv|3gp)(\?|$)',
    caseSensitive: false,
  );

  /// Convert all video elements (<a> links, <video> tags) into safe
  /// placeholder <div>s so that flutter_widget_from_html's built-in
  /// Chewie/ExoPlayer extension never sees them (avoids error 153).
  static String preprocessVideoLinks(String html) {
    // 1. <a href="...video.mp4">...</a>  →  placeholder div
    html = html.replaceAllMapped(
      RegExp(
        r'<a\s[^>]*href="([^"]+\.(mp4|m4v|webm|ogv|mov|3gp)(\?[^"]*)?)".^>]*>[\s\S]*?</a>',
        caseSensitive: false,
      ),
      (match) {
        final url = match.group(1)!;
        return '<div data-video-src="$url"></div>';
      },
    );

    // 2. <video ...><source src="...">...</video>  →  placeholder div
    html = html.replaceAllMapped(
      RegExp(
        r'<video[^>]*>[\s\S]*?<source[^>]*\ssrc="([^"]+)"[^>]*/?>([\s\S]*?)</video>',
        caseSensitive: false,
      ),
      (match) {
        final url = match.group(1)!;
        return '<div data-video-src="$url"></div>';
      },
    );

    // 3. <video src="...">...</video>  →  placeholder div
    html = html.replaceAllMapped(
      RegExp(
        r'<video[^>]*\ssrc="([^"]+)"[^>]*>[\s\S]*?</video>',
        caseSensitive: false,
      ),
      (match) {
        final url = match.group(1)!;
        return '<div data-video-src="$url"></div>';
      },
    );

    // 4. Self-closing <video src="..."/> or <video src="...">
    html = html.replaceAllMapped(
      RegExp(r'<video[^>]*\ssrc="([^"]+)"[^>]*/?>', caseSensitive: false),
      (match) {
        final url = match.group(1)!;
        return '<div data-video-src="$url"></div>';
      },
    );

    return html;
  }

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

    // 1) URL provided without inline description → WebView to load that URL.
    if (widget.url != null &&
        (widget.description == null || widget.description!.isEmpty)) {
      _useWebView = true;
      _initWebView();
      return;
    }

    // 2) File content without description → WebView.
    if (widget.contents != null && widget.contents!.isNotEmpty) {
      final firstContent = widget.contents!.first;
      if (firstContent.fileUrl != null &&
          firstContent.type == 'file' &&
          (widget.description == null || widget.description!.isEmpty)) {
        _useWebView = true;
        _initWebView();
        return;
      }
    }

    // 3) Description (with or without media) → HtmlWidget renders natively.
    //    flutter_widget_from_html handles <img>, <video> (Chewie),
    //    <iframe> (WebView), <audio> (just_audio) out of the box.
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
      _loadUrlWithAuth(targetUrl);
    }
  }

  /// Load URL with Moodle auto-login if it's a Moodle URL.
  Future<void> _loadUrlWithAuth(String targetUrl) async {
    try {
      final apiClient = sl<MoodleApiClient>();
      final baseUrl = await apiClient.getBaseUrl();

      // Check if this URL is on our Moodle server
      if (baseUrl != null && targetUrl.startsWith(baseUrl)) {
        // If it's a pluginfile URL, we can just append the token
        if (targetUrl.contains('pluginfile.php')) {
          final token = await sl<FlutterSecureStorage>().read(
            key: AppConstants.tokenKey,
          );
          if (token != null) {
            // Strip forcedownload so the server sends inline content
            var cleanUrl = targetUrl.replaceAll(
              RegExp(r'[?&]forcedownload=[^&]*'),
              '',
            );
            final separator = cleanUrl.contains('?') ? '&' : '?';
            final urlWithToken =
                '$cleanUrl${separator}token=$token&forcedownload=0';
            _webViewController.loadRequest(Uri.parse(urlWithToken));
            return;
          }
        }

        final privateToken = await apiClient.getPrivateToken();
        if (privateToken == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى لتفعيل ميزة فتح الروابط تلقائياً',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          throw Exception('No private token available for auto-login');
        }

        // Get auto-login key from Moodle
        final keyResponse = await apiClient.call(
          MoodleApiEndpoints.getAutoLoginKey,
          params: {'privatetoken': privateToken},
        );

        if (keyResponse is Map &&
            keyResponse.containsKey('key') &&
            keyResponse.containsKey('autologinurl')) {
          final key = keyResponse['key'] as String;
          final autologinUrl = keyResponse['autologinurl'] as String;

          // Get userId
          final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
          final userId = (siteInfo as Map<String, dynamic>)['userid'] ?? 0;

          // Build auto-login URL — pass the FULL targetUrl to urltogo
          // Moodle's PARAM_URL requires a full URL (http/https), otherwise
          // it rejects it and falls back to the dashboard/login.
          final uri = Uri.parse(autologinUrl);
          final queryParams = Map<String, String>.from(uri.queryParameters);
          queryParams['userid'] = userId.toString();
          queryParams['key'] = key;
          queryParams['urltogo'] = targetUrl;

          final autoLoginFullUrl = uri
              .replace(queryParameters: queryParams)
              .toString();

          _webViewController.loadRequest(Uri.parse(autoLoginFullUrl));
          return;
        }
      }
    } catch (_) {
      // If auto-login fails, fall back to direct URL load
    }

    // Fallback: load URL directly
    _webViewController.loadRequest(Uri.parse(targetUrl));
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
                  // HTML description content – HtmlWidget renders
                  // images, videos (Chewie), iframes (WebView),
                  // and audio (just_audio) natively.
                  if (widget.description != null &&
                      widget.description!.isNotEmpty)
                    Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: HtmlWidget(
                        HtmlContentPage.preprocessVideoLinks(
                          widget.description!,
                        ),
                        textStyle: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                        ),
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
                            return {
                              'max-width': '100%',
                              'border-radius': '8px',
                            };
                          }
                          if (tag == 'table') {
                            return {
                              'border-collapse': 'collapse',
                              'width': '100%',
                            };
                          }
                          if (tag == 'td' || tag == 'th') {
                            return {
                              'border': '1px solid #ddd',
                              'padding': '8px',
                            };
                          }
                          return null;
                        },
                        customWidgetBuilder: (element) {
                          // 1. Intercept placeholder <div data-video-src>
                          //    created by preprocessVideoLinks.
                          if (element.localName == 'div') {
                            final videoSrc =
                                element.attributes['data-video-src'];
                            if (videoSrc != null && videoSrc.isNotEmpty) {
                              return _InlineVideoPlayer(url: videoSrc);
                            }
                          }

                          // 2. Safety fallback: intercept any <video> tags
                          //    that slipped past preprocessing.
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
                              return _InlineVideoPlayer(url: src);
                            }
                          }

                          // 3. Catch remaining <a> links to video files.
                          if (element.localName == 'a') {
                            final href = element.attributes['href'];
                            if (href != null &&
                                HtmlContentPage.videoExtensions.hasMatch(
                                  href,
                                )) {
                              return _InlineVideoPlayer(url: href);
                            }
                          }
                          return null;
                        },
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

/// Inline video player rendered in a small embedded WebView.
/// Uses the browser's native HTML5 <video> player which handles
/// Moodle pluginfile URLs, redirects, and all codecs reliably —
/// unlike Flutter's video_player plugin which fails with
/// Moodle's authenticated/redirect URLs.
class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  const _InlineVideoPlayer({required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint(
              'Video WebView error: ${error.errorCode} ${error.description}',
            );
            if (mounted)
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
          },
        ),
      )
      ..setBackgroundColor(Colors.black);

    // Android-specific: allow inline media playback without user gesture
    if (_controller.platform is AndroidWebViewController) {
      final android = _controller.platform as AndroidWebViewController;
      await android.setMediaPlaybackRequiresUserGesture(false);
    }

    // Set baseUrl to the Moodle server origin so resource loads
    // are treated as same-origin (fixes ERR_CACHE_MISS / error 153).
    final uri = Uri.tryParse(widget.url);
    final baseUrl = (uri != null && uri.hasScheme && uri.hasAuthority)
        ? '${uri.scheme}://${uri.authority}'
        : null;

    await _controller.loadHtmlString(
      _buildVideoHtml(widget.url),
      baseUrl: baseUrl,
    );

    if (mounted) setState(() {});
  }

  String _buildVideoHtml(String videoUrl) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
  video {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }
</style>
</head>
<body>
  <video controls playsinline preload="auto">
    <source src="$videoUrl" />
    Your browser does not support the video tag.
  </video>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    // If the WebView fails, show a tap-to-open fallback
    if (_hasError) {
      return GestureDetector(
        onTap: () async {
          final uri = Uri.parse(widget.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 220,
            color: Colors.black87,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اضغط لتشغيل الفيديو',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 220,
        color: Colors.black,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
