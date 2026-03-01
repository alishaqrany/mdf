/// System health info returned by local_mdf_api_get_system_health.
class SystemHealthModel {
  final String moodleVersion;
  final int moodleBuild;
  final String phpVersion;
  final String dbType;
  final int dbSizeBytes;
  final int datarootSizeBytes;
  final int freeDiskBytes;
  final int lastCronTime;
  final bool cronOverdue;
  final int activePlugins;
  final int totalFiles;
  final int cacheStores;
  final int serverUptimeSecs;
  final int memoryUsageBytes;
  final int memoryPeakBytes;
  final int memoryLimitBytes;
  final int pendingAdhocTasks;
  final int failedTasks24h;
  final int serverTime;

  const SystemHealthModel({
    required this.moodleVersion,
    required this.moodleBuild,
    required this.phpVersion,
    required this.dbType,
    required this.dbSizeBytes,
    required this.datarootSizeBytes,
    required this.freeDiskBytes,
    required this.lastCronTime,
    required this.cronOverdue,
    required this.activePlugins,
    required this.totalFiles,
    required this.cacheStores,
    required this.serverUptimeSecs,
    required this.memoryUsageBytes,
    required this.memoryPeakBytes,
    required this.memoryLimitBytes,
    required this.pendingAdhocTasks,
    required this.failedTasks24h,
    required this.serverTime,
  });

  factory SystemHealthModel.fromJson(Map<String, dynamic> json) {
    return SystemHealthModel(
      moodleVersion: json['moodle_version'] as String? ?? '',
      moodleBuild: json['moodle_build'] as int? ?? 0,
      phpVersion: json['php_version'] as String? ?? '',
      dbType: json['db_type'] as String? ?? '',
      dbSizeBytes: json['db_size_bytes'] as int? ?? 0,
      datarootSizeBytes: json['dataroot_size_bytes'] as int? ?? 0,
      freeDiskBytes: json['free_disk_bytes'] as int? ?? 0,
      lastCronTime: json['last_cron_time'] as int? ?? 0,
      cronOverdue: (json['cron_overdue'] as int? ?? 0) == 1,
      activePlugins: json['active_plugins'] as int? ?? 0,
      totalFiles: json['total_files'] as int? ?? 0,
      cacheStores: json['cache_stores'] as int? ?? 0,
      serverUptimeSecs: json['server_uptime_secs'] as int? ?? 0,
      memoryUsageBytes: json['memory_usage_bytes'] as int? ?? 0,
      memoryPeakBytes: json['memory_peak_bytes'] as int? ?? 0,
      memoryLimitBytes: json['memory_limit_bytes'] as int? ?? 0,
      pendingAdhocTasks: json['pending_adhoc_tasks'] as int? ?? 0,
      failedTasks24h: json['failed_tasks_24h'] as int? ?? 0,
      serverTime: json['server_time'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'moodle_version': moodleVersion,
    'moodle_build': moodleBuild,
    'php_version': phpVersion,
    'db_type': dbType,
    'db_size_bytes': dbSizeBytes,
    'dataroot_size_bytes': datarootSizeBytes,
    'free_disk_bytes': freeDiskBytes,
    'last_cron_time': lastCronTime,
    'cron_overdue': cronOverdue ? 1 : 0,
    'active_plugins': activePlugins,
    'total_files': totalFiles,
    'cache_stores': cacheStores,
    'server_uptime_secs': serverUptimeSecs,
    'memory_usage_bytes': memoryUsageBytes,
    'memory_peak_bytes': memoryPeakBytes,
    'memory_limit_bytes': memoryLimitBytes,
    'pending_adhoc_tasks': pendingAdhocTasks,
    'failed_tasks_24h': failedTasks24h,
    'server_time': serverTime,
  };
}
