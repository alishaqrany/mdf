part of 'search_bloc.dart';

enum SearchFilter { all, courses, users }

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class PerformSearch extends SearchEvent {
  final String query;
  final SearchFilter? filter;
  const PerformSearch({required this.query, this.filter});
  @override
  List<Object?> get props => [query, filter];
}

class ClearSearch extends SearchEvent {
  const ClearSearch();
}

class LoadSearchHistory extends SearchEvent {
  const LoadSearchHistory();
}

class RemoveSearchHistoryItem extends SearchEvent {
  final String query;
  const RemoveSearchHistoryItem({required this.query});
  @override
  List<Object?> get props => [query];
}

class ChangeSearchFilter extends SearchEvent {
  final SearchFilter filter;
  const ChangeSearchFilter({required this.filter});
  @override
  List<Object?> get props => [filter];
}
