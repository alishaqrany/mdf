import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_repository.dart';

/// A button + expandable summary card that can be embedded
/// inside course content pages / module detail screens.
class ContentSummaryWidget extends StatefulWidget {
  final int courseId;
  final int moduleId;
  final String moduleTitle;

  const ContentSummaryWidget({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  State<ContentSummaryWidget> createState() => _ContentSummaryWidgetState();
}

class _ContentSummaryWidgetState extends State<ContentSummaryWidget> {
  bool _loading = false;
  ContentSummary? _summary;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = sl<AiRepository>();
    final result = await repo.summarizeContent(
      widget.courseId,
      widget.moduleId,
    );

    result.fold(
      (failure) => setState(() {
        _error = failure.toString();
        _loading = false;
      }),
      (summary) => setState(() {
        _summary = summary;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_summary != null) {
      return FadeIn(child: _SummaryCard(summary: _summary!));
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: _generate,
                    icon: const Icon(Icons.summarize_outlined, size: 18),
                    label: const Text('Summarize'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ContentSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 12, color: AppColors.info),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.estimatedReadTime} min read',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary text
            Text(
              summary.summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 14),

            // Key points
            if (summary.keyPoints.isNotEmpty) ...[
              Text(
                'Key Points',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...summary.keyPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A standalone page wrapper for the Content Summary Widget.
class ContentSummaryPage extends StatelessWidget {
  final int courseId;
  final int moduleId;
  final String moduleTitle;

  const ContentSummaryPage({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(moduleTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ContentSummaryWidget(
          courseId: courseId,
          moduleId: moduleId,
          moduleTitle: moduleTitle,
        ),
      ),
    );
  }
}
