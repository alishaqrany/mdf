import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ai_entities.dart';
import '../bloc/ai_insights_bloc.dart';

class AiInsightsPage extends StatelessWidget {
  const AiInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthAuthenticated ? authState.user.id : 0;
        return sl<AiInsightsBloc>()..add(LoadStudentInsights(userId: userId));
      },
      child: const _AiInsightsView(),
    );
  }
}

class _AiInsightsView extends StatelessWidget {
  const _AiInsightsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'AI Assistant',
            onPressed: () {
              final loc = GoRouterState.of(context).matchedLocation;
              final prefix = loc.startsWith('/admin') ? '/admin' : '/student';
              context.push('$prefix/ai-chat');
            },
          ),
        ],
      ),
      body: BlocBuilder<AiInsightsBloc, AiInsightsState>(
        builder: (context, state) {
          if (state is AiInsightsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AiInsightsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          if (state is AiInsightsLoaded) {
            return _InsightsContent(insights: state.insights);
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  final StudentInsights insights;
  const _InsightsContent({required this.insights});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Overview Card ───
        FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: _OverviewCard(insights: insights),
        ),
        const SizedBox(height: 16),

        // ─── Performance Trend ───
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: _TrendCard(insights: insights),
        ),
        const SizedBox(height: 16),

        // ─── Course Predictions ───
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: _PredictionsSection(predictions: insights.predictions),
        ),
        const SizedBox(height: 16),

        // ─── Recommendations ───
        if (insights.recommendations.isNotEmpty) ...[
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _RecommendationsSection(
              recommendations: insights.recommendations,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ],
    );
  }
}

// ─── Overview Card ───
class _OverviewCard extends StatelessWidget {
  final StudentInsights insights;
  const _OverviewCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Performance Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overall: ${insights.overallPerformance.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularPercentIndicator(
                  radius: 30,
                  lineWidth: 5,
                  percent: (insights.overallPerformance / 100).clamp(0, 1),
                  center: Text(
                    '${insights.overallPerformance.toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: insights.overallPerformance >= 70
                      ? AppColors.success
                      : insights.overallPerformance >= 50
                      ? AppColors.warning
                      : AppColors.error,
                  backgroundColor: AppColors.primarySurface,
                ),
              ],
            ),
            const Divider(height: 28),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Study Streak',
                  value: '${insights.studyStreak}d',
                  color: AppColors.warning,
                ),
                _MiniStat(
                  icon: Icons.schedule_rounded,
                  label: 'Weekly Hours',
                  value: '${insights.weeklyActivityHours.toStringAsFixed(1)}h',
                  color: AppColors.info,
                ),
                _MiniStat(
                  icon: Icons.trending_up_rounded,
                  label: 'Trend',
                  value: insights.performanceTrend == 'improving'
                      ? '↑'
                      : insights.performanceTrend == 'declining'
                      ? '↓'
                      : '→',
                  color: insights.performanceTrend == 'improving'
                      ? AppColors.success
                      : insights.performanceTrend == 'declining'
                      ? AppColors.error
                      : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ─── Trend Card ───
class _TrendCard extends StatelessWidget {
  final StudentInsights insights;
  const _TrendCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strengths & Weaknesses',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SubjectChip(
                    label: 'Strongest',
                    subject: insights.strongestSubject,
                    color: AppColors.success,
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SubjectChip(
                    label: 'Needs Work',
                    subject: insights.weakestSubject,
                    color: AppColors.error,
                    icon: Icons.flag_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final String subject;
  final Color color;
  final IconData icon;

  const _SubjectChip({
    required this.label,
    required this.subject,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subject,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Predictions Section ───
class _PredictionsSection extends StatelessWidget {
  final List<PerformancePrediction> predictions;
  const _PredictionsSection({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (predictions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Course Predictions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...predictions.map((p) => _PredictionTile(prediction: p)),
      ],
    );
  }
}

class _PredictionTile extends StatelessWidget {
  final PerformancePrediction prediction;
  const _PredictionTile({required this.prediction});

  Color get _riskColor {
    switch (prediction.riskLevel) {
      case RiskLevel.low:
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.accent;
      case RiskLevel.critical:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prediction.courseName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prediction.riskLevel.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearPercentIndicator(
                    lineHeight: 8,
                    percent: (prediction.predictedGrade / 100).clamp(0, 1),
                    backgroundColor: AppColors.primarySurface,
                    progressColor: _riskColor,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${prediction.predictedGrade.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _riskColor,
                  ),
                ),
              ],
            ),
            if (prediction.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...prediction.suggestions
                  .take(2)
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s,
                              style: theme.textTheme.bodySmall?.copyWith(
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

// ─── Recommendations Section ───
class _RecommendationsSection extends StatelessWidget {
  final List<CourseRecommendation> recommendations;
  const _RecommendationsSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Recommended for You',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) =>
                _RecommendationCard(rec: recommendations[index]),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final CourseRecommendation rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 250,
      margin: const EdgeInsetsDirectional.only(end: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push(
              '/student/course/${rec.courseId}?title=${Uri.encodeComponent(rec.courseName)}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${(rec.confidenceScore * 100).toInt()}% match',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  rec.courseName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (rec.categoryName != null)
                  Text(
                    rec.categoryName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  rec.reasonText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
