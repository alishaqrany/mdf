part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<String> recentSearches;
  const SearchInitial({this.recentSearches = const []});
  @override
  List<Object?> get props => [recentSearches];
}

class SearchLoading extends SearchState {}

class SearchResults extends SearchState {
  final List<SearchResult> results;
  final String query;
  final SearchFilter filter;

  const SearchResults({
    required this.results,
    required this.query,
    required this.filter,
  });

  List<SearchResult> get courses =>
      results.where((r) => r.type == SearchResultType.course).toList();

  List<SearchResult> get users =>
      results.where((r) => r.type == SearchResultType.user).toList();

  @override
  List<Object?> get props => [results, query, filter];
}

class SearchError extends SearchState {
  final String message;
  const SearchError({required this.message});
  @override
  List<Object?> get props => [message];
}
