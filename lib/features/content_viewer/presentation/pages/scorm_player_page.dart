import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';

/// SCORM player using WebView with Moodle auto-login.
/// Loads the Moodle SCORM player page (which handles the JS SCORM runtime)
/// instead of directly loading the SCORM package, so progress tracking
/// works natively through Moodle.
class ScormPlayerPage extends StatefulWidget {
  final String title;
  final String? url;
  final int? instance;
  final int? courseId;

  const ScormPlayerPage({
    super.key,
    required this.title,
    this.url,
    this.instance,
    this.courseId,
  });

  @override
  State<ScormPlayerPage> createState() => _ScormPlayerPageState();
}

class _ScormPlayerPageState extends State<ScormPlayerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onWebResourceError: (error) {
            debugPrint(
              'SCORM WebView error: ${error.errorCode} ${error.description}',
            );
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
        ),
      );

    _loadScormWithAuth();
  }

  /// Build the SCORM player URL and load with Moodle auto-login.
  Future<void> _loadScormWithAuth() async {
    try {
      final apiClient = sl<MoodleApiClient>();
      final baseUrl = await apiClient.getBaseUrl();

      // The target URL is the Moodle SCORM player page.
      // Moodle will handle SCORM API, tracking, and packaging internally.
      String targetUrl;
      if (widget.url != null && widget.url!.isNotEmpty) {
        targetUrl = widget.url!;
      } else if (baseUrl != null && widget.instance != null) {
        // Fallback: build the Moodle SCORM view URL manually
        targetUrl = '$baseUrl/mod/scorm/view.php?id=${widget.instance}';
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'SCORM content URL not available';
          });
        }
        return;
      }

      // Try auto-login for seamless authentication
      await _loadUrlWithAutoLogin(apiClient, baseUrl, targetUrl);
    } catch (e) {
      debugPrint('SCORM load error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Load URL with Moodle auto-login for seamless authentication.
  Future<void> _loadUrlWithAutoLogin(
    MoodleApiClient apiClient,
    String? baseUrl,
    String targetUrl,
  ) async {
    try {
      if (baseUrl != null && targetUrl.startsWith(baseUrl)) {
        final privateToken = await apiClient.getPrivateToken();
        if (privateToken != null) {
          final keyResponse = await apiClient.call(
            MoodleApiEndpoints.getAutoLoginKey,
            params: {'privatetoken': privateToken},
          );

          if (keyResponse is Map &&
              keyResponse.containsKey('key') &&
              keyResponse.containsKey('autologinurl')) {
            final key = keyResponse['key'] as String;
            final autologinUrl = keyResponse['autologinurl'] as String;

            final siteInfo = await apiClient.call(
              MoodleApiEndpoints.getSiteInfo,
            );
            final userId = (siteInfo as Map<String, dynamic>)['userid'] ?? 0;

            final uri = Uri.parse(autologinUrl);
            final queryParams = Map<String, String>.from(uri.queryParameters);
            queryParams['userid'] = userId.toString();
            queryParams['key'] = key;
            queryParams['urltogo'] = targetUrl;

            final autoLoginFullUrl = uri
                .replace(queryParameters: queryParams)
                .toString();
            _controller.loadRequest(Uri.parse(autoLoginFullUrl));
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to direct load
    }

    // Fallback: load directly
    _controller.loadRequest(Uri.parse(targetUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
              _loadScormWithAuth();
            },
          ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.smart_display,
                    size: 64,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'SCORM content URL not available',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                      });
                      _loadScormWithAuth();
                    },
                  ),
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
