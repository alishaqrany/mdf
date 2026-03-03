import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/quiz.dart';
import '../bloc/quiz_bloc.dart';

class QuizListPage extends StatelessWidget {
  final int courseId;
  final String courseTitle;

  const QuizListPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          QuizBloc(repository: sl())..add(LoadQuizzes(courseId: courseId)),
      child: Scaffold(
        appBar: AppBar(title: Text('quiz.title'.tr())),
        body: BlocConsumer<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizAttemptStarted) {
              context.push(
                '/quiz/attempt/${state.attempt.id}',
                extra: {'quizId': state.attempt.quizId},
              );
            }
          },
          builder: (context, state) {
            if (state is QuizLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is QuizError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<QuizBloc>().add(
                        LoadQuizzes(courseId: courseId),
                      ),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            }
            if (state is QuizzesLoaded) {
              if (state.quizzes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'quiz.no_attempts'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.quizzes.length,
                itemBuilder: (context, index) =>
                    _QuizCard(quiz: state.quizzes[index]),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push(
            '/quiz/info',
            extra: {'quiz': quiz, 'courseId': quiz.courseId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.quiz_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quiz.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (quiz.grade != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${'quiz.grade'.tr()}: ${quiz.grade!.toStringAsFixed(1)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
              if (quiz.timeLimit != null && quiz.timeLimit! > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${(quiz.timeLimit! / 60).round()} ${'common.minutes'.tr()}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (quiz.attempts != null && quiz.attempts! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${'quiz.attempts'.tr()}: ${quiz.attempts}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
