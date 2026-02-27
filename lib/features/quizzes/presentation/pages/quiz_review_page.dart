import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../../app/di/injection.dart';
import '../bloc/quiz_bloc.dart';

/// Displays the review of a finished quiz attempt.
class QuizReviewPage extends StatelessWidget {
  final int attemptId;

  const QuizReviewPage({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          QuizBloc(repository: sl())
            ..add(LoadAttemptReview(attemptId: attemptId)),
      child: Scaffold(
        appBar: AppBar(title: Text('quiz.review'.tr())),
        body: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            if (state is QuizLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is QuizReviewLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.questions.length,
                itemBuilder: (context, index) {
                  final q = state.questions[index];
                  Color? bgColor;
                  IconData icon = Icons.help_outline;
                  if (q.state == 'gradedright') {
                    bgColor = Colors.green.withValues(alpha: 0.1);
                    icon = Icons.check_circle;
                  } else if (q.state == 'gradedwrong') {
                    bgColor = Colors.red.withValues(alpha: 0.1);
                    icon = Icons.cancel;
                  } else if (q.state == 'gradedpartial') {
                    bgColor = Colors.orange.withValues(alpha: 0.1);
                    icon = Icons.warning;
                  }

                  return Card(
                    color: bgColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${'quiz.question'.tr()} ${q.slot}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              if (q.mark != null)
                                Text(
                                  q.mark!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          HtmlWidget(q.html),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            if (state is QuizError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
