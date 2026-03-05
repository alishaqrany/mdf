import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/course_management_remote_datasource.dart';
import 'course_management_event.dart';
import 'course_management_state.dart';

class CourseManagementBloc
    extends Bloc<CourseManagementEvent, CourseManagementState> {
  final CourseManagementRemoteDataSource _dataSource;

  CourseManagementBloc({required CourseManagementRemoteDataSource dataSource})
    : _dataSource = dataSource,
      super(const CourseManagementInitial()) {
    on<AddSection>(_onAddSection);
    on<UpdateSection>(_onUpdateSection);
    on<DeleteSection>(_onDeleteSection);
    on<MoveSection>(_onMoveSection);
    on<AddModule>(_onAddModule);
    on<UpdateModule>(_onUpdateModule);
    on<DeleteModule>(_onDeleteModule);
    on<MoveModule>(_onMoveModule);
  }

  Future<void> _onAddSection(
    AddSection event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.addSection(
        courseId: event.courseId,
        name: event.name,
        summary: event.summary,
      );
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Section added',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }

  Future<void> _onUpdateSection(
    UpdateSection event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.updateSection(
        sectionId: event.sectionId,
        name: event.name,
        summary: event.summary,
        visible: event.visible,
      );
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Section updated',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSection(
    DeleteSection event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.deleteSection(
        courseId: event.courseId,
        sectionId: event.sectionId,
      );
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Section deleted',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }

  Future<void> _onMoveSection(
    MoveSection event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.moveSection(
        courseId: event.courseId,
        sectionId: event.sectionId,
        position: event.position,
      );
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Section moved',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }

  Future<void> _onAddModule(
    AddModule event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.addModule(
        courseId: event.courseId,
        sectionNum: event.sectionNum,
        moduleName: event.moduleName,
        name: event.name,
        intro: event.intro,
        config: event.config,
      );
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Activity added',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }

  Future<void> _onUpdateModule(
    UpdateModule event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.updateModule(
        cmid: event.cmid,
        name: event.name,
        intro: event.intro,
        visible: event.visible,
        config: event.config,
      );
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Activity updated',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }

  Future<void> _onDeleteModule(
    DeleteModule event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.deleteModule(cmid: event.cmid);
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Activity deleted',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }

  Future<void> _onMoveModule(
    MoveModule event,
    Emitter<CourseManagementState> emit,
  ) async {
    emit(const CourseManagementLoading());
    try {
      final result = await _dataSource.moveModule(
        cmid: event.cmid,
        sectionId: event.sectionId,
        beforeMod: event.beforeMod,
      );
      emit(
        CourseManagementSuccess(
          message: result['message'] ?? 'Activity moved',
          data: result,
        ),
      );
    } catch (e) {
      emit(CourseManagementError(message: e.toString()));
    }
  }
}
