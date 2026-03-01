import 'dart:async';

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
/// between pages. Includes countdown timer, question navigator, and flagging.
class QuizAttemptPage extends StatefulWidget {
  final int attemptId;
  final int quizId;
  final int? timeLimit; // seconds

  const QuizAttemptPage({
    super.key,
    required this.attemptId,
    required this.quizId,
    this.timeLimit,
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

  /// Flagged question slots
  final Set<int> _flaggedSlots = {};

  /// All questions accumulated across pages
  final Map<int, List<QuizQuestion>> _pageQuestions = {};

  /// Current page questions
  List<QuizQuestion> _questions = [];

  /// Countdown timer
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _timerExpired = false;

  @override
  void initState() {
    super.initState();
    _bloc = QuizBloc(repository: sl())
      ..add(LoadAttemptQuestions(attemptId: widget.attemptId, page: 0));

    // Start countdown timer if quiz has a time limit
    if (widget.timeLimit != null && widget.timeLimit! > 0) {
      _remainingSeconds = widget.timeLimit!;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _timerExpired = true;
            _countdownTimer?.cancel();
            // Auto-submit when timer expires
            _autoSubmit();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bloc.close();
    super.dispose();
  }

  void _autoSubmit() {
    _bloc.add(SubmitQuizAttempt(attemptId: widget.attemptId));
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (_remainingSeconds <= 60) return Colors.red;
    if (_remainingSeconds <= 300) return Colors.orange;
    return Colors.white;
  }

  List<QuizQuestion> get _allQuestions {
    final all = <QuizQuestion>[];
    final sortedKeys = _pageQuestions.keys.toList()..sort();
    for (final k in sortedKeys) {
      all.addAll(_pageQuestions[k]!);
    }
    return all;
  }

  void _openQuestionNavigator() {
    final allQ = _allQuestions;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quiz.question_navigator'.tr(),
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allQ.asMap().entries.map((entry) {
                    final q = entry.value;
                    final answered = _answers.keys.any(
                      (k) => k.contains(':${q.slot}_'),
                    );
                    final flagged = _flaggedSlots.contains(q.slot);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        // Find which page this question is on
                        for (final pageEntry in _pageQuestions.entries) {
                          if (pageEntry.value.any((pq) => pq.slot == q.slot)) {
                            setState(() => _currentPage = pageEntry.key);
                            _bloc.add(
                              LoadAttemptQuestions(
                                attemptId: widget.attemptId,
                                page: pageEntry.key,
                              ),
                            );
                            break;
                          }
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: answered
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: answered
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${q.slot}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: answered
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                            if (flagged)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Icon(
                                  Icons.flag,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(
                  AppColors.primary.withValues(alpha: 0.15),
                  'quiz.answered'.tr(),
                ),
                const SizedBox(width: 16),
                _legendItem(
                  Colors.grey.withValues(alpha: 0.1),
                  'quiz.not_answered'.tr(),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'quiz.flagged'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
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
            // Question navigator button
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'quiz.question_navigator'.tr(),
              onPressed: _openQuestionNavigator,
            ),
            TextButton.icon(
              onPressed: _confirmSubmit,
              icon: const Icon(Icons.send),
              label: Text('quiz.submit'.tr()),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
          // Timer bar at the bottom of AppBar
          bottom: widget.timeLimit != null && widget.timeLimit! > 0
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(36),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    color: _remainingSeconds <= 60
                        ? Colors.red.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 18, color: _timerColor()),
                        const SizedBox(width: 8),
                        Text(
                          '${'quiz.time_remaining'.tr()}: ${_formatTime(_remainingSeconds)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _timerColor(),
                          ),
                        ),
                        if (_timerExpired) ...[
                          const SizedBox(width: 8),
                          Text(
                            'quiz.time_up'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : null,
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
              _pageQuestions[_currentPage] = List.from(state.questions);
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
                              isFlagged: _flaggedSlots.contains(
                                _questions[index].slot,
                              ),
                              onFlagToggle: () {
                                setState(() {
                                  final slot = _questions[index].slot;
                                  if (_flaggedSlots.contains(slot)) {
                                    _flaggedSlots.remove(slot);
                                  } else {
                                    _flaggedSlots.add(slot);
                                  }
                                });
                              },
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
    final allQ = _allQuestions;
    final answeredCount = allQ.where((q) {
      return _answers.keys.any((k) => k.contains(':${q.slot}_'));
    }).length;
    final unanswered = allQ.length - answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('quiz.submit'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('quiz.confirm_submit'.tr()),
            if (unanswered > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${'quiz.unanswered'.tr()}: $unanswered',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_flaggedSlots.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${'quiz.flagged'.tr()}: ${_flaggedSlots.length}',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
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
/// Supports: MCQ (single/multi), True/False, Short Answer, Essay, Numerical, Matching.
class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final Map<String, String> answers;
  final bool isFlagged;
  final VoidCallback onFlagToggle;
  final void Function(String key, String value) onAnswerChanged;

  const _QuestionCard({
    required this.question,
    required this.answers,
    required this.isFlagged,
    required this.onFlagToggle,
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
            // Question header with number & flag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                const Spacer(),
                // Flag button
                IconButton(
                  icon: Icon(
                    isFlagged ? Icons.flag : Icons.flag_outlined,
                    color: isFlagged ? Colors.orange : Colors.grey,
                    size: 22,
                  ),
                  tooltip: 'quiz.flag_question'.tr(),
                  onPressed: onFlagToggle,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Question text
            if (parsed.questionText.isNotEmpty)
              HtmlWidget(
                parsed.questionText,
                textStyle: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            // Render based on detected question type
            _buildAnswerWidget(context, parsed, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(
    BuildContext context,
    _ParsedQuestion parsed,
    ThemeData theme,
  ) {
    switch (parsed.questionType) {
      case _QuestionType.multichoiceSingle:
        return _buildRadioOptions(parsed, theme);
      case _QuestionType.multichoiceMulti:
        return _buildCheckboxOptions(parsed, theme);
      case _QuestionType.truefalse:
        return _buildRadioOptions(parsed, theme);
      case _QuestionType.shortanswer:
        return _buildTextInput(parsed, theme, maxLines: 1);
      case _QuestionType.essay:
        return _buildTextInput(parsed, theme, maxLines: 8);
      case _QuestionType.numerical:
        return _buildTextInput(parsed, theme, maxLines: 1, numeric: true);
      case _QuestionType.matching:
        return _buildMatchingWidget(parsed, theme);
      case _QuestionType.unknown:
        // Fallback: render raw question HTML
        return HtmlWidget(question.html, textStyle: theme.textTheme.bodyMedium);
    }
  }

  Widget _buildRadioOptions(_ParsedQuestion parsed, ThemeData theme) {
    if (parsed.options.isEmpty) {
      return HtmlWidget(question.html, textStyle: theme.textTheme.bodyMedium);
    }
    final answerKey = parsed.inputName;
    return Column(
      children: [
        const Divider(),
        ...parsed.options.map((option) {
          return RadioListTile<String>(
            value: option.value,
            groupValue: answers[answerKey],
            onChanged: (val) {
              if (val != null) onAnswerChanged(answerKey, val);
            },
            title: option.html.isNotEmpty
                ? HtmlWidget(option.html, textStyle: theme.textTheme.bodyMedium)
                : Text(option.text),
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCheckboxOptions(_ParsedQuestion parsed, ThemeData theme) {
    if (parsed.options.isEmpty) {
      return HtmlWidget(question.html, textStyle: theme.textTheme.bodyMedium);
    }
    return Column(
      children: [
        const Divider(),
        ...parsed.options.map((option) {
          final key = option.inputName ?? parsed.inputName;
          final isChecked = answers[key] == '1';
          return CheckboxListTile(
            value: isChecked,
            onChanged: (val) {
              onAnswerChanged(key, val == true ? '1' : '0');
            },
            title: option.html.isNotEmpty
                ? HtmlWidget(option.html, textStyle: theme.textTheme.bodyMedium)
                : Text(option.text),
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            controlAffinity: ListTileControlAffinity.leading,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextInput(
    _ParsedQuestion parsed,
    ThemeData theme, {
    int maxLines = 1,
    bool numeric = false,
  }) {
    final key = parsed.inputName;
    return TextField(
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: maxLines > 1
            ? 'quiz.enter_essay'.tr()
            : 'quiz.enter_answer'.tr(),
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: answers[key] ?? ''),
      onChanged: (val) => onAnswerChanged(key, val),
    );
  }

  Widget _buildMatchingWidget(_ParsedQuestion parsed, ThemeData theme) {
    if (parsed.matchingPairs.isEmpty) {
      return HtmlWidget(question.html, textStyle: theme.textTheme.bodyMedium);
    }
    return Column(
      children: [
        const Divider(),
        ...parsed.matchingPairs.map((pair) {
          final key = pair.inputName;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: pair.questionHtml.isNotEmpty
                      ? HtmlWidget(
                          pair.questionHtml,
                          textStyle: theme.textTheme.bodyMedium,
                        )
                      : Text(pair.questionText),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: answers[key],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    isExpanded: true,
                    items: pair.choices.map((c) {
                      return DropdownMenuItem(
                        value: c.value,
                        child: Text(c.text, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onAnswerChanged(key, val);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Parses Moodle question HTML to extract question text and answer options.
  _ParsedQuestion _parseQuestion(String html) {
    String questionText = '';
    String inputName = 'q0:${question.slot}_answer';
    final options = <_AnswerOption>[];
    final matchingPairs = <_MatchingPair>[];
    var questionType = _QuestionType.unknown;

    try {
      // Extract question text from .qtext
      final qtextMatch = RegExp(
        r'<div[^>]*class="[^"]*\bqtext\b[^"]*"[^>]*>(.*?)</div>',
        dotAll: true,
      ).firstMatch(html);
      if (qtextMatch != null) {
        questionText = qtextMatch.group(1)!.trim();
      } else {
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

      // Detect question type from CSS classes or input types
      final isMatchingQ =
          html.contains('class="answer') && html.contains('<select');
      final hasCheckbox = html.contains('type="checkbox"');
      final hasRadio = html.contains('type="radio"');
      final hasTextInput = RegExp(
        r'type="text"[^>]*class="[^"]*\bform-control\b',
      ).hasMatch(html);
      final hasTextArea = html.contains('<textarea');
      final isTrueFalse =
          question.type == 'truefalse' ||
          (hasRadio &&
              RegExp(r'>\s*(True|False|صح|خطأ|صواب)\s*<').hasMatch(html));

      if (isMatchingQ) {
        questionType = _QuestionType.matching;
        _parseMatching(html, matchingPairs, inputName);
      } else if (hasTextArea || question.type == 'essay') {
        questionType = _QuestionType.essay;
        // Extract textarea name
        final taName = RegExp(r'<textarea[^>]*name="([^"]*)"').firstMatch(html);
        if (taName != null) inputName = taName.group(1)!;
      } else if (question.type == 'numerical' ||
          (hasTextInput && !hasRadio && !hasCheckbox)) {
        questionType = hasTextInput || question.type == 'numerical'
            ? _QuestionType.numerical
            : _QuestionType.shortanswer;
        // Extract text input name
        final textName = RegExp(
          r'<input[^>]*type="text"[^>]*name="([^"]*)"',
        ).firstMatch(html);
        if (textName != null) inputName = textName.group(1)!;
        if (question.type == 'shortanswer') {
          questionType = _QuestionType.shortanswer;
        }
      } else if (isTrueFalse) {
        questionType = _QuestionType.truefalse;
        _parseRadioOptions(html, options, inputName);
      } else if (hasCheckbox) {
        questionType = _QuestionType.multichoiceMulti;
        _parseCheckboxOptions(html, options);
      } else if (hasRadio) {
        questionType = _QuestionType.multichoiceSingle;
        _parseRadioOptions(html, options, inputName);
      } else if (question.type == 'shortanswer') {
        questionType = _QuestionType.shortanswer;
      } else if (question.type == 'essay') {
        questionType = _QuestionType.essay;
      }
    } catch (_) {
      // Parsing failed — fallback to raw HTML rendering
    }

    return _ParsedQuestion(
      questionText: questionText,
      inputName: inputName,
      options: options,
      questionType: questionType,
      matchingPairs: matchingPairs,
    );
  }

  void _parseRadioOptions(
    String html,
    List<_AnswerOption> options,
    String inputName,
  ) {
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
          _AnswerOption(value: value, text: cleanText, html: labelHtml.trim()),
        );
      }
    }
    // Fallback: answer div pattern
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
  }

  void _parseCheckboxOptions(String html, List<_AnswerOption> options) {
    final checkboxPattern = RegExp(
      r'<input[^>]*type="checkbox"[^>]*name="([^"]*)"[^>]*value="([^"]*)"[^>]*/?\s*>\s*'
      r'(?:<label[^>]*>(.*?)</label>)?',
      dotAll: true,
    );
    for (final match in checkboxPattern.allMatches(html)) {
      final name = match.group(1) ?? '';
      final value = match.group(2) ?? '';
      final labelHtml = match.group(3) ?? '';
      final cleanText = labelHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (value.isNotEmpty) {
        options.add(
          _AnswerOption(
            value: value,
            text: cleanText,
            html: labelHtml.trim(),
            inputName: name,
          ),
        );
      }
    }
  }

  void _parseMatching(
    String html,
    List<_MatchingPair> pairs,
    String baseInputName,
  ) {
    // Moodle matching: <tr> with question text + <select name="...">
    final rowPattern = RegExp(
      r'<tr[^>]*>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>\s*<select[^>]*name="([^"]*)"[^>]*>(.*?)</select>',
      dotAll: true,
    );
    for (final match in rowPattern.allMatches(html)) {
      final qHtml = match.group(1)?.trim() ?? '';
      final selectName = match.group(2) ?? '';
      final optionsHtml = match.group(3) ?? '';
      final qText = qHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      final choices = <_MatchChoice>[];
      final optPattern = RegExp(
        r'<option[^>]*value="([^"]*)"[^>]*>(.*?)</option>',
        dotAll: true,
      );
      for (final optMatch in optPattern.allMatches(optionsHtml)) {
        final val = optMatch.group(1) ?? '';
        final label = (optMatch.group(2) ?? '')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim();
        choices.add(_MatchChoice(value: val, text: label));
      }

      pairs.add(
        _MatchingPair(
          questionText: qText,
          questionHtml: qHtml,
          inputName: selectName,
          choices: choices,
        ),
      );
    }
  }
}

enum _QuestionType {
  multichoiceSingle,
  multichoiceMulti,
  truefalse,
  shortanswer,
  essay,
  numerical,
  matching,
  unknown,
}

class _ParsedQuestion {
  final String questionText;
  final String inputName;
  final List<_AnswerOption> options;
  final _QuestionType questionType;
  final List<_MatchingPair> matchingPairs;

  const _ParsedQuestion({
    required this.questionText,
    required this.inputName,
    required this.options,
    required this.questionType,
    this.matchingPairs = const [],
  });
}

class _AnswerOption {
  final String value;
  final String text;
  final String html;
  final String? inputName; // For checkboxes that have individual input names

  const _AnswerOption({
    required this.value,
    required this.text,
    required this.html,
    this.inputName,
  });
}

class _MatchingPair {
  final String questionText;
  final String questionHtml;
  final String inputName;
  final List<_MatchChoice> choices;

  const _MatchingPair({
    required this.questionText,
    required this.questionHtml,
    required this.inputName,
    required this.choices,
  });
}

class _MatchChoice {
  final String value;
  final String text;

  const _MatchChoice({required this.value, required this.text});
}
