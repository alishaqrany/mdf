import 'package:equatable/equatable.dart';

/// A course section containing modules.
class CourseSection extends Equatable {
  final int id;
  final String name;
  final String? summary;
  final int sectionNumber;
  final bool visible;
  final List<CourseModule> modules;

  const CourseSection({
    required this.id,
    required this.name,
    this.summary,
    required this.sectionNumber,
    this.visible = true,
    this.modules = const [],
  });

  @override
  List<Object?> get props => [id, name, sectionNumber];
}

/// A single activity/resource module within a course section.
class CourseModule extends Equatable {
  final int id;
  final String name;
  final int? instance;
  final String modName; // e.g., 'resource', 'quiz', 'forum', 'assign', etc.
  final String? modIcon;
  final String? description;
  final String? url;
  final bool visible;
  final bool? completion; // null=no tracking, true=complete, false=incomplete
  final int? completionState;
  final List<ModuleContent> contents;

  const CourseModule({
    required this.id,
    required this.name,
    this.instance,
    required this.modName,
    this.modIcon,
    this.description,
    this.url,
    this.visible = true,
    this.completion,
    this.completionState,
    this.contents = const [],
  });

  /// Whether this module is a quiz.
  bool get isQuiz => modName == 'quiz';
  bool get isAssignment => modName == 'assign';
  bool get isForum => modName == 'forum';
  bool get isResource => modName == 'resource';
  bool get isUrl => modName == 'url';
  bool get isPage => modName == 'page';
  bool get isBook => modName == 'book';
  bool get isLesson => modName == 'lesson';
  bool get isScorm => modName == 'scorm';
  bool get isH5P => modName == 'h5pactivity';
  bool get isLabel => modName == 'label';
  bool get isFolder => modName == 'folder';
  bool get isBBB => modName == 'bigbluebuttonbn';
  bool get isSubSection => modName == 'subsection';
  bool get isVideo =>
      contents.any((c) => c.mimeType?.startsWith('video/') == true);

  @override
  List<Object?> get props => [id, name, modName];
}

/// File/content within a module.
class ModuleContent extends Equatable {
  final String? type; // 'file', 'url', 'content'
  final String? fileName;
  final String? filePath;
  final String? fileSize;
  final String? fileUrl;
  final String? mimeType;
  final int? timeModified;
  final String? content; // For inline content

  const ModuleContent({
    this.type,
    this.fileName,
    this.filePath,
    this.fileSize,
    this.fileUrl,
    this.mimeType,
    this.timeModified,
    this.content,
  });

  bool get isPdf => mimeType == 'application/pdf';
  bool get isVideo => mimeType?.startsWith('video/') == true;
  bool get isImage => mimeType?.startsWith('image/') == true;
  bool get isAudio => mimeType?.startsWith('audio/') == true;

  @override
  List<Object?> get props => [fileName, fileUrl];
}
