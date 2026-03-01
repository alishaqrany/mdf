part of 'downloads_bloc.dart';

abstract class DownloadsState extends Equatable {
  const DownloadsState();

  @override
  List<Object?> get props => [];
}

class DownloadsInitial extends DownloadsState {}

class DownloadsLoading extends DownloadsState {}

class DownloadsLoaded extends DownloadsState {
  final Map<String, DownloadItem> items;

  const DownloadsLoaded({required this.items});

  List<DownloadItem> get completedItems => items.values
      .where((item) => item.status == DownloadStatus.completed)
      .toList();

  List<DownloadItem> get activeItems => items.values
      .where(
        (item) =>
            item.status == DownloadStatus.downloading ||
            item.status == DownloadStatus.queued,
      )
      .toList();

  List<DownloadItem> get pausedItems => items.values
      .where((item) => item.status == DownloadStatus.paused)
      .toList();

  List<DownloadItem> get failedItems => items.values
      .where((item) => item.status == DownloadStatus.failed)
      .toList();

  int get totalSize => items.values
      .where((item) => item.status == DownloadStatus.completed)
      .fold(0, (sum, item) => sum + item.totalBytes);

  bool get hasActiveDownloads => activeItems.isNotEmpty;

  @override
  List<Object?> get props => [items];
}

class DownloadsError extends DownloadsState {
  final String message;
  const DownloadsError({required this.message});
  @override
  List<Object?> get props => [message];
}
