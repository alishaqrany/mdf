import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/colors.dart';

/// SCORM player using WebView with JavaScript bridge for progress tracking.
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ScormBridge',
        onMessageReceived: (message) {
          // Handle SCORM completion/progress messages from JS
          debugPrint('SCORM Bridge: ${message.message}');
        },
      )
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
        ),
      );

    if (widget.url != null && widget.url!.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.url!));
    }
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
      ),
      body: widget.url == null || widget.url!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.smart_display,
                    size: 64,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: 16),
                  const Text('SCORM content URL not available'),
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
