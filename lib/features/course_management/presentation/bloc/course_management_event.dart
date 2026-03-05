import 'package:equatable/equatable.dart';

abstract class CourseManagementEvent extends Equatable {
  const CourseManagementEvent();

  @override
  List<Object?> get props => [];
}

// ─── Section Events ───

class AddSection extends CourseManagementEvent {
  final int courseId;
  final String name;
  final String? summary;

  const AddSection({
    required this.courseId,
    required this.name,
    this.summary,
  });

  @override
  List<Object?> get props => [courseId, name, summary];
}

class UpdateSection extends CourseManagementEvent {
  final int sectionId;
  final String? name;
  final String? summary;
  final int? visible;

  const UpdateSection({
    required this.sectionId,
    this.name,
    this.summary,
    this.visible,
  });

  @override
  List<Object?> get props => [sectionId, name, summary, visible];
}

class DeleteSection extends CourseManagementEvent {
  final int courseId;
  final int sectionId;

  const DeleteSection({required this.courseId, required this.sectionId});

  @override
  List<Object?> get props => [courseId, sectionId];
}

class MoveSection extends CourseManagementEvent {
  final int courseId;
  final int sectionId;
  final int position;

  const MoveSection({
    required this.courseId,
    required this.sectionId,
    required this.position,
  });

  @override
  List<Object?> get props => [courseId, sectionId, position];
}

// ─── Module Events ───

class AddModule extends CourseManagementEvent {
  final int courseId;
  final int sectionNum;
  final String moduleName; // resource, page, label, assign, quiz, forum, url, folder
  final String name;
  final String? intro;
  final Map<String, dynamic>? config;

  const AddModule({
    required this.courseId,
    required this.sectionNum,
    required this.moduleName,
    required this.name,
    this.intro,
    this.config,
  });

  @override
  List<Object?> get props => [courseId, sectionNum, moduleName, name, intro, config];
}

class UpdateModule extends CourseManagementEvent {
  final int cmid;
  final String? name;
  final String? intro;
  final int? visible;
  final Map<String, dynamic>? config;

  const UpdateModule({
    required this.cmid,
    this.name,
    this.intro,
    this.visible,
    this.config,
  });

  @override
  List<Object?> get props => [cmid, name, intro, visible, config];
}

class DeleteModule extends CourseManagementEvent {
  final int cmid;

  const DeleteModule({required this.cmid});

  @override
  List<Object?> get props => [cmid];
}

class MoveModule extends CourseManagementEvent {
  final int cmid;
  final int sectionId;
  final int? beforeMod;

  const MoveModule({
    required this.cmid,
    required this.sectionId,
    this.beforeMod,
  });

  @override
  List<Object?> get props => [cmid, sectionId, beforeMod];
}
