import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import 'cache_config.dart';

/// Status of a single download.
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Metadata for a downloaded file.
class DownloadItem {
  final String id;
  final String title;
  final String url;
  final String localPath;
  final String mimeType;
  int totalBytes;
  int downloadedBytes;
  DownloadStatus status;
  String? errorMessage;
  final int createdAt; // ms since epoch
  int? completedAt;

  DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    required this.localPath,
    this.mimeType = '',
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.errorMessage,
    int? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  double get progress =>
      totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => status == DownloadStatus.completed;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'localPath': localPath,
    'mimeType': mimeType,
    'totalBytes': totalBytes,
    'downloadedBytes': downloadedBytes,
    'status': status.index,
    'errorMessage': errorMessage,
    'createdAt': createdAt,
    'completedAt': completedAt,
  };

  factory DownloadItem.fromMap(Map<dynamic, dynamic> map) {
    return DownloadItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? '',
      localPath: map['localPath'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      totalBytes: map['totalBytes'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      status: DownloadStatus.values[map['status'] as int? ?? 0],
      errorMessage: map['errorMessage'] as String?,
      createdAt: map['createdAt'] as int? ?? 0,
      completedAt: map['completedAt'] as int?,
    );
  }
}

/// Manages file downloads with queue, progress tracking, and persistence.
class DownloadManager {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  final Map<String, CancelToken> _cancelTokens = {};
  final _progressController =
      StreamController<Map<String, DownloadItem>>.broadcast();

  /// Stream of all download items (fires on any change).
  Stream<Map<String, DownloadItem>> get progressStream =>
      _progressController.stream;

  late Box _metaBox;

  DownloadManager({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage,
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

  /// Initialize — opens the Hive metadata box.
  Future<void> init() async {
    _metaBox = Hive.box(CacheConfig.downloadsBox);
    // Recover any "downloading" items as "paused" after app restart
    for (final key in _metaBox.keys) {
      final raw = _metaBox.get(key);
      if (raw is Map) {
        final item = DownloadItem.fromMap(raw);
        if (item.status == DownloadStatus.downloading) {
          item.status = DownloadStatus.paused;
          await _metaBox.put(key, item.toMap());
        }
      }
    }
  }

  /// Get all download items.
  Map<String, DownloadItem> getAll() {
    final result = <String, DownloadItem>{};
    for (final key in _metaBox.keys) {
      final raw = _metaBox.get(key);
      if (raw is Map) {
        result[key as String] = DownloadItem.fromMap(raw);
      }
    }
    return result;
  }

  /// Get a single download item by ID.
  DownloadItem? getItem(String id) {
    final raw = _metaBox.get(id);
    if (raw is Map) return DownloadItem.fromMap(raw);
    return null;
  }

  /// Get the base downloads directory.
  Future<String> get _downloadDir async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/mdf_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  /// Enqueue a download.
  Future<DownloadItem> enqueue({
    required String id,
    required String title,
    required String url,
    String mimeType = '',
    String? fileName,
  }) async {
    // If already downloaded and complete, return existing
    final existing = getItem(id);
    if (existing != null && existing.isComplete) {
      if (await File(existing.localPath).exists()) {
        return existing;
      }
    }

    final dir = await _downloadDir;
    final ext = _extensionFromMime(mimeType, url);
    final safeName =
        fileName ?? '${id}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final localPath = '$dir/$safeName';

    final item = DownloadItem(
      id: id,
      title: title,
      url: url,
      localPath: localPath,
      mimeType: mimeType,
    );

    await _metaBox.put(id, item.toMap());
    _notifyListeners();

    // Start downloading immediately
    _startDownload(item);

    return item;
  }

  Future<void> _startDownload(DownloadItem item) async {
    item.status = DownloadStatus.downloading;
    await _metaBox.put(item.id, item.toMap());
    _notifyListeners();

    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    try {
      // Get auth token for Moodle files
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      final baseUrl = await _secureStorage.read(key: AppConstants.serverUrlKey);

      // Build authenticated URL if it's a Moodle file
      String downloadUrl = item.url;
      if (token != null &&
          baseUrl != null &&
          downloadUrl.contains('pluginfile.php')) {
        downloadUrl = downloadUrl.replaceFirst(
          '/pluginfile.php/',
          '/webservice/pluginfile.php/',
        );
        downloadUrl += (downloadUrl.contains('?') ? '&' : '?');
        downloadUrl += 'token=$token';
      }

      await _dio.download(
        downloadUrl,
        item.localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          item.downloadedBytes = received;
          if (total > 0) item.totalBytes = total;
          item.status = DownloadStatus.downloading;
          _metaBox.put(item.id, item.toMap());
          _notifyListeners();
        },
      );

      item.status = DownloadStatus.completed;
      item.completedAt = DateTime.now().millisecondsSinceEpoch;
      await _metaBox.put(item.id, item.toMap());
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        item.status = DownloadStatus.cancelled;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.message ?? 'Download failed';
      }
      await _metaBox.put(item.id, item.toMap());
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString();
      await _metaBox.put(item.id, item.toMap());
    } finally {
      _cancelTokens.remove(item.id);
      _notifyListeners();
    }
  }

  /// Pause a download (cancels the current request).
  Future<void> pause(String id) async {
    _cancelTokens[id]?.cancel('Paused');
    _cancelTokens.remove(id);
    final item = getItem(id);
    if (item != null) {
      item.status = DownloadStatus.paused;
      await _metaBox.put(id, item.toMap());
      _notifyListeners();
    }
  }

  /// Resume a paused/failed download.
  Future<void> resume(String id) async {
    final item = getItem(id);
    if (item == null) return;
    if (item.status == DownloadStatus.completed) return;
    _startDownload(item);
  }

  /// Cancel and delete a download.
  Future<void> cancel(String id) async {
    _cancelTokens[id]?.cancel('Cancelled');
    _cancelTokens.remove(id);
    final item = getItem(id);
    if (item != null) {
      // Delete local file
      try {
        final file = File(item.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await _metaBox.delete(id);
      _notifyListeners();
    }
  }

  /// Retry a failed download.
  Future<void> retry(String id) => resume(id);

  /// Delete a completed download (removes file and metadata).
  Future<void> deleteDownload(String id) async {
    final item = getItem(id);
    if (item != null) {
      try {
        final file = File(item.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await _metaBox.delete(id);
      _notifyListeners();
    }
  }

  /// Delete all downloads.
  Future<void> deleteAll() async {
    for (final key in _metaBox.keys.toList()) {
      await deleteDownload(key as String);
    }
  }

  /// Get total size of all downloads in bytes.
  Future<int> get totalDownloadSize async {
    int total = 0;
    for (final key in _metaBox.keys) {
      final item = getItem(key as String);
      if (item != null && item.isComplete) {
        try {
          final file = File(item.localPath);
          if (await file.exists()) {
            total += await file.length();
          }
        } catch (_) {}
      }
    }
    return total;
  }

  void _notifyListeners() {
    if (!_progressController.isClosed) {
      _progressController.add(getAll());
    }
  }

  String _extensionFromMime(String mimeType, String url) {
    if (mimeType.contains('pdf')) return '.pdf';
    if (mimeType.contains('mp4') || mimeType.contains('video')) return '.mp4';
    if (mimeType.contains('png')) return '.png';
    if (mimeType.contains('jpg') || mimeType.contains('jpeg')) return '.jpg';
    if (mimeType.contains('zip')) return '.zip';
    // Try to extract from URL
    final uri = Uri.tryParse(url);
    if (uri != null && uri.path.contains('.')) {
      final ext = uri.path.substring(uri.path.lastIndexOf('.'));
      if (ext.length <= 5) return ext;
    }
    return '';
  }

  /// Dispose resources.
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel('Disposed');
    }
    _cancelTokens.clear();
    _progressController.close();
  }
}
