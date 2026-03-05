import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/forums/domain/entities/forum.dart';
import 'package:mdf_app/features/forums/domain/repositories/forum_repository.dart';
import 'package:mdf_app/features/forums/presentation/bloc/forum_bloc.dart';

class MockForumRepository extends Mock implements ForumRepository {}

void main() {
  late MockForumRepository mockRepository;
  late ForumBloc bloc;

  const tForum = Forum(
    id: 1,
    courseId: 10,
    name: 'General Forum',
    type: 'general',
  );

  const tDiscussion = ForumDiscussion(
    id: 1,
    forumId: 1,
    name: 'Test Discussion',
    numReplies: 3,
    pinned: false,
  );

  const tPost = ForumPost(
    id: 1,
    discussionId: 1,
    subject: 'Hello',
    message: '<p>Hello World</p>',
    userId: 5,
    userFullName: 'John Doe',
  );

  setUp(() {
    mockRepository = MockForumRepository();
    bloc = ForumBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is ForumInitial', () {
    expect(bloc.state, isA<ForumInitial>());
  });

  group('LoadForums', () {
    blocTest<ForumBloc, ForumState>(
      'emits [Loading, ForumsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getForumsByCourse(10),
        ).thenAnswer((_) async => const Right([tForum]));
        return bloc;
      },
      act: (b) => b.add(const LoadForums(courseId: 10)),
      expect: () => [
        isA<ForumLoading>(),
        isA<ForumsLoaded>().having(
          (s) => s.forums.length,
          'count',
          1,
        ),
      ],
    );

    blocTest<ForumBloc, ForumState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getForumsByCourse(10),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Network error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadForums(courseId: 10)),
      expect: () => [
        isA<ForumLoading>(),
        isA<ForumError>().having(
          (s) => s.message,
          'message',
          'Network error',
        ),
      ],
    );
  });

  group('LoadDiscussions', () {
    blocTest<ForumBloc, ForumState>(
      'emits [Loading, DiscussionsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getDiscussions(1),
        ).thenAnswer((_) async => const Right([tDiscussion]));
        return bloc;
      },
      act: (b) => b.add(const LoadDiscussions(forumId: 1)),
      expect: () => [
        isA<ForumLoading>(),
        isA<DiscussionsLoaded>().having(
          (s) => s.discussions.first.name,
          'name',
          'Test Discussion',
        ),
      ],
    );
  });

  group('LoadPosts', () {
    blocTest<ForumBloc, ForumState>(
      'emits [Loading, PostsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getDiscussionPosts(1),
        ).thenAnswer((_) async => const Right([tPost]));
        return bloc;
      },
      act: (b) => b.add(const LoadPosts(discussionId: 1)),
      expect: () => [
        isA<ForumLoading>(),
        isA<PostsLoaded>().having(
          (s) => s.posts.first.subject,
          'subject',
          'Hello',
        ),
      ],
    );
  });

  group('AddNewDiscussion', () {
    blocTest<ForumBloc, ForumState>(
      'emits [Loading, ActionSuccess, Loading, DiscussionsLoaded] on success',
      build: () {
        when(
          () => mockRepository.addDiscussion(1, 'Topic', 'Body'),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getDiscussions(1),
        ).thenAnswer((_) async => const Right([tDiscussion]));
        return bloc;
      },
      act: (b) => b.add(const AddNewDiscussion(
        forumId: 1,
        subject: 'Topic',
        message: 'Body',
      )),
      expect: () => [
        isA<ForumLoading>(),
        isA<ForumActionSuccess>(),
        isA<ForumLoading>(),
        isA<DiscussionsLoaded>(),
      ],
    );
  });

  group('AddReplyToPost', () {
    blocTest<ForumBloc, ForumState>(
      'emits [Loading, ActionSuccess, Loading, PostsLoaded] on success',
      build: () {
        when(
          () => mockRepository.addReply(1, 'Re: Hello', 'My reply'),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getDiscussionPosts(1),
        ).thenAnswer((_) async => const Right([tPost]));
        return bloc;
      },
      act: (b) => b.add(const AddReplyToPost(
        postId: 1,
        discussionId: 1,
        subject: 'Re: Hello',
        message: 'My reply',
      )),
      expect: () => [
        isA<ForumLoading>(),
        isA<ForumActionSuccess>(),
        isA<ForumLoading>(),
        isA<PostsLoaded>(),
      ],
    );
  });

  group('DeleteDiscussion', () {
    blocTest<ForumBloc, ForumState>(
      'emits [ActionSuccess, Loading, DiscussionsLoaded] on success',
      build: () {
        when(
          () => mockRepository.deletePost(1),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getDiscussions(1),
        ).thenAnswer((_) async => const Right([tDiscussion]));
        return bloc;
      },
      act: (b) => b.add(const DeleteDiscussion(postId: 1, forumId: 1)),
      expect: () => [
        isA<ForumActionSuccess>(),
        isA<ForumLoading>(),
        isA<DiscussionsLoaded>(),
      ],
    );
  });
}
