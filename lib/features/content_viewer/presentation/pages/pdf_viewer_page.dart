import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/constants/app_constants.dart';

/// PDF viewer using WebView with Google Docs viewer as fallback.
class PdfViewerPage extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerPage({super.key, required this.title, required this.pdfUrl});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// Prepare the PDF URL: append token for Moodle pluginfile URLs
  /// and strip forcedownload so the server serves inline.
  Future<String> _preparePdfUrl() async {
    var url = widget.pdfUrl;

    // Append authentication token for Moodle pluginfile URLs
    if (url.contains('pluginfile.php')) {
      final token = await sl<FlutterSecureStorage>().read(
        key: AppConstants.tokenKey,
      );
      if (token != null) {
        // Strip forcedownload and add token
        url = url.replaceAll(RegExp(r'[?&]forcedownload=[^&]*'), '');
        final separator = url.contains('?') ? '&' : '?';
        url = '$url${separator}token=$token&forcedownload=0';
      }
    }
    return url;
  }

  void _initWebView() {
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
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      );

    // Try loading the PDF directly first. If the URL is a Moodle pluginfile URL,
    // append token parameter. Use Google Docs viewer as a wrapper.
    _preparePdfUrl().then((authedUrl) {
      final encodedUrl = Uri.encodeComponent(authedUrl);
      final viewerUrl =
          'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
      _controller.loadRequest(Uri.parse(viewerUrl));
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
            onPressed: () {
              // Open directly in device browser
              _controller.loadRequest(Uri.parse(widget.pdfUrl));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _initWebView();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError)
            WebViewWidget(controller: _controller)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Failed to load PDF'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                      });
                      _initWebView();
                    },
                  ),
                ],
              ),
            ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
