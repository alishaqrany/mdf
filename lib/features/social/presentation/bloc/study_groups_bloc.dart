import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/social_entities.dart';
import '../../domain/repositories/social_repository.dart';

// ─── Events ───
abstract class StudyGroupsEvent extends Equatable {
  const StudyGroupsEvent();
  @override
  List<Object?> get props => [];
}

class LoadStudyGroups extends StudyGroupsEvent {
  final int? courseId;
  const LoadStudyGroups({this.courseId});
  @override
  List<Object?> get props => [courseId];
}

class LoadGroupDetail extends StudyGroupsEvent {
  final int groupId;
  const LoadGroupDetail(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class CreateStudyGroup extends StudyGroupsEvent {
  final String name;
  final int courseId;
  final String? description;
  final bool isPublic;
  final int maxMembers;

  const CreateStudyGroup({
    required this.name,
    required this.courseId,
    this.description,
    this.isPublic = true,
    this.maxMembers = 30,
  });

  @override
  List<Object?> get props => [name, courseId];
}

class JoinStudyGroup extends StudyGroupsEvent {
  final int groupId;
  const JoinStudyGroup(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class LeaveStudyGroup extends StudyGroupsEvent {
  final int groupId;
  const LeaveStudyGroup(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class DeleteStudyGroup extends StudyGroupsEvent {
  final int groupId;
  const DeleteStudyGroup(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

// ─── States ───
abstract class StudyGroupsState extends Equatable {
  const StudyGroupsState();
  @override
  List<Object?> get props => [];
}

class StudyGroupsInitial extends StudyGroupsState {}

class StudyGroupsLoading extends StudyGroupsState {}

class StudyGroupsLoaded extends StudyGroupsState {
  final List<StudyGroup> groups;
  const StudyGroupsLoaded(this.groups);
  @override
  List<Object?> get props => [groups];
}

class StudyGroupDetailLoaded extends StudyGroupsState {
  final StudyGroup group;
  final List<GroupMember> members;
  const StudyGroupDetailLoaded({required this.group, required this.members});
  @override
  List<Object?> get props => [group, members];
}

class StudyGroupCreated extends StudyGroupsState {
  final StudyGroup group;
  const StudyGroupCreated(this.group);
  @override
  List<Object?> get props => [group];
}

class StudyGroupActionSuccess extends StudyGroupsState {
  final String message;
  const StudyGroupActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class StudyGroupsError extends StudyGroupsState {
  final String message;
  const StudyGroupsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class StudyGroupsBloc extends Bloc<StudyGroupsEvent, StudyGroupsState> {
  final SocialRepository repository;

  StudyGroupsBloc({required this.repository}) : super(StudyGroupsInitial()) {
    on<LoadStudyGroups>(_onLoadGroups);
    on<LoadGroupDetail>(_onLoadGroupDetail);
    on<CreateStudyGroup>(_onCreateGroup);
    on<JoinStudyGroup>(_onJoinGroup);
    on<LeaveStudyGroup>(_onLeaveGroup);
    on<DeleteStudyGroup>(_onDeleteGroup);
  }

  Future<void> _onLoadGroups(
    LoadStudyGroups event,
    Emitter<StudyGroupsState> emit,
  ) async {
    emit(StudyGroupsLoading());
    final result = await repository.getStudyGroups(courseId: event.courseId);
    result.fold(
      (failure) => emit(StudyGroupsError(failure.message)),
      (groups) => emit(StudyGroupsLoaded(groups)),
    );
  }

  Future<void> _onLoadGroupDetail(
    LoadGroupDetail event,
    Emitter<StudyGroupsState> emit,
  ) async {
    emit(StudyGroupsLoading());
    final groupResult = await repository.getGroupDetail(event.groupId);
    final membersResult = await repository.getGroupMembers(event.groupId);

    groupResult.fold((failure) => emit(StudyGroupsError(failure.message)), (
      group,
    ) {
      membersResult.fold(
        (failure) =>
            emit(StudyGroupDetailLoaded(group: group, members: const [])),
        (members) =>
            emit(StudyGroupDetailLoaded(group: group, members: members)),
      );
    });
  }

  Future<void> _onCreateGroup(
    CreateStudyGroup event,
    Emitter<StudyGroupsState> emit,
  ) async {
    emit(StudyGroupsLoading());
    final result = await repository.createStudyGroup(
      name: event.name,
      courseId: event.courseId,
      description: event.description,
      isPublic: event.isPublic,
      maxMembers: event.maxMembers,
    );
    result.fold(
      (failure) => emit(StudyGroupsError(failure.message)),
      (group) => emit(StudyGroupCreated(group)),
    );
  }

  Future<void> _onJoinGroup(
    JoinStudyGroup event,
    Emitter<StudyGroupsState> emit,
  ) async {
    final result = await repository.joinStudyGroup(event.groupId);
    result.fold(
      (failure) => emit(StudyGroupsError(failure.message)),
      (_) => emit(const StudyGroupActionSuccess('joined')),
    );
  }

  Future<void> _onLeaveGroup(
    LeaveStudyGroup event,
    Emitter<StudyGroupsState> emit,
  ) async {
    final result = await repository.leaveStudyGroup(event.groupId);
    result.fold(
      (failure) => emit(StudyGroupsError(failure.message)),
      (_) => emit(const StudyGroupActionSuccess('left')),
    );
  }

  Future<void> _onDeleteGroup(
    DeleteStudyGroup event,
    Emitter<StudyGroupsState> emit,
  ) async {
    final result = await repository.deleteStudyGroup(event.groupId);
    result.fold(
      (failure) => emit(StudyGroupsError(failure.message)),
      (_) => emit(const StudyGroupActionSuccess('deleted')),
    );
  }
}
