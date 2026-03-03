import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/error/mdf_error_handler.dart';
import '../../data/datasources/course_visibility_remote_datasource.dart';
import '../../data/models/course_visibility_model.dart';

part 'course_visibility_event.dart';
part 'course_visibility_state.dart';

class CourseVisibilityBloc
    extends Bloc<CourseVisibilityEvent, CourseVisibilityState> {
  final MoodleApiClient apiClient;
  late final CourseVisibilityRemoteDataSource _dataSource;

  CourseVisibilityBloc({required this.apiClient})
    : super(CourseVisibilityInitial()) {
    _dataSource = CourseVisibilityRemoteDataSourceImpl(apiClient: apiClient);
    on<LoadCourseVisibility>(_onLoad);
    on<SetCourseVisibilityEvent>(_onSet);
    on<RemoveCourseVisibilityEvent>(_onRemove);
  }

  Future<void> _onLoad(
    LoadCourseVisibility event,
    Emitter<CourseVisibilityState> emit,
  ) async {
    emit(CourseVisibilityLoading());
    try {
      final overrides = await _dataSource.getCourseVisibility(
        courseid: event.courseid,
      );
      emit(CourseVisibilityLoaded(overrides: overrides));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'إخفاء المقررات (Course Visibility)',
      );
      emit(CourseVisibilityError(message: failure.message));
    }
  }

  Future<void> _onSet(
    SetCourseVisibilityEvent event,
    Emitter<CourseVisibilityState> emit,
  ) async {
    try {
      await _dataSource.setCourseVisibility(
        courseid: event.courseid,
        targettype: event.targettype,
        targetid: event.targetid,
        hidden: event.hidden,
      );
      // Reload after change
      add(const LoadCourseVisibility());
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'إخفاء المقررات (Course Visibility)',
      );
      emit(CourseVisibilityError(message: failure.message));
    }
  }

  Future<void> _onRemove(
    RemoveCourseVisibilityEvent event,
    Emitter<CourseVisibilityState> emit,
  ) async {
    try {
      await _dataSource.removeCourseVisibility(id: event.id);
      // Reload after removal
      add(const LoadCourseVisibility());
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'إخفاء المقررات (Course Visibility)',
      );
      emit(CourseVisibilityError(message: failure.message));
    }
  }
}
