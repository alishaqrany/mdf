import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/quiz.dart';
import '../bloc/quiz_bloc.dart';

/// Quiz info page showing details and attempt history, with start/resume buttons.
class QuizInfoPage extends StatefulWidget {
  final Quiz quiz;

  const QuizInfoPage({super.key, required this.quiz});

  @override
  State<QuizInfoPage> createState() => _QuizInfoPageState();
}

class _QuizInfoPageState extends State<QuizInfoPage> {
  late final QuizBloc _bloc;
  late final int _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthAuthenticated ? authState.user.id : 0;
    _bloc = QuizBloc(repository: sl())
      ..add(LoadQuizAttempts(quizId: widget.quiz.id, userId: _userId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _reloadAttempts() {
    _bloc.add(LoadQuizAttempts(quizId: widget.quiz.id, userId: _userId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiz = widget.quiz;
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: Text(quiz.name)),
        body: BlocConsumer<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizAttemptStarted) {
              final timeLimitParam = quiz.timeLimit != null && quiz.timeLimit! > 0
                  ? '&timeLimit=${quiz.timeLimit}'
                  : '';
              context
                  .push(
                    '/quiz/attempt/${state.attempt.id}?quizId=${quiz.id}$timeLimitParam',
                  )
                  .then((_) => _reloadAttempts());
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz intro
                  if (quiz.intro != null && quiz.intro!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: HtmlWidget(quiz.intro!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quiz info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (quiz.grade != null)
                            _InfoRow(
                              icon: Icons.grade,
                              label: 'quiz.grade'.tr(),
                              value: quiz.grade!.toStringAsFixed(1),
                            ),
                          if (quiz.timeLimit != null && quiz.timeLimit! > 0)
                            _InfoRow(
                              icon: Icons.timer,
                              label: 'quiz.time_remaining'.tr(),
                              value: '${(quiz.timeLimit! / 60).round()} min',
                            ),
                          if (quiz.attempts != null && quiz.attempts! > 0)
                            _InfoRow(
                              icon: Icons.replay,
                              label: 'quiz.attempts'.tr(),
                              value: quiz.attempts.toString(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attempts list
                  if (state is QuizAttemptsLoaded) ...[
                    Text(
                      'quiz.attempts'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.attempts.isEmpty)
                      Text('quiz.no_attempts'.tr())
                    else
                      ...state.attempts.map((a) => _AttemptCard(attempt: a)),
                  ],
                  if (state is QuizLoading)
                    const Center(child: CircularProgressIndicator()),

                  const SizedBox(height: 24),

                  // Start/Resume button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // Check if there's an in-progress attempt
                        if (state is QuizAttemptsLoaded) {
                          final inProgress = state.attempts
                              .where((a) => a.isInProgress)
                              .toList();
                          if (inProgress.isNotEmpty) {
                            final timeLimitParam = quiz.timeLimit != null && quiz.timeLimit! > 0
                                ? '&timeLimit=${quiz.timeLimit}'
                                : '';
                            context
                                .push(
                                  '/quiz/attempt/${inProgress.first.id}?quizId=${quiz.id}$timeLimitParam',
                                )
                                .then((_) => _reloadAttempts());
                            return;
                          }
                        }
                        _bloc.add(StartQuizAttempt(quizId: quiz.id));
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        state is QuizAttemptsLoaded &&
                                state.attempts.any((a) => a.isInProgress)
                            ? 'quiz.resume_quiz'.tr()
                            : 'quiz.start_quiz'.tr(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttempt attempt;

  const _AttemptCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${attempt.attempt}')),
        title: Text(
          '${'quiz.attempts'.tr()} #${attempt.attempt}',
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(attempt.state),
        trailing: attempt.isFinished
            ? TextButton(
                onPressed: () => context.push('/quiz/review/${attempt.id}'),
                child: Text('quiz.review'.tr()),
              )
            : null,
      ),
    );
  }
}
