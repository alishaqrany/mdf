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

class CreateCohort extends CohortEvent {
  final String name;
  final String idnumber;
  final String description;
  final bool visible;

  const CreateCohort({
    required this.name,
    this.idnumber = '',
    this.description = '',
    this.visible = true,
  });

  @override
  List<Object?> get props => [name, idnumber, description, visible];
}

class DeleteCohort extends CohortEvent {
  final int cohortid;
  const DeleteCohort({required this.cohortid});

  @override
  List<Object?> get props => [cohortid];
}

class SyncCohortToCourse extends CohortEvent {
  final int cohortid;
  final int courseid;
  final int roleid;

  const SyncCohortToCourse({
    required this.cohortid,
    required this.courseid,
    this.roleid = 5,
  });

  @override
  List<Object?> get props => [cohortid, courseid, roleid];
}

class UnsyncCohortFromCourse extends CohortEvent {
  final int cohortid;
  final int courseid;

  const UnsyncCohortFromCourse({
    required this.cohortid,
    required this.courseid,
  });

  @override
  List<Object?> get props => [cohortid, courseid];
}

class LoadCohortCourseSyncs extends CohortEvent {
  final int cohortid;
  const LoadCohortCourseSyncs({required this.cohortid});

  @override
  List<Object?> get props => [cohortid];
}
