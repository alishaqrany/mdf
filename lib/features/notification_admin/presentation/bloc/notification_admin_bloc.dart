import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/notification_admin_remote_datasource.dart';
import 'notification_admin_event.dart';
import 'notification_admin_state.dart';

class NotificationAdminBloc
    extends Bloc<NotificationAdminEvent, NotificationAdminState> {
  final NotificationAdminRemoteDataSource _dataSource;

  NotificationAdminBloc({
    required NotificationAdminRemoteDataSource dataSource,
  })  : _dataSource = dataSource,
        super(const NotificationAdminInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<SendNotifications>(_onSendNotifications);
    on<LoadNotificationLog>(_onLoadLog);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<NotificationAdminState> emit,
  ) async {
    emit(const NotificationAdminLoading());
    try {
      final result = await _dataSource.getUsers(
        search: event.search,
        courseId: event.courseId,
        cohortId: event.cohortId,
      );
      final users = (result['users'] as List?)
              ?.map((u) => Map<String, dynamic>.from(u))
              .toList() ??
          [];
      emit(UsersLoaded(
        users: users,
        total: result['total'] ?? users.length,
      ));
    } catch (e) {
      emit(NotificationAdminError(message: e.toString()));
    }
  }

  Future<void> _onSendNotifications(
    SendNotifications event,
    Emitter<NotificationAdminState> emit,
  ) async {
    emit(const NotificationAdminLoading());
    try {
      final result = await _dataSource.sendNotification(
        userIds: event.userIds,
        subject: event.subject,
        message: event.message,
        sendFcm: event.sendFcm,
      );
      emit(NotificationSent(
        totalSent: result['total_sent'] ?? 0,
        totalFailed: result['total_failed'] ?? 0,
        message:
            '${result['total_sent'] ?? 0} sent, ${result['total_failed'] ?? 0} failed',
      ));
    } catch (e) {
      emit(NotificationAdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadLog(
    LoadNotificationLog event,
    Emitter<NotificationAdminState> emit,
  ) async {
    emit(const NotificationAdminLoading());
    try {
      final result = await _dataSource.getNotificationLog(
        page: event.page,
        status: event.status,
      );
      final logs = (result['logs'] as List?)
              ?.map((l) => Map<String, dynamic>.from(l))
              .toList() ??
          [];
      emit(NotificationLogLoaded(
        logs: logs,
        total: result['total'] ?? logs.length,
      ));
    } catch (e) {
      emit(NotificationAdminError(message: e.toString()));
    }
  }
}
