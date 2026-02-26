part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final int userId;
  const LoadProfile({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final Map<String, dynamic> userData;
  const UpdateProfile({required this.userData});
  @override
  List<Object?> get props => [userData];
}
