import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/storage/download_manager.dart';
import 'package:mdf_app/features/downloads/presentation/bloc/downloads_bloc.dart';

class MockDownloadManager extends Mock implements DownloadManager {}

void main() {
  late MockDownloadManager mockManager;
  late DownloadsBloc bloc;

  final tItem = DownloadItem(
    id: 'file_1',
    title: 'Lecture Notes.pdf',
    url: 'https://example.com/notes.pdf',
    localPath: '/downloads/notes.pdf',
    mimeType: 'application/pdf',
    totalBytes: 1024000,
    downloadedBytes: 512000,
    status: DownloadStatus.downloading,
  );

  final tCompletedItem = DownloadItem(
    id: 'file_2',
    title: 'Assignment.docx',
    url: 'https://example.com/assignment.docx',
    localPath: '/downloads/assignment.docx',
    totalBytes: 50000,
    downloadedBytes: 50000,
    status: DownloadStatus.completed,
  );

  final tItems = {'file_1': tItem, 'file_2': tCompletedItem};

  setUp(() {
    mockManager = MockDownloadManager();
    when(
      () => mockManager.progressStream,
    ).thenAnswer((_) => const Stream.empty());
    bloc = DownloadsBloc(downloadManager: mockManager);
  });

  tearDown(() => bloc.close());

  test('initial state is DownloadsInitial', () {
    expect(bloc.state, isA<DownloadsInitial>());
  });

  group('LoadDownloads', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'emits [Loaded] with items',
      build: () {
        when(() => mockManager.getAll()).thenReturn(tItems);
        return bloc;
      },
      act: (b) => b.add(LoadDownloads()),
      expect: () => [
        isA<DownloadsLoaded>().having((s) => s.items.length, 'count', 2),
      ],
    );
  });

  group('StartDownload', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'calls enqueue on download manager',
      build: () {
        when(
          () => mockManager.enqueue(
            id: any(named: 'id'),
            title: any(named: 'title'),
            url: any(named: 'url'),
            mimeType: any(named: 'mimeType'),
          ),
        ).thenAnswer((_) async => tItem);
        return bloc;
      },
      act: (b) => b.add(
        const StartDownload(
          id: 'file_3',
          title: 'New File.pdf',
          url: 'https://example.com/new.pdf',
        ),
      ),
      verify: (_) {
        verify(
          () => mockManager.enqueue(
            id: 'file_3',
            title: 'New File.pdf',
            url: 'https://example.com/new.pdf',
            mimeType: '',
          ),
        ).called(1);
      },
    );
  });

  group('PauseDownload', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'calls pause on download manager',
      build: () {
        when(() => mockManager.pause('file_1')).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(const PauseDownload(id: 'file_1')),
      verify: (_) {
        verify(() => mockManager.pause('file_1')).called(1);
      },
    );
  });

  group('ResumeDownload', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'calls resume on download manager',
      build: () {
        when(() => mockManager.resume('file_1')).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(const ResumeDownload(id: 'file_1')),
      verify: (_) {
        verify(() => mockManager.resume('file_1')).called(1);
      },
    );
  });

  group('CancelDownload', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'calls cancel then reloads downloads',
      build: () {
        when(() => mockManager.cancel('file_1')).thenAnswer((_) async {});
        when(() => mockManager.getAll()).thenReturn(tItems);
        return bloc;
      },
      act: (b) => b.add(const CancelDownload(id: 'file_1')),
      expect: () => [isA<DownloadsLoaded>()],
      verify: (_) {
        verify(() => mockManager.cancel('file_1')).called(1);
      },
    );
  });

  group('DeleteDownload', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'calls deleteDownload then reloads downloads',
      build: () {
        when(
          () => mockManager.deleteDownload('file_2'),
        ).thenAnswer((_) async {});
        when(() => mockManager.getAll()).thenReturn({});
        return bloc;
      },
      act: (b) => b.add(const DeleteDownload(id: 'file_2')),
      expect: () => [isA<DownloadsLoaded>()],
      verify: (_) {
        verify(() => mockManager.deleteDownload('file_2')).called(1);
      },
    );
  });

  group('DeleteAllDownloads', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'calls deleteAll and emits empty Loaded',
      build: () {
        when(() => mockManager.deleteAll()).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(DeleteAllDownloads()),
      expect: () => [
        isA<DownloadsLoaded>().having((s) => s.items.isEmpty, 'empty', isTrue),
      ],
      verify: (_) {
        verify(() => mockManager.deleteAll()).called(1);
      },
    );
  });

  group('RetryDownload', () {
    blocTest<DownloadsBloc, DownloadsState>(
      'calls retry on download manager',
      build: () {
        when(() => mockManager.retry('file_1')).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(const RetryDownload(id: 'file_1')),
      verify: (_) {
        verify(() => mockManager.retry('file_1')).called(1);
      },
    );
  });

  group('DownloadItem', () {
    test('status is downloading', () {
      expect(tItem.status, DownloadStatus.downloading);
    });

    test('completed item has matching bytes', () {
      expect(tCompletedItem.downloadedBytes, tCompletedItem.totalBytes);
    });

    test('progress computation', () {
      expect(tItem.progress, closeTo(0.5, 0.01));
    });

    test('isComplete flag', () {
      expect(tItem.isComplete, isFalse);
      expect(tCompletedItem.isComplete, isTrue);
    });
  });

  group('DownloadsLoaded getters', () {
    test('completedItems filters correctly', () {
      final state = DownloadsLoaded(items: tItems);
      expect(
        state.completedItems.every((i) => i.status == DownloadStatus.completed),
        isTrue,
      );
    });

    test('activeItems filters correctly', () {
      final state = DownloadsLoaded(items: tItems);
      expect(state.activeItems, isNotEmpty);
    });

    test('hasActiveDownloads is true', () {
      final state = DownloadsLoaded(items: tItems);
      expect(state.hasActiveDownloads, isTrue);
    });

    test('totalSize sums completed items', () {
      final state = DownloadsLoaded(items: tItems);
      expect(state.totalSize, 50000);
    });
  });
}
