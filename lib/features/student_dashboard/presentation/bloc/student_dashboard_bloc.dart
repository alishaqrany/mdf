import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/repositories/courses_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

part 'student_dashboard_event.dart';
part 'student_dashboard_state.dart';

class StudentDashboardBloc
    extends Bloc<StudentDashboardEvent, StudentDashboardState> {
  final CoursesRepository coursesRepository;
  final AuthRepository authRepository;

  StudentDashboardBloc({
    required this.coursesRepository,
    required this.authRepository,
  }) : super(StudentDashboardInitial()) {
    on<LoadStudentDashboard>(_onLoad);
    on<RefreshStudentDashboard>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadStudentDashboard event,
    Emitter<StudentDashboardState> emit,
  ) async {
    emit(StudentDashboardLoading());
    await _loadDashboard(event.userId, emit);
  }

  Future<void> _onRefresh(
    RefreshStudentDashboard event,
    Emitter<StudentDashboardState> emit,
  ) async {
    await _loadDashboard(event.userId, emit);
  }

  Future<void> _loadDashboard(
    int userId,
    Emitter<StudentDashboardState> emit,
  ) async {
    // Load enrolled courses
    final coursesResult = await coursesRepository.getEnrolledCourses(userId);
    // Load recent courses
    final recentResult = await coursesRepository.getRecentCourses(userId);

    coursesResult.fold(
      (failure) => emit(StudentDashboardError(message: failure.message)),
      (courses) {
        final recentCourses = recentResult.fold(
          (_) => <Course>[],
          (recent) => recent,
        );

        final inProgress = courses
            .where(
              (c) => c.progress != null && c.progress! > 0 && c.progress! < 100,
            )
            .toList();
        final completed = courses
            .where(
              (c) =>
                  c.completed == true ||
                  (c.progress != null && c.progress == 100),
            )
            .toList();

        emit(
          StudentDashboardLoaded(
            enrolledCourses: courses,
            recentCourses: recentCourses,
            inProgressCourses: inProgress,
            completedCourses: completed,
            totalEnrolled: courses.length,
            totalCompleted: completed.length,
            totalInProgress: inProgress.length,
          ),
        );
      },
    );
  }
}
