import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/quiz.dart';
import '../bloc/quiz_bloc.dart';

/// Page for taking a quiz attempt. Renders each question with its answer
/// choices extracted from the Moodle HTML, allows selection, and navigates
/// between pages.
class QuizAttemptPage extends StatefulWidget {
  final int attemptId;
  final int quizId;

  const QuizAttemptPage({
    super.key,
    required this.attemptId,
    required this.quizId,
  });

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  late final QuizBloc _bloc;
  int _currentPage = 0;
  bool _hasNextPage = true;

  /// Stores user answers keyed by input name
  final Map<String, String> _answers = {};

  /// Current page questions
  List<QuizQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _bloc = QuizBloc(repository: sl())
      ..add(LoadAttemptQuestions(attemptId: widget.attemptId, page: 0));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('quiz.title'.tr()),
          actions: [
            TextButton.icon(
              onPressed: _confirmSubmit,
              icon: const Icon(Icons.send),
              label: Text('quiz.submit'.tr()),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
        body: BlocConsumer<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizAttemptSubmitted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('quiz.submitted_success'.tr())),
              );
              context.pop();
            }
            if (state is QuizError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is QuizLoading && _questions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is QuizQuestionsLoaded) {
              _questions = state.questions;
              // If API returned empty questions, no next page
              _hasNextPage = state.questions.isNotEmpty;
            }
            if (_questions.isEmpty && state is! QuizLoading) {
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
                      'quiz.no_questions'.tr(),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _confirmSubmit,
                      child: Text('quiz.submit'.tr()),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Page info bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppColors.primary.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${'quiz.page'.tr()} ${_currentPage + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${_questions.length} ${'quiz.questions'.tr()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Questions list
                Expanded(
                  child: state is QuizLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            return _QuestionCard(
                              question: _questions[index],
                              answers: _answers,
                              onAnswerChanged: (key, value) {
                                setState(() {
                                  _answers[key] = value;
                                });
                                // Auto-save answer
                                _bloc.add(
                                  SaveQuizAnswer(
                                    attemptId: widget.attemptId,
                                    data: {key: value},
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _currentPage--);
                        _bloc.add(
                          LoadAttemptQuestions(
                            attemptId: widget.attemptId,
                            page: _currentPage,
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: Text('quiz.previous'.tr()),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: _hasNextPage && _questions.isNotEmpty
                      ? FilledButton.icon(
                          onPressed: () {
                            setState(() => _currentPage++);
                            _bloc.add(
                              LoadAttemptQuestions(
                                attemptId: widget.attemptId,
                                page: _currentPage,
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: Text('quiz.next'.tr()),
                        )
                      : FilledButton.icon(
                          onPressed: _confirmSubmit,
                          icon: const Icon(Icons.check),
                          label: Text('quiz.submit'.tr()),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('quiz.submit'.tr()),
        content: Text('quiz.confirm_submit'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(SubmitQuizAttempt(attemptId: widget.attemptId));
            },
            child: Text('quiz.submit'.tr()),
          ),
        ],
      ),
    );
  }
}

/// Renders a single quiz question with native answer choices.
class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final Map<String, String> answers;
  final void Function(String key, String value) onAnswerChanged;

  const _QuestionCard({
    required this.question,
    required this.answers,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = _parseQuestion(question.html);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${'quiz.question'.tr()} ${question.slot}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Question text
            if (parsed.questionText.isNotEmpty)
              HtmlWidget(
                parsed.questionText,
                textStyle: theme.textTheme.bodyMedium,
              ),
            // Answer options (native radio buttons)
            if (parsed.options.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              ...parsed.options.map((option) {
                final answerKey = parsed.inputName;
                return RadioListTile<String>(
                  value: option.value,
                  groupValue: answers[answerKey],
                  onChanged: (val) {
                    if (val != null) onAnswerChanged(answerKey, val);
                  },
                  title: option.html.isNotEmpty
                      ? HtmlWidget(
                          option.html,
                          textStyle: theme.textTheme.bodyMedium,
                        )
                      : Text(option.text),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ] else ...[
              // Fallback: render raw question HTML (essay, matching, etc.)
              const SizedBox(height: 8),
              HtmlWidget(question.html, textStyle: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  /// Parses Moodle question HTML to extract question text and answer options.
  _ParsedQuestion _parseQuestion(String html) {
    String questionText = '';
    String inputName = 'q0:${question.slot}_answer';
    final options = <_AnswerOption>[];

    try {
      // Extract question text from .qtext
      final qtextMatch = RegExp(
        r'<div[^>]*class="[^"]*\bqtext\b[^"]*"[^>]*>(.*?)</div>',
        dotAll: true,
      ).firstMatch(html);
      if (qtextMatch != null) {
        questionText = qtextMatch.group(1)!.trim();
      } else {
        // Fallback: content before first input or answer block
        final beforeInput = RegExp(
          r'^(.*?)(?:<div[^>]*class="[^"]*\banswer\b|<input|<div[^>]*class="[^"]*\bablock\b)',
          dotAll: true,
        ).firstMatch(html);
        if (beforeInput != null) {
          questionText = beforeInput.group(1)!.trim();
        } else {
          questionText = html;
        }
      }

      // Extract input name
      final inputNameMatch = RegExp(r'name="(q\d+:\d+_\w+)"').firstMatch(html);
      if (inputNameMatch != null) {
        inputName = inputNameMatch.group(1)!;
      }

      // Extract radio buttons (multichoice)
      final radioPattern = RegExp(
        r'<input[^>]*type="radio"[^>]*value="([^"]*)"[^>]*/?\s*>\s*'
        r'(?:<label[^>]*>(.*?)</label>)?',
        dotAll: true,
      );
      for (final match in radioPattern.allMatches(html)) {
        final value = match.group(1) ?? '';
        final labelHtml = match.group(2) ?? '';
        final cleanText = labelHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (value.isNotEmpty && value != '-1') {
          options.add(
            _AnswerOption(
              value: value,
              text: cleanText,
              html: labelHtml.trim(),
            ),
          );
        }
      }

      // Try answer div pattern
      if (options.isEmpty) {
        final answerDivPattern = RegExp(
          r'<div[^>]*class="[^"]*\br\d+\b[^"]*"[^>]*>.*?'
          r'value="([^"]*)".*?'
          r'<(?:label|span)[^>]*>(.*?)</(?:label|span)>',
          dotAll: true,
        );
        for (final match in answerDivPattern.allMatches(html)) {
          final value = match.group(1) ?? '';
          final labelHtml = match.group(2) ?? '';
          final cleanText = labelHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (value.isNotEmpty && value != '-1') {
            options.add(
              _AnswerOption(
                value: value,
                text: cleanText,
                html: labelHtml.trim(),
              ),
            );
          }
        }
      }

      // Try checkbox pattern (multi-answer)
      if (options.isEmpty) {
        final checkboxPattern = RegExp(
          r'<input[^>]*type="checkbox"[^>]*value="([^"]*)"[^>]*/?\s*>\s*'
          r'(?:<label[^>]*>(.*?)</label>)?',
          dotAll: true,
        );
        for (final match in checkboxPattern.allMatches(html)) {
          final value = match.group(1) ?? '';
          final labelHtml = match.group(2) ?? '';
          final cleanText = labelHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (value.isNotEmpty) {
            options.add(
              _AnswerOption(
                value: value,
                text: cleanText,
                html: labelHtml.trim(),
              ),
            );
          }
        }
      }
    } catch (_) {
      // Parsing failed — fallback to raw HTML rendering
    }

    return _ParsedQuestion(
      questionText: questionText,
      inputName: inputName,
      options: options,
    );
  }
}

class _ParsedQuestion {
  final String questionText;
  final String inputName;
  final List<_AnswerOption> options;
  const _ParsedQuestion({
    required this.questionText,
    required this.inputName,
    required this.options,
  });
}

class _AnswerOption {
  final String value;
  final String text;
  final String html;
  const _AnswerOption({
    required this.value,
    required this.text,
    required this.html,
  });
}
