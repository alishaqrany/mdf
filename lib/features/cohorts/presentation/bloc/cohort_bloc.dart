import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/error/mdf_error_handler.dart';
import '../../data/datasources/cohort_remote_datasource.dart';
import '../../data/models/cohort_model.dart';

part 'cohort_event.dart';
part 'cohort_state.dart';

class CohortBloc extends Bloc<CohortEvent, CohortState> {
  final MoodleApiClient apiClient;
  late final CohortRemoteDataSource _dataSource;

  /// Cache cohort name when viewing members so we can display it.
  String _currentCohortName = '';

  CohortBloc({required this.apiClient}) : super(CohortInitial()) {
    _dataSource = CohortRemoteDataSourceImpl(apiClient: apiClient);
    on<LoadCohorts>(_onLoadCohorts);
    on<LoadCohortMembers>(_onLoadMembers);
    on<AddMembersToCohort>(_onAddMembers);
    on<RemoveMembersFromCohort>(_onRemoveMembers);
    on<CreateCohort>(_onCreateCohort);
    on<DeleteCohort>(_onDeleteCohort);
    on<SyncCohortToCourse>(_onSyncCohort);
    on<UnsyncCohortFromCourse>(_onUnsyncCohort);
    on<LoadCohortCourseSyncs>(_onLoadSyncs);
  }

  Future<void> _onLoadCohorts(
    LoadCohorts event,
    Emitter<CohortState> emit,
  ) async {
    emit(CohortLoading());
    try {
      final result = await _dataSource.getCohorts(
        search: event.search,
        page: event.page,
        perpage: event.perpage,
      );
      emit(CohortsLoaded(cohorts: result.cohorts, total: result.total));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  Future<void> _onLoadMembers(
    LoadCohortMembers event,
    Emitter<CohortState> emit,
  ) async {
    emit(CohortLoading());
    try {
      final members = await _dataSource.getCohortMembers(
        cohortid: event.cohortid,
      );
      emit(
        CohortMembersLoaded(
          cohortid: event.cohortid,
          cohortName: _currentCohortName,
          members: members,
        ),
      );
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  Future<void> _onAddMembers(
    AddMembersToCohort event,
    Emitter<CohortState> emit,
  ) async {
    try {
      await _dataSource.addCohortMembers(
        cohortid: event.cohortid,
        userids: event.userids,
      );
      // Reload members
      add(LoadCohortMembers(cohortid: event.cohortid));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  Future<void> _onRemoveMembers(
    RemoveMembersFromCohort event,
    Emitter<CohortState> emit,
  ) async {
    try {
      await _dataSource.removeCohortMembers(
        cohortid: event.cohortid,
        userids: event.userids,
      );
      // Reload members
      add(LoadCohortMembers(cohortid: event.cohortid));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  /// Set the current cohort name for display in member views.
  void setCohortName(String name) => _currentCohortName = name;

  Future<void> _onCreateCohort(
    CreateCohort event,
    Emitter<CohortState> emit,
  ) async {
    emit(CohortLoading());
    try {
      await _dataSource.createCohort(
        name: event.name,
        idnumber: event.idnumber,
        description: event.description,
        visible: event.visible,
      );
      emit(const CohortActionSuccess(message: 'Cohort created successfully'));
      add(const LoadCohorts());
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  Future<void> _onDeleteCohort(
    DeleteCohort event,
    Emitter<CohortState> emit,
  ) async {
    try {
      await _dataSource.deleteCohort(cohortid: event.cohortid);
      emit(const CohortActionSuccess(message: 'Cohort deleted'));
      add(const LoadCohorts());
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  Future<void> _onSyncCohort(
    SyncCohortToCourse event,
    Emitter<CohortState> emit,
  ) async {
    try {
      await _dataSource.syncCohortToCourse(
        cohortid: event.cohortid,
        courseid: event.courseid,
        roleid: event.roleid,
      );
      emit(const CohortActionSuccess(message: 'Cohort synced to course'));
      add(LoadCohortCourseSyncs(cohortid: event.cohortid));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  Future<void> _onUnsyncCohort(
    UnsyncCohortFromCourse event,
    Emitter<CohortState> emit,
  ) async {
    try {
      await _dataSource.unsyncCohortFromCourse(
        cohortid: event.cohortid,
        courseid: event.courseid,
      );
      emit(const CohortActionSuccess(message: 'Sync removed'));
      add(LoadCohortCourseSyncs(cohortid: event.cohortid));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }

  Future<void> _onLoadSyncs(
    LoadCohortCourseSyncs event,
    Emitter<CohortState> emit,
  ) async {
    emit(CohortLoading());
    try {
      final syncs = await _dataSource.getCohortCourseSyncs(
        cohortid: event.cohortid,
      );
      emit(CohortCourseSyncsLoaded(cohortid: event.cohortid, syncs: syncs));
    } catch (e) {
      final failure = MdfErrorHandler.handleException(
        e,
        featureName: 'الدفعات (Cohorts)',
      );
      emit(CohortError(message: failure.message));
    }
  }
}
