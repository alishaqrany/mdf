part of 'cohort_bloc.dart';

abstract class CohortEvent extends Equatable {
  const CohortEvent();

  @override
  List<Object?> get props => [];
}

class LoadCohorts extends CohortEvent {
  final String search;
  final int page;
  final int perpage;

  const LoadCohorts({this.search = '', this.page = 0, this.perpage = 50});

  @override
  List<Object?> get props => [search, page, perpage];
}

class LoadCohortMembers extends CohortEvent {
  final int cohortid;
  const LoadCohortMembers({required this.cohortid});

  @override
  List<Object?> get props => [cohortid];
}

class AddMembersToCohort extends CohortEvent {
  final int cohortid;
  final List<int> userids;

  const AddMembersToCohort({required this.cohortid, required this.userids});

  @override
  List<Object?> get props => [cohortid, userids];
}

class RemoveMembersFromCohort extends CohortEvent {
  final int cohortid;
  final List<int> userids;

  const RemoveMembersFromCohort({
    required this.cohortid,
    required this.userids,
  });

  @override
  List<Object?> get props => [cohortid, userids];
}
