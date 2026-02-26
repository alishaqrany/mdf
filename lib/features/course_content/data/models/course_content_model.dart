import '../../domain/entities/course_content.dart';

class CourseSectionModel extends CourseSection {
  const CourseSectionModel({
    required super.id,
    required super.name,
    super.summary,
    required super.sectionNumber,
    super.visible,
    super.modules,
  });

  factory CourseSectionModel.fromJson(Map<String, dynamic> json) {
    final modulesJson = json['modules'] as List? ?? [];
    return CourseSectionModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String?,
      sectionNumber: json['section'] as int? ?? 0,
      visible: (json['visible'] as int?) == 1,
      modules: modulesJson
          .map((m) => CourseModuleModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CourseModuleModel extends CourseModule {
  const CourseModuleModel({
    required super.id,
    required super.name,
    super.instance,
    required super.modName,
    super.modIcon,
    super.description,
    super.url,
    super.visible,
    super.completion,
    super.completionState,
    super.contents,
  });

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) {
    final contentsJson = json['contents'] as List? ?? [];
    final completionData = json['completiondata'] as Map<String, dynamic>?;

    int? completionState;
    bool? completion;
    if (completionData != null) {
      completionState = completionData['state'] as int?;
      completion = completionState != null && completionState > 0;
    }

    return CourseModuleModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      instance: json['instance'] as int?,
      modName: json['modname'] as String? ?? '',
      modIcon: json['modicon'] as String?,
      description: json['description'] as String?,
      url: json['url'] as String?,
      visible: (json['visible'] as int?) != 0,
      completion: completion,
      completionState: completionState,
      contents: contentsJson
          .map((c) => ModuleContentModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ModuleContentModel extends ModuleContent {
  const ModuleContentModel({
    super.type,
    super.fileName,
    super.filePath,
    super.fileSize,
    super.fileUrl,
    super.mimeType,
    super.timeModified,
    super.content,
  });

  factory ModuleContentModel.fromJson(Map<String, dynamic> json) {
    return ModuleContentModel(
      type: json['type'] as String?,
      fileName: json['filename'] as String?,
      filePath: json['filepath'] as String?,
      fileSize: json['filesize']?.toString(),
      fileUrl: json['fileurl'] as String?,
      mimeType: json['mimetype'] as String?,
      timeModified: json['timemodified'] as int?,
      content: json['content'] as String?,
    );
  }
}
