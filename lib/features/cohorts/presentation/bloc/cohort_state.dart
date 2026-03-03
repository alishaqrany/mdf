part of 'cohort_bloc.dart';

abstract class CohortState extends Equatable {
  const CohortState();

  @override
  List<Object?> get props => [];
}

class CohortInitial extends CohortState {}

class CohortLoading extends CohortState {}

class CohortsLoaded extends CohortState {
  final List<CohortModel> cohorts;
  final int total;

  const CohortsLoaded({required this.cohorts, required this.total});

  @override
  List<Object?> get props => [cohorts, total];
}

class CohortMembersLoaded extends CohortState {
  final int cohortid;
  final String cohortName;
  final List<CohortMemberModel> members;

  const CohortMembersLoaded({
    required this.cohortid,
    required this.cohortName,
    required this.members,
  });

  @override
  List<Object?> get props => [cohortid, members];
}

class CohortError extends CohortState {
  final String message;
  const CohortError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CohortActionSuccess extends CohortState {
  final String message;
  const CohortActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
