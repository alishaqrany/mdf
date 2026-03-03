import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Native PDF viewer with page navigation, night mode, and zoom support.
class PdfViewerPage extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerPage({super.key, required this.title, required this.pdfUrl});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? _localFilePath;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _downloadProgress = 0;

  int _currentPage = 0;
  int _totalPages = 0;
  bool _nightMode = false;
  PDFViewController? _pdfController;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  @override
  void dispose() {
    // Clean up the temp file
    if (_localFilePath != null) {
      File(_localFilePath!).delete().catchError((_) => File(_localFilePath!));
    }
    super.dispose();
  }

  /// Prepare the PDF URL with authentication token if needed.
  Future<String> _prepareAuthUrl() async {
    var url = widget.pdfUrl;
    if (url.contains('pluginfile.php')) {
      final token = await sl<FlutterSecureStorage>().read(
        key: AppConstants.tokenKey,
      );
      if (token != null) {
        url = url.replaceAll(RegExp(r'[?&]forcedownload=[^&]*'), '');
        final separator = url.contains('?') ? '&' : '?';
        url = '$url${separator}token=$token&forcedownload=0';
      }
    }
    return url;
  }

  /// Download the PDF to a local temp file and display natively.
  Future<void> _downloadPdf() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _downloadProgress = 0;
    });

    try {
      final authedUrl = await _prepareAuthUrl();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(
        authedUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      // Verify the file is actually a PDF
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 4 &&
            bytes[0] == 0x25 && // %
            bytes[1] == 0x50 && // P
            bytes[2] == 0x44 && // D
            bytes[3] == 0x46) {
          // F — valid PDF header
          if (mounted) {
            setState(() {
              _localFilePath = filePath;
              _isLoading = false;
            });
          }
        } else {
          throw Exception('الملف المحمّل ليس PDF صالحاً');
        }
      } else {
        throw Exception('فشل حفظ الملف');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _goToPage(int page) {
    if (_pdfController != null && page >= 0 && page < _totalPages) {
      _pdfController!.setPage(page);
    }
  }

  void _showGoToPageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('انتقل إلى صفحة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                Navigator.pop(ctx);
                _goToPage(page - 1);
              }
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
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
          if (_localFilePath != null) ...[
            // Night mode toggle
            IconButton(
              icon: Icon(_nightMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: _nightMode ? 'الوضع العادي' : 'الوضع الليلي',
              onPressed: () {
                setState(() => _nightMode = !_nightMode);
              },
            ),
            // Go to page
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'انتقل إلى صفحة',
              onPressed: _showGoToPageDialog,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: _buildBody(theme),
      // Bottom page navigation bar
      bottomNavigationBar: _localFilePath != null && _totalPages > 0
          ? _buildPageNavigator(theme)
          : null,
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    strokeWidth: 3,
                  ),
                  if (_downloadProgress > 0)
                    Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل الملف...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('فشل تحميل الملف', style: theme.textTheme.titleMedium),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                onPressed: _downloadPdf,
              ),
            ],
          ),
        ),
      );
    }

    if (_localFilePath != null) {
      return PDFView(
        filePath: _localFilePath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        fitPolicy: FitPolicy.WIDTH,
        nightMode: _nightMode,
        onRender: (pages) {
          if (mounted && pages != null) {
            setState(() => _totalPages = pages);
          }
        },
        onViewCreated: (controller) {
          _pdfController = controller;
        },
        onPageChanged: (page, total) {
          if (mounted && page != null) {
            setState(() => _currentPage = page);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = error.toString();
            });
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPageNavigator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous page
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 28),
              onPressed: _currentPage < _totalPages - 1
                  ? () => _goToPage(_currentPage + 1)
                  : null,
            ),
            // Page indicator
            Expanded(
              child: GestureDetector(
                onTap: _showGoToPageDialog,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'صفحة ${_currentPage + 1} من $_totalPages',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _totalPages > 1
                            ? (_currentPage + 1) / _totalPages
                            : 1.0,
                        minHeight: 3,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Next page
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              onPressed: _currentPage > 0
                  ? () => _goToPage(_currentPage - 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
