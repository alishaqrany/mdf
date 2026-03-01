import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/search_result.dart';
import '../bloc/search_bloc.dart';

/// Unified search page — courses, users, with filters, history & debounce.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  late final SearchBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = SearchBloc(repository: sl(), prefs: sl());
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  void _search([SearchFilter? filter]) {
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      _bloc.add(PerformSearch(query: q, filter: filter));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: Text('search.title'.tr())),
        body: Column(
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'search.hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _bloc.add(const ClearSearch());
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                onChanged: (q) {
                  if (q.trim().length >= 2) {
                    _bloc.add(PerformSearch(query: q.trim()));
                  } else if (q.isEmpty) {
                    _bloc.add(const ClearSearch());
                  }
                },
              ),
            ),

            // Filter chips
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is! SearchResults) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'search.all'.tr(),
                        selected: state.filter == SearchFilter.all,
                        onSelected: () {
                          _bloc.add(
                            const ChangeSearchFilter(filter: SearchFilter.all),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'search.courses'.tr(),
                        count: state.courses.length,
                        selected: state.filter == SearchFilter.courses,
                        onSelected: () {
                          _bloc.add(
                            const ChangeSearchFilter(
                              filter: SearchFilter.courses,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'search.users'.tr(),
                        count: state.users.length,
                        selected: state.filter == SearchFilter.users,
                        onSelected: () {
                          _bloc.add(
                            const ChangeSearchFilter(
                              filter: SearchFilter.users,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  // Loading
                  if (state is SearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error
                  if (state is SearchError) {
                    return Center(child: Text(state.message));
                  }

                  // Initial — show recent searches
                  if (state is SearchInitial) {
                    if (state.recentSearches.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text('search.hint'.tr()),
                          ],
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'search.recent'.tr(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.recentSearches.length,
                            itemBuilder: (context, index) {
                              final q = state.recentSearches[index];
                              return ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(q),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _bloc.add(
                                      RemoveSearchHistoryItem(query: q),
                                    );
                                  },
                                ),
                                onTap: () {
                                  _controller.text = q;
                                  _search();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  // Results
                  if (state is SearchResults) {
                    if (state.results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text('common.no_results'.tr()),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.results.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final r = state.results[index];
                        return _SearchResultCard(result: r);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(count != null ? '$label ($count)' : label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: result.imageUrl != null
              ? NetworkImage(result.imageUrl!)
              : null,
          child: result.imageUrl == null
              ? Icon(_iconForType(result.type), size: 20)
              : null,
        ),
        title: Text(result.title),
        subtitle: result.subtitle != null
            ? Text(
                result.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Chip(
          label: Text(
            _labelForType(result.type, context),
            style: const TextStyle(fontSize: 11),
          ),
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => _navigate(context),
      ),
    );
  }

  IconData _iconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.course:
        return Icons.school;
      case SearchResultType.user:
        return Icons.person;
      case SearchResultType.activity:
        return Icons.extension;
    }
  }

  String _labelForType(SearchResultType type, BuildContext context) {
    switch (type) {
      case SearchResultType.course:
        return 'search.courses'.tr();
      case SearchResultType.user:
        return 'search.users'.tr();
      case SearchResultType.activity:
        return 'search.activities'.tr();
    }
  }

  void _navigate(BuildContext context) {
    switch (result.type) {
      case SearchResultType.course:
        context.push(
          '/student/course/${result.id}?title=${Uri.encodeComponent(result.title)}',
        );
        break;
      case SearchResultType.user:
        context.push('/admin/users/${result.id}');
        break;
      case SearchResultType.activity:
        break;
    }
  }
}
