import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/enrollment_repository.dart';
import 'enrollment_event.dart';
import 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final EnrollmentRepository repository;

  EnrollmentBloc({required this.repository}) : super(EnrollmentInitial()) {
    on<LoadEnrolledUsers>(_onLoadEnrolledUsers);
    on<EnrollUser>(_onEnrollUser);
    on<BulkEnrollUsers>(_onBulkEnrollUsers);
    on<UnenrollUser>(_onUnenrollUser);
  }

  Future<void> _onLoadEnrolledUsers(
    LoadEnrolledUsers event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final result = await repository.getEnrolledUsers(event.courseId);
    result.fold(
      (failure) => emit(EnrollmentError(message: failure.message)),
      (users) => emit(EnrolledUsersLoaded(users: users)),
    );
  }

  Future<void> _onEnrollUser(
    EnrollUser event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final result = await repository.enrollUser(
      courseId: event.courseId,
      userId: event.userId,
      roleId: event.roleId,
    );
    result.fold(
      (failure) => emit(EnrollmentError(message: failure.message)),
      (_) => emit(UserEnrolled()),
    );
  }

  Future<void> _onBulkEnrollUsers(
    BulkEnrollUsers event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final result = await repository.bulkEnrollUsers(
      courseId: event.courseId,
      userIds: event.userIds,
      roleId: event.roleId,
    );
    result.fold(
      (failure) => emit(EnrollmentError(message: failure.message)),
      (_) => emit(BulkUsersEnrolled(count: event.userIds.length)),
    );
  }

  Future<void> _onUnenrollUser(
    UnenrollUser event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final result = await repository.unenrollUser(
      courseId: event.courseId,
      userId: event.userId,
    );
    result.fold(
      (failure) => emit(EnrollmentError(message: failure.message)),
      (_) => emit(UserUnenrolled()),
    );
  }
}
