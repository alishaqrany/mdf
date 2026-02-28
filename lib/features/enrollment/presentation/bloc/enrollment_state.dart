import 'package:equatable/equatable.dart';

import '../../domain/entities/enrolled_user.dart';

abstract class EnrollmentState extends Equatable {
  const EnrollmentState();

  @override
  List<Object?> get props => [];
}

class EnrollmentInitial extends EnrollmentState {}

class EnrollmentLoading extends EnrollmentState {}

class EnrolledUsersLoaded extends EnrollmentState {
  final List<EnrolledUser> users;

  const EnrolledUsersLoaded({required this.users});

  @override
  List<Object?> get props => [users];
}

class UserEnrolled extends EnrollmentState {}

class BulkUsersEnrolled extends EnrollmentState {
  final int count;

  const BulkUsersEnrolled({required this.count});

  @override
  List<Object?> get props => [count];
}

class UserUnenrolled extends EnrollmentState {}

class EnrollmentError extends EnrollmentState {
  final String message;

  const EnrollmentError({required this.message});

  @override
  List<Object?> get props => [message];
}
