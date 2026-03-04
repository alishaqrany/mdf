import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/error/mdf_error_handler.dart';
import '../../data/datasources/courses_remote_datasource.dart';
import '../../data/models/course_model.dart';

part 'course_create_event.dart';
part 'course_create_state.dart';

class CourseCreateBloc extends Bloc<CourseCreateEvent, CourseCreateState> {
  final MoodleApiClient apiClient;
  final CoursesRemoteDataSource coursesDataSource;

  CourseCreateBloc({required this.apiClient, required this.coursesDataSource})
    : super(CourseCreateInitial()) {
    on<LoadCategoriesForCreate>(_onLoadCategories);
    on<SubmitCourseCreate>(_onSubmit);
  }

  Future<void> _onLoadCategories(
    LoadCategoriesForCreate event,
    Emitter<CourseCreateState> emit,
  ) async {
    emit(CourseCreateLoading());
    try {
      final categories = await coursesDataSource.getCategories();
      emit(CategoriesLoadedForCreate(categories: categories));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'إنشاء مقرر (Course Creation)',
      );
      emit(CourseCreateError(message: failure.message));
    }
  }

  Future<void> _onSubmit(
    SubmitCourseCreate event,
    Emitter<CourseCreateState> emit,
  ) async {
    emit(CourseCreateSubmitting());
    try {
      final params = <String, dynamic>{
        'courses[0][fullname]': event.fullName,
        'courses[0][shortname]': event.shortName,
        'courses[0][categoryid]': event.categoryId,
      };

      if (event.summary != null && event.summary!.isNotEmpty) {
        params['courses[0][summary]'] = event.summary!;
        params['courses[0][summaryformat]'] = 1;
      }
      if (event.visible != null) {
        params['courses[0][visible]'] = event.visible! ? 1 : 0;
      }
      if (event.startDate != null) {
        params['courses[0][startdate]'] =
            event.startDate!.millisecondsSinceEpoch ~/ 1000;
      }
      if (event.endDate != null) {
        params['courses[0][enddate]'] =
            event.endDate!.millisecondsSinceEpoch ~/ 1000;
      }
      if (event.format != null && event.format!.isNotEmpty) {
        params['courses[0][format]'] = event.format!;
      }
      if (event.numSections != null) {
        params['courses[0][numsections]'] = event.numSections!;
      }

      final response = await apiClient.call(
        MoodleApiEndpoints.createCourses,
        params: params,
      );

      int? newCourseId;
      if (response is List && response.isNotEmpty) {
        newCourseId = (response.first as Map<String, dynamic>)['id'] as int?;
      }

      emit(
        CourseCreateSuccess(courseId: newCourseId, courseName: event.fullName),
      );
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'إنشاء مقرر (Course Creation)',
      );
      emit(CourseCreateError(message: failure.message));
    }
  }
}
