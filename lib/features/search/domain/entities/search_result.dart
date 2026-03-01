import 'package:equatable/equatable.dart';

/// Unified search result types.
enum SearchResultType { course, user, activity }

/// A unified search result.
class SearchResult extends Equatable {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final SearchResultType type;
  final Map<String, dynamic>? extra;

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.type,
    this.extra,
  });

  @override
  List<Object?> get props => [id, type, title];
}
