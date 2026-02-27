import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';

abstract class MessagingRepository {
  Future<Either<Failure, List<Conversation>>> getConversations(int userId);
  Future<Either<Failure, List<Message>>> getConversationMessages(
    int conversationId,
    int userId,
  );
  Future<Either<Failure, void>> sendMessage(int userId, String message);
}
