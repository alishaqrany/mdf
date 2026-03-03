import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/social_entities.dart';
import '../bloc/peer_review_bloc.dart';
import '../widgets/review_card.dart';

class PeerReviewPage extends StatelessWidget {
  const PeerReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthAuthenticated ? authState.user.id : 0;
        return sl<PeerReviewBloc>()..add(LoadPendingReviews(userId));
      },
      child: const _PeerReviewView(),
    );
  }
}

class _PeerReviewView extends StatelessWidget {
  const _PeerReviewView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('social.peer_review')),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.pending_actions_rounded),
                text: tr('social.pending'),
              ),
              Tab(
                icon: const Icon(Icons.check_circle_rounded),
                text: tr('social.completed'),
              ),
            ],
          ),
        ),
        body: BlocBuilder<PeerReviewBloc, PeerReviewState>(
          builder: (context, state) {
            if (state is PeerReviewLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PeerReviewError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, style: theme.textTheme.bodyLarge),
                  ],
                ),
              );
            }

            if (state is PeerReviewListLoaded) {
              return TabBarView(
                children: [
                  _buildReviewList(
                    context,
                    state.pending,
                    tr('social.no_pending_reviews'),
                    Icons.pending_actions_outlined,
                  ),
                  _buildReviewList(
                    context,
                    state.completed,
                    tr('social.no_completed_reviews'),
                    Icons.check_circle_outlined,
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildReviewList(
    BuildContext context,
    List<PeerReview> reviews,
    String emptyText,
    IconData emptyIcon,
  ) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: AppColors.textTertiaryLight),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 60),
          child: ReviewCard(
            review: reviews[index],
            onTap: () => _showReviewDetail(context, reviews[index]),
          ),
        );
      },
    );
  }

  void _showReviewDetail(BuildContext context, PeerReview review) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final ratingCtrl = TextEditingController(
          text: review.rating?.toStringAsFixed(1) ?? '',
        );
        final feedbackCtrl = TextEditingController(text: review.feedback ?? '');

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ListView(
              controller: scrollController,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          review.status,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _statusIcon(review.status),
                        color: _statusColor(review.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.workshopName,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            review.courseName ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Submission info
                Text(
                  '${tr('social.submitted_by')}: ${review.submitterName}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (review.submissionContent != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      review.submissionContent!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],

                // Review form (for pending reviews)
                if (review.status == PeerReviewStatus.pending ||
                    review.status == PeerReviewStatus.inProgress) ...[
                  const SizedBox(height: 20),
                  Text(
                    tr('social.your_review'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ratingCtrl,
                    decoration: InputDecoration(
                      labelText:
                          '${tr('social.rating')} (0-${review.maxRating.toInt()})',
                      prefixIcon: const Icon(Icons.star_rounded),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: feedbackCtrl,
                    decoration: InputDecoration(
                      labelText: tr('social.feedback'),
                      prefixIcon: const Icon(Icons.rate_review_rounded),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    minLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final rating = double.tryParse(ratingCtrl.text);
                      if (rating != null &&
                          feedbackCtrl.text.trim().isNotEmpty) {
                        context.read<PeerReviewBloc>().add(
                          SubmitReview(
                            reviewId: review.id,
                            rating: rating,
                            feedback: feedbackCtrl.text.trim(),
                          ),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(tr('social.submit_review')),
                  ),
                ],

                // Completed review display
                if (review.status == PeerReviewStatus.completed &&
                    review.rating != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tr('social.your_rating'),
                                style: theme.textTheme.titleSmall,
                              ),
                              const Spacer(),
                              Text(
                                '${review.rating!.toStringAsFixed(1)}/${review.maxRating.toInt()}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (review.feedback != null) ...[
                            const Divider(),
                            Text(review.feedback!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(PeerReviewStatus status) {
    switch (status) {
      case PeerReviewStatus.pending:
        return AppColors.warning;
      case PeerReviewStatus.inProgress:
        return AppColors.info;
      case PeerReviewStatus.completed:
        return AppColors.success;
      case PeerReviewStatus.overdue:
        return AppColors.error;
    }
  }

  IconData _statusIcon(PeerReviewStatus status) {
    switch (status) {
      case PeerReviewStatus.pending:
        return Icons.pending_actions_rounded;
      case PeerReviewStatus.inProgress:
        return Icons.rate_review_rounded;
      case PeerReviewStatus.completed:
        return Icons.check_circle_rounded;
      case PeerReviewStatus.overdue:
        return Icons.warning_rounded;
    }
  }
}
