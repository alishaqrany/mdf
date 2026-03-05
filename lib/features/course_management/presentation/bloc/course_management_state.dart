import 'package:equatable/equatable.dart';

abstract class CourseManagementState extends Equatable {
  const CourseManagementState();

  @override
  List<Object?> get props => [];
}

class CourseManagementInitial extends CourseManagementState {
  const CourseManagementInitial();
}

class CourseManagementLoading extends CourseManagementState {
  const CourseManagementLoading();
}

class CourseManagementSuccess extends CourseManagementState {
  final String message;
  final Map<String, dynamic>? data;

  const CourseManagementSuccess({required this.message, this.data});

  @override
  List<Object?> get props => [message, data];
}

class CourseManagementError extends CourseManagementState {
  final String message;

  const CourseManagementError({required this.message});

  @override
  List<Object?> get props => [message];
}
