import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/colors.dart';

/// H5P interactive content player using WebView.
class H5pPlayerPage extends StatefulWidget {
  final String title;
  final String? url;
  final int? instance;

  const H5pPlayerPage({
    super.key,
    required this.title,
    this.url,
    this.instance,
  });

  @override
  State<H5pPlayerPage> createState() => _H5pPlayerPageState();
}

class _H5pPlayerPageState extends State<H5pPlayerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'H5PBridge',
        onMessageReceived: (message) {
          // Handle H5P xAPI result messages
          debugPrint('H5P Bridge: ${message.message}');
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
                    Icons.extension,
                    size: 64,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: 16),
                  const Text('H5P content URL not available'),
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
