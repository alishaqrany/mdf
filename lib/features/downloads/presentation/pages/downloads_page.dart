import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/download_manager.dart';
import '../bloc/downloads_bloc.dart';

/// Page to manage all downloads — shows active, completed, and
/// failed downloads with progress bars and action buttons.
class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadsBloc(downloadManager: sl())..add(LoadDownloads()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('downloads.title'.tr()),
          actions: [
            BlocBuilder<DownloadsBloc, DownloadsState>(
              builder: (context, state) {
                if (state is DownloadsLoaded && state.items.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'downloads.clear_all'.tr(),
                    onPressed: () => _confirmClearAll(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<DownloadsBloc, DownloadsState>(
          builder: (context, state) {
            if (state is DownloadsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DownloadsError) {
              return Center(child: Text(state.message));
            }
            if (state is DownloadsLoaded) {
              if (state.items.isEmpty) {
                return _EmptyState();
              }
              return _DownloadsList(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('downloads.clear_all'.tr()),
        content: Text('common.delete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<DownloadsBloc>().add(DeleteAllDownloads());
              Navigator.pop(ctx);
            },
            child: Text(
              'common.delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'downloads.no_downloads'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _DownloadsList extends StatelessWidget {
  final DownloadsLoaded state;

  const _DownloadsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Storage info header
        if (state.totalSize > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Icon(Icons.storage, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${'downloads.storage_used'.tr()}: ${_formatBytes(state.totalSize)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Active downloads
        if (state.activeItems.isNotEmpty) ...[
          _SectionHeader(
            title: 'downloads.downloading'.tr(),
            count: state.activeItems.length,
          ),
          ...state.activeItems.map((item) => _DownloadTile(item: item)),
        ],

        // Paused downloads
        if (state.pausedItems.isNotEmpty) ...[
          _SectionHeader(
            title: 'downloads.pending'.tr(),
            count: state.pausedItems.length,
          ),
          ...state.pausedItems.map((item) => _DownloadTile(item: item)),
        ],

        // Failed downloads
        if (state.failedItems.isNotEmpty) ...[
          _SectionHeader(
            title: 'downloads.failed'.tr(),
            count: state.failedItems.length,
          ),
          ...state.failedItems.map((item) => _DownloadTile(item: item)),
        ],

        // Completed downloads
        if (state.completedItems.isNotEmpty) ...[
          _SectionHeader(
            title: 'downloads.downloaded'.tr(),
            count: state.completedItems.length,
          ),
          ...state.completedItems.map((item) => _DownloadTile(item: item)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadItem item;

  const _DownloadTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _statusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActions(context),
              ],
            ),
            // Progress bar for active downloads
            if (item.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress > 0 ? item.progress : null,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatBytes(item.downloadedBytes),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (item.totalBytes > 0)
                    Text(
                      '${(item.progress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
            // Error message
            if (item.status == DownloadStatus.failed &&
                item.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                item.errorMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red[400],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (item.status) {
      case DownloadStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        color = Colors.blue;
      case DownloadStatus.paused:
        icon = Icons.pause_circle;
        color = Colors.orange;
      case DownloadStatus.failed:
        icon = Icons.error;
        color = Colors.red;
      case DownloadStatus.queued:
        icon = Icons.schedule;
        color = Colors.grey;
      case DownloadStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
    }

    return Icon(icon, size: 36, color: color);
  }

  String _statusText() {
    switch (item.status) {
      case DownloadStatus.completed:
        return _formatBytes(item.totalBytes);
      case DownloadStatus.downloading:
        return '${_formatBytes(item.downloadedBytes)} / ${item.totalBytes > 0 ? _formatBytes(item.totalBytes) : "..."}';
      case DownloadStatus.paused:
        return '${(item.progress * 100).toStringAsFixed(0)}%';
      case DownloadStatus.failed:
        return item.errorMessage ?? 'Failed';
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor() {
    switch (item.status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.queued:
      case DownloadStatus.cancelled:
        return Colors.grey;
    }
  }

  Widget _buildActions(BuildContext context) {
    final bloc = context.read<DownloadsBloc>();

    switch (item.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () => bloc.add(PauseDownload(id: item.id)),
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => bloc.add(ResumeDownload(id: item.id)),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => bloc.add(CancelDownload(id: item.id)),
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => bloc.add(RetryDownload(id: item.id)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => bloc.add(DeleteDownload(id: item.id)),
            ),
          ],
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => bloc.add(DeleteDownload(id: item.id)),
        );
      case DownloadStatus.queued:
        return IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => bloc.add(CancelDownload(id: item.id)),
        );
      case DownloadStatus.cancelled:
        return IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => bloc.add(DeleteDownload(id: item.id)),
        );
    }
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  var i = 0;
  double size = bytes.toDouble();
  while (size >= 1024 && i < suffixes.length - 1) {
    size /= 1024;
    i++;
  }
  return '${size.toStringAsFixed(i > 0 ? 1 : 0)} ${suffixes[i]}';
}
