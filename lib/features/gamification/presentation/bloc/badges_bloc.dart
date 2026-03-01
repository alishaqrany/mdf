import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gamification_entities.dart';
import '../../domain/repositories/gamification_repository.dart';

// ─── Events ───

abstract class BadgesEvent extends Equatable {
  const BadgesEvent();
  @override
  List<Object?> get props => [];
}

class LoadAllBadges extends BadgesEvent {
  final int userId;
  const LoadAllBadges(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadBadgeDetail extends BadgesEvent {
  final int badgeId;
  final int userId;
  const LoadBadgeDetail({required this.badgeId, required this.userId});
  @override
  List<Object?> get props => [badgeId, userId];
}

// ─── States ───

abstract class BadgesState extends Equatable {
  const BadgesState();
  @override
  List<Object?> get props => [];
}

class BadgesInitial extends BadgesState {}

class BadgesLoading extends BadgesState {}

class BadgesLoaded extends BadgesState {
  final List<Badge> allBadges;
  final List<Badge> earned;
  final List<Badge> locked;

  const BadgesLoaded({
    required this.allBadges,
    required this.earned,
    required this.locked,
  });

  @override
  List<Object?> get props => [allBadges, earned, locked];
}

class BadgeDetailLoaded extends BadgesState {
  final Badge badge;
  const BadgeDetailLoaded(this.badge);
  @override
  List<Object?> get props => [badge];
}

class BadgesError extends BadgesState {
  final String message;
  const BadgesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───

class BadgesBloc extends Bloc<BadgesEvent, BadgesState> {
  final GamificationRepository repository;

  BadgesBloc({required this.repository}) : super(BadgesInitial()) {
    on<LoadAllBadges>(_onLoadAll);
    on<LoadBadgeDetail>(_onLoadDetail);
  }

  Future<void> _onLoadAll(
    LoadAllBadges event,
    Emitter<BadgesState> emit,
  ) async {
    emit(BadgesLoading());
    final result = await repository.getAllBadges(event.userId);
    result.fold(
      (failure) => emit(BadgesError(failure.message)),
      (badges) {
        final earned = badges.where((b) => b.isEarned).toList();
        final locked = badges.where((b) => !b.isEarned).toList();
        emit(BadgesLoaded(allBadges: badges, earned: earned, locked: locked));
      },
    );
  }

  Future<void> _onLoadDetail(
    LoadBadgeDetail event,
    Emitter<BadgesState> emit,
  ) async {
    emit(BadgesLoading());
    final result =
        await repository.getBadgeDetail(event.badgeId, event.userId);
    result.fold(
      (failure) => emit(BadgesError(failure.message)),
      (badge) => emit(BadgeDetailLoaded(badge)),
    );
  }
}
