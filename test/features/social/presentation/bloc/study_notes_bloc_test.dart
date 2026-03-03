import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/social/domain/entities/social_entities.dart';
import 'package:mdf_app/features/social/domain/repositories/social_repository.dart';
import 'package:mdf_app/features/social/presentation/bloc/study_notes_bloc.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepository;
  late StudyNotesBloc bloc;

  setUpAll(() {
    registerFallbackValue(NoteVisibility.course);
    registerFallbackValue(<String>[]);
  });

  final tNote = StudyNote(
    id: 1,
    title: 'Chapter 1 Summary',
    content: 'Key points from chapter 1...',
    authorId: 1,
    authorName: 'Ahmad Ali',
    courseId: 101,
    courseName: 'Mathematics',
    likes: 5,
    isLiked: false,
    isBookmarked: true,
    commentCount: 2,
    visibility: NoteVisibility.course,
    tags: const ['math', 'chapter1'],
    createdAt: DateTime(2024, 3, 10),
    updatedAt: DateTime(2024, 3, 10),
  );

  final tComment = NoteComment(
    id: 1,
    noteId: 1,
    authorId: 2,
    authorName: 'Sara',
    content: 'Great notes!',
    createdAt: DateTime(2024, 3, 11),
  );

  setUp(() {
    mockRepository = MockSocialRepository();
    bloc = StudyNotesBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is StudyNotesInitial', () {
    expect(bloc.state, isA<StudyNotesInitial>());
  });

  group('LoadCourseNotes', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockRepository.getCourseNotes(101),
        ).thenAnswer((_) async => Right([tNote]));
        return bloc;
      },
      act: (b) => b.add(const LoadCourseNotes(101)),
      expect: () => [
        isA<StudyNotesLoading>(),
        isA<StudyNotesLoaded>().having((s) => s.notes.length, 'count', 1),
      ],
    );

    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getCourseNotes(101)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Notes error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadCourseNotes(101)),
      expect: () => [isA<StudyNotesLoading>(), isA<StudyNotesError>()],
    );
  });

  group('LoadGroupNotes', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockRepository.getGroupNotes(1),
        ).thenAnswer((_) async => Right([tNote]));
        return bloc;
      },
      act: (b) => b.add(const LoadGroupNotes(1)),
      expect: () => [isA<StudyNotesLoading>(), isA<StudyNotesLoaded>()],
    );
  });

  group('CreateNote', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [Loading, NoteCreated] on success',
      build: () {
        when(
          () => mockRepository.createNote(
            title: any(named: 'title'),
            content: any(named: 'content'),
            courseId: any(named: 'courseId'),
            groupId: any(named: 'groupId'),
            visibility: any(named: 'visibility'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async => Right(tNote));
        return bloc;
      },
      act: (b) => b.add(
        const CreateNote(
          title: 'Chapter 1 Summary',
          content: 'Key points from chapter 1...',
          courseId: 101,
        ),
      ),
      expect: () => [isA<StudyNotesLoading>(), isA<NoteCreated>()],
    );
  });

  group('UpdateNote', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [Loading, NoteUpdated] on success',
      build: () {
        when(
          () => mockRepository.updateNote(
            noteId: any(named: 'noteId'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async => Right(tNote));
        return bloc;
      },
      act: (b) => b.add(
        const UpdateNote(
          noteId: 1,
          title: 'Updated title',
          content: 'Updated content',
        ),
      ),
      expect: () => [isA<StudyNotesLoading>(), isA<NoteUpdated>()],
    );
  });

  group('DeleteNote', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [ActionSuccess] on success (no Loading)',
      build: () {
        when(
          () => mockRepository.deleteNote(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const DeleteNote(1)),
      expect: () => [isA<StudyNotesActionSuccess>()],
    );
  });

  group('ToggleLikeNote', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'calls toggleLikeNote on repository',
      build: () {
        when(
          () => mockRepository.toggleLikeNote(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const ToggleLikeNote(1)),
      verify: (_) {
        verify(() => mockRepository.toggleLikeNote(1)).called(1);
      },
    );
  });

  group('ToggleBookmarkNote', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'calls toggleBookmarkNote on repository',
      build: () {
        when(
          () => mockRepository.toggleBookmarkNote(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const ToggleBookmarkNote(1)),
      verify: (_) {
        verify(() => mockRepository.toggleBookmarkNote(1)).called(1);
      },
    );
  });

  group('LoadNoteComments', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [Loading, CommentsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getNoteComments(1),
        ).thenAnswer((_) async => Right([tComment]));
        return bloc;
      },
      act: (b) => b.add(const LoadNoteComments(1)),
      expect: () => [
        isA<StudyNotesLoading>(),
        isA<NoteCommentsLoaded>().having((s) => s.comments.length, 'count', 1),
      ],
    );
  });

  group('AddNoteComment', () {
    blocTest<StudyNotesBloc, StudyNotesState>(
      'emits [ActionSuccess] on comment add (no Loading)',
      build: () {
        when(
          () => mockRepository.addNoteComment(1, 'Great notes!'),
        ).thenAnswer((_) async => Right(tComment));
        return bloc;
      },
      act: (b) =>
          b.add(const AddNoteComment(noteId: 1, content: 'Great notes!')),
      expect: () => [isA<StudyNotesActionSuccess>()],
    );
  });
}
