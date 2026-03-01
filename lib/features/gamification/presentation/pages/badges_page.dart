import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/gamification_entities.dart';
import '../bloc/badges_bloc.dart';
import '../widgets/gamification_widgets.dart';

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

    return BlocProvider(
      create: (_) => sl<BadgesBloc>()..add(LoadAllBadges(userId)),
      child: _BadgesView(userId: userId),
    );
  }
}

class _BadgesView extends StatefulWidget {
  final int userId;
  const _BadgesView({required this.userId});

  @override
  State<_BadgesView> createState() => _BadgesViewState();
}

class _BadgesViewState extends State<_BadgesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BadgeCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('gamification.badges')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('gamification.all_badges')),
            Tab(text: tr('gamification.earned')),
            Tab(text: tr('gamification.locked')),
          ],
        ),
      ),
      body: BlocBuilder<BadgesBloc, BadgesState>(
        builder: (context, state) {
          if (state is BadgesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BadgesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<BadgesBloc>().add(
                      LoadAllBadges(widget.userId),
                    ),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is BadgesLoaded) {
            return Column(
              children: [
                // Category filter
                _CategoryFilter(
                  selected: _selectedCategory,
                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _BadgesGrid(
                        badges: _filter(state.allBadges),
                        userId: widget.userId,
                      ),
                      _BadgesGrid(
                        badges: _filter(state.earned),
                        userId: widget.userId,
                      ),
                      _BadgesGrid(
                        badges: _filter(state.locked),
                        userId: widget.userId,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  List<Badge> _filter(List<Badge> badges) {
    if (_selectedCategory == null) return badges;
    return badges.where((b) => b.category == _selectedCategory).toList();
  }
}

// ─── Category Filter Chips ───
class _CategoryFilter extends StatelessWidget {
  final BadgeCategory? selected;
  final ValueChanged<BadgeCategory?> onChanged;

  const _CategoryFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip(context, null, tr('gamification.all')),
          ...BadgeCategory.values.map(
            (c) => _chip(context, c, _categoryLabel(c)),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, BadgeCategory? cat, String label) {
    final isActive = selected == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onChanged(cat),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  String _categoryLabel(BadgeCategory c) {
    switch (c) {
      case BadgeCategory.general:
        return tr('gamification.cat_general');
      case BadgeCategory.courses:
        return tr('gamification.cat_courses');
      case BadgeCategory.quizzes:
        return tr('gamification.cat_quizzes');
      case BadgeCategory.assignments:
        return tr('gamification.cat_assignments');
      case BadgeCategory.social:
        return tr('gamification.cat_social');
      case BadgeCategory.streaks:
        return tr('gamification.cat_streaks');
      case BadgeCategory.special:
        return tr('gamification.cat_special');
    }
  }
}

// ─── Badges Grid ───
class _BadgesGrid extends StatelessWidget {
  final List<Badge> badges;
  final int userId;

  const _BadgesGrid({required this.badges, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.military_tech_rounded,
              size: 64,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              tr('gamification.no_badges'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) => FadeInUp(
        duration: const Duration(milliseconds: 300),
        delay: Duration(milliseconds: (index % 6) * 60),
        child: BadgeCard(
          badge: badges[index],
          onTap: () => _showBadgeDetail(context, badges[index]),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Badge badge) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            BadgeCard(badge: badge),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (badge.criteria != null && badge.criteria!.isNotEmpty)
              Text(
                badge.criteria!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            if (badge.isEarned && badge.earnedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    '${tr('gamification.earned_on')} ${DateFormat('yyyy/MM/dd').format(badge.earnedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
