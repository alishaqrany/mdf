import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/download_manager.dart';

part 'downloads_event.dart';
part 'downloads_state.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  final DownloadManager downloadManager;
  StreamSubscription<Map<String, DownloadItem>>? _subscription;

  DownloadsBloc({required this.downloadManager}) : super(DownloadsInitial()) {
    on<LoadDownloads>(_onLoad);
    on<StartDownload>(_onStart);
    on<PauseDownload>(_onPause);
    on<ResumeDownload>(_onResume);
    on<CancelDownload>(_onCancel);
    on<DeleteDownload>(_onDelete);
    on<DeleteAllDownloads>(_onDeleteAll);
    on<RetryDownload>(_onRetry);
    on<_DownloadsUpdated>(_onUpdated);

    // Listen to download progress
    _subscription = downloadManager.progressStream.listen((items) {
      add(_DownloadsUpdated(items: items));
    });
  }

  void _onLoad(LoadDownloads event, Emitter<DownloadsState> emit) {
    final items = downloadManager.getAll();
    emit(DownloadsLoaded(items: items));
  }

  Future<void> _onStart(
    StartDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadManager.enqueue(
      id: event.id,
      title: event.title,
      url: event.url,
      mimeType: event.mimeType,
    );
  }

  Future<void> _onPause(
    PauseDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadManager.pause(event.id);
  }

  Future<void> _onResume(
    ResumeDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadManager.resume(event.id);
  }

  Future<void> _onCancel(
    CancelDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadManager.cancel(event.id);
    add(LoadDownloads());
  }

  Future<void> _onDelete(
    DeleteDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadManager.deleteDownload(event.id);
    add(LoadDownloads());
  }

  Future<void> _onDeleteAll(
    DeleteAllDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadManager.deleteAll();
    emit(const DownloadsLoaded(items: {}));
  }

  Future<void> _onRetry(
    RetryDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadManager.retry(event.id);
  }

  void _onUpdated(_DownloadsUpdated event, Emitter<DownloadsState> emit) {
    emit(DownloadsLoaded(items: event.items));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
