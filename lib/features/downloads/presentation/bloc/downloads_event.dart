part of 'downloads_bloc.dart';

abstract class DownloadsEvent extends Equatable {
  const DownloadsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDownloads extends DownloadsEvent {}

class StartDownload extends DownloadsEvent {
  final String id;
  final String title;
  final String url;
  final String mimeType;

  const StartDownload({
    required this.id,
    required this.title,
    required this.url,
    this.mimeType = '',
  });

  @override
  List<Object?> get props => [id, title, url, mimeType];
}

class PauseDownload extends DownloadsEvent {
  final String id;
  const PauseDownload({required this.id});
  @override
  List<Object?> get props => [id];
}

class ResumeDownload extends DownloadsEvent {
  final String id;
  const ResumeDownload({required this.id});
  @override
  List<Object?> get props => [id];
}

class CancelDownload extends DownloadsEvent {
  final String id;
  const CancelDownload({required this.id});
  @override
  List<Object?> get props => [id];
}

class DeleteDownload extends DownloadsEvent {
  final String id;
  const DeleteDownload({required this.id});
  @override
  List<Object?> get props => [id];
}

class DeleteAllDownloads extends DownloadsEvent {}

class RetryDownload extends DownloadsEvent {
  final String id;
  const RetryDownload({required this.id});
  @override
  List<Object?> get props => [id];
}

/// Internal event triggered by the download stream.
class _DownloadsUpdated extends DownloadsEvent {
  final Map<String, DownloadItem> items;
  const _DownloadsUpdated({required this.items});
  @override
  List<Object?> get props => [items];
}
