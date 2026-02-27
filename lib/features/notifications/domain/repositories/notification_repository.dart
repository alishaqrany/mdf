import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotifications(int userId);
  Future<Either<Failure, int>> getUnreadCount(int userId);
  Future<Either<Failure, void>> markRead(int notificationId);
}
