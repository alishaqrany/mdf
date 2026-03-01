import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;
  final SharedPreferences prefs;

  static const _historyKey = 'search_history';
  static const _maxHistory = 10;

  SearchBloc({required this.repository, required this.prefs})
    : super(SearchInitial(recentSearches: _loadHistory(prefs))) {
    on<PerformSearch>(
      _onSearch,
      transformer: _debounceTransformer(const Duration(milliseconds: 400)),
    );
    on<ClearSearch>(_onClear);
    on<LoadSearchHistory>(_onLoadHistory);
    on<RemoveSearchHistoryItem>(_onRemoveHistoryItem);
    on<ChangeSearchFilter>(_onChangeFilter);
  }

  static EventTransformer<T> _debounceTransformer<T>(Duration duration) {
    return (events, mapper) => events
        .distinct()
        .transform(
          StreamTransformer<T, T>.fromHandlers(
            handleData: (data, sink) {
              Future.delayed(duration, () => sink.add(data));
            },
          ),
        )
        .asyncExpand(mapper);
  }

  static List<String> _loadHistory(SharedPreferences prefs) {
    return prefs.getStringList(_historyKey) ?? [];
  }

  void _saveToHistory(String query) {
    final history = List<String>.from(prefs.getStringList(_historyKey) ?? []);
    history.remove(query);
    history.insert(0, query);
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    prefs.setStringList(_historyKey, history);
  }

  Future<void> _onSearch(PerformSearch event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        SearchInitial(recentSearches: prefs.getStringList(_historyKey) ?? []),
      );
      return;
    }

    emit(SearchLoading());

    _saveToHistory(query);

    final filter = event.filter ?? SearchFilter.all;

    switch (filter) {
      case SearchFilter.all:
        final result = await repository.searchAll(query);
        result.fold(
          (f) => emit(SearchError(message: f.message)),
          (results) => emit(
            SearchResults(results: results, query: query, filter: filter),
          ),
        );
        break;
      case SearchFilter.courses:
        final result = await repository.searchCourses(query);
        result.fold(
          (f) => emit(SearchError(message: f.message)),
          (results) => emit(
            SearchResults(results: results, query: query, filter: filter),
          ),
        );
        break;
      case SearchFilter.users:
        final result = await repository.searchUsers(query);
        result.fold(
          (f) => emit(SearchError(message: f.message)),
          (results) => emit(
            SearchResults(results: results, query: query, filter: filter),
          ),
        );
        break;
    }
  }

  Future<void> _onClear(ClearSearch event, Emitter<SearchState> emit) async {
    emit(SearchInitial(recentSearches: prefs.getStringList(_historyKey) ?? []));
  }

  Future<void> _onLoadHistory(
    LoadSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchInitial(recentSearches: prefs.getStringList(_historyKey) ?? []));
  }

  Future<void> _onRemoveHistoryItem(
    RemoveSearchHistoryItem event,
    Emitter<SearchState> emit,
  ) async {
    final history = List<String>.from(prefs.getStringList(_historyKey) ?? []);
    history.remove(event.query);
    prefs.setStringList(_historyKey, history);
    emit(SearchInitial(recentSearches: history));
  }

  Future<void> _onChangeFilter(
    ChangeSearchFilter event,
    Emitter<SearchState> emit,
  ) async {
    if (state is SearchResults) {
      final current = state as SearchResults;
      add(PerformSearch(query: current.query, filter: event.filter));
    }
  }
}
