/// All Moodle Web Service function names used throughout the app.
class MoodleApiEndpoints {
  MoodleApiEndpoints._();

  // ─── Authentication & Site Info ───
  static const String getSiteInfo = 'core_webservice_get_site_info';
  static const String getMobileConfig = 'tool_mobile_get_config';
  static const String getPublicConfig = 'tool_mobile_get_public_config';
  static const String getAutoLoginKey = 'tool_mobile_get_autologin_key';

  // ─── User Management ───
  static const String getUsers = 'core_user_get_users';
  static const String getUsersByField = 'core_user_get_users_by_field';
  static const String createUsers = 'core_user_create_users';
  static const String updateUsers = 'core_user_update_users';
  static const String deleteUsers = 'core_user_delete_users';
  static const String getUserCourseProfiles =
      'core_user_get_course_user_profiles';
  static const String updateUserPicture = 'core_user_update_picture';

  // ─── Course Management ───
  static const String getCourses = 'core_course_get_courses';
  static const String getCoursesByField = 'core_course_get_courses_by_field';
  static const String getCategories = 'core_course_get_categories';
  static const String getCourseContents = 'core_course_get_contents';
  static const String searchCourses = 'core_course_search_courses';
  static const String createCourses = 'core_course_create_courses';
  static const String updateCourses = 'core_course_update_courses';
  static const String deleteCourses = 'core_course_delete_courses';
  static const String getRecentCourses = 'core_course_get_recent_courses';
  static const String getCoursesByTimeline =
      'core_course_get_enrolled_courses_by_timeline_classification';
  static const String viewCourse = 'core_course_view_course';

  // ─── Enrollment ───
  static const String getEnrolledUsers = 'enrol_get_enrolled_users';
  static const String getUsersCourses = 'enrol_get_users_courses';
  static const String manualEnrolUsers = 'enrol_manual_enrol_users';
  static const String manualUnenrolUsers = 'enrol_manual_unenrol_users';
  static const String selfEnrolUser = 'enrol_self_enrol_user';

  // ─── Completion ───
  static const String getActivitiesCompletionStatus =
      'core_completion_get_activities_completion_status';
  static const String updateActivityCompletion =
      'core_completion_update_activity_completion_status_manually';

  // ─── Content Modules ───
  static const String getResources = 'mod_resource_get_resources_by_courses';
  static const String getUrls = 'mod_url_get_urls_by_courses';
  static const String getPages = 'mod_page_get_pages_by_courses';
  static const String getFolders = 'mod_folder_get_folders_by_courses';
  static const String getBooks = 'mod_book_get_books_by_courses';
  static const String getLabels = 'mod_label_get_labels_by_courses';
  static const String getLessons = 'mod_lesson_get_lessons_by_courses';
  static const String getLessonPages = 'mod_lesson_get_pages';
  static const String getScorms = 'mod_scorm_get_scorms_by_courses';
  static const String getScormAttemptCount =
      'mod_scorm_get_scorm_attempt_count';
  static const String getScormScoTracks = 'mod_scorm_get_scorm_sco_tracks';
  static const String launchScorm = 'mod_scorm_launch_sco';
  static const String getScormScoes = 'mod_scorm_get_scorm_scoes';
  static const String insertScormTracks = 'mod_scorm_insert_scorm_tracks';

  // ─── H5P ───
  static const String getH5PActivities =
      'mod_h5pactivity_get_h5pactivities_by_courses';
  static const String getH5PAttempts = 'mod_h5pactivity_get_attempts';
  static const String getH5PResults = 'mod_h5pactivity_get_results';

  // ─── Quiz ───
  static const String getQuizzes = 'mod_quiz_get_quizzes_by_courses';
  static const String getQuizAccessInfo =
      'mod_quiz_get_quiz_access_information';
  static const String startAttempt = 'mod_quiz_start_attempt';
  static const String getAttemptData = 'mod_quiz_get_attempt_data';
  static const String processAttempt = 'mod_quiz_process_attempt';
  static const String saveAttempt = 'mod_quiz_save_attempt';
  static const String getAttemptSummary = 'mod_quiz_get_attempt_summary';
  static const String submitAttempt = 'mod_quiz_submit_attempt';
  static const String getAttemptReview = 'mod_quiz_get_attempt_review';
  static const String getUserAttempts = 'mod_quiz_get_user_attempts';
  static const String getUserBestGrade = 'mod_quiz_get_user_best_grade';

  // ─── Assignments ───
  static const String getAssignments = 'mod_assign_get_assignments';
  static const String getSubmissions = 'mod_assign_get_submissions';
  static const String submitForGrading = 'mod_assign_submit_for_grading';
  static const String saveSubmission = 'mod_assign_save_submission';
  static const String saveGrade = 'mod_assign_save_grade';
  static const String getAssignGrades = 'mod_assign_get_grades';

  // ─── Grades ───
  static const String getGradesTable = 'gradereport_user_get_grades_table';
  static const String getGradeItems = 'gradereport_user_get_grade_items';
  static const String getCourseGrades =
      'gradereport_overview_get_course_grades';

  // ─── Messaging ───
  static const String getMessages = 'core_message_get_messages';
  static const String sendInstantMessages =
      'core_message_send_instant_messages';
  static const String getConversations = 'core_message_get_conversations';
  static const String getConversationMessages =
      'core_message_get_conversation_messages';
  static const String getPopupNotifications =
      'message_popup_get_popup_notifications';
  static const String getUnreadNotificationCount =
      'message_popup_get_unread_popup_notification_count';
  static const String markNotificationRead =
      'core_message_mark_notification_read';

  // ─── Calendar ───
  static const String getCalendarEvents = 'core_calendar_get_calendar_events';
  static const String getCalendarMonthlyView =
      'core_calendar_get_calendar_monthly_view';
  static const String getCalendarUpcomingView =
      'core_calendar_get_calendar_upcoming_view';
  static const String createCalendarEvents =
      'core_calendar_create_calendar_events';
  static const String deleteCalendarEvents =
      'core_calendar_delete_calendar_events';

  // ─── Forums ───
  static const String getForums = 'mod_forum_get_forums_by_courses';
  static const String getForumDiscussions = 'mod_forum_get_forum_discussions';
  static const String getDiscussionPosts = 'mod_forum_get_discussion_posts';
  static const String addDiscussion = 'mod_forum_add_discussion';
  static const String addDiscussionPost = 'mod_forum_add_discussion_post';
  static const String setPinState = 'mod_forum_set_pin_state';
  static const String deletePost = 'mod_forum_delete_post';

  // ─── Files ───
  static const String getFiles = 'core_files_get_files';
  static const String uploadFiles = 'core_files_upload';

  // ─── BigBlueButton (Video Meetings) ───
  static const String getBBBInstances =
      'mod_bigbluebuttonbn_get_bigbluebuttonbns_by_courses';
  static const String getBBBMeetingInfo = 'mod_bigbluebuttonbn_meeting_info';
  static const String viewBBB = 'mod_bigbluebuttonbn_view_bigbluebuttonbn';

  // ─── Roles ───
  static const String assignRoles = 'core_role_assign_roles';
  static const String unassignRoles = 'core_role_unassign_roles';

  // ─── MDF Academy Custom Plugin (local_mdf_api) ───
  static const String mdfGetDashboardStats =
      'local_mdf_api_get_dashboard_stats';
  static const String mdfGetEnrollmentStats =
      'local_mdf_api_get_enrollment_stats';
  static const String mdfBulkEnrolUsers = 'local_mdf_api_bulk_enrol_users';
  static const String mdfGetActivityLogs = 'local_mdf_api_get_activity_logs';
  static const String mdfGetSystemHealth = 'local_mdf_api_get_system_health';
  static const String mdfSendPushNotification =
      'local_mdf_api_send_push_notification';
  static const String mdfRegisterFcmToken = 'local_mdf_api_register_fcm_token';

  // ─── Social / Study Groups (local_mdf_api) ───
  static const String mdfGetStudyGroups = 'local_mdf_api_get_study_groups';
  static const String mdfGetStudyGroupDetail =
      'local_mdf_api_get_study_group_detail';
  static const String mdfCreateStudyGroup = 'local_mdf_api_create_study_group';
  static const String mdfJoinStudyGroup = 'local_mdf_api_join_study_group';
  static const String mdfLeaveStudyGroup = 'local_mdf_api_leave_study_group';
  static const String mdfGetGroupMembers = 'local_mdf_api_get_group_members';
  static const String mdfUpdateGroupMemberRole =
      'local_mdf_api_update_group_member_role';
  static const String mdfDeleteStudyGroup = 'local_mdf_api_delete_study_group';

  // ─── Social / Study Notes (local_mdf_api) ───
  static const String mdfGetCourseNotes = 'local_mdf_api_get_course_notes';
  static const String mdfGetGroupNotes = 'local_mdf_api_get_group_notes';
  static const String mdfCreateNote = 'local_mdf_api_create_note';
  static const String mdfUpdateNote = 'local_mdf_api_update_note';
  static const String mdfDeleteNote = 'local_mdf_api_delete_note';
  static const String mdfToggleLikeNote = 'local_mdf_api_toggle_like_note';
  static const String mdfToggleBookmarkNote =
      'local_mdf_api_toggle_bookmark_note';
  static const String mdfGetNoteComments = 'local_mdf_api_get_note_comments';
  static const String mdfAddNoteComment = 'local_mdf_api_add_note_comment';

  // ─── Social / Peer Review (local_mdf_api) ───
  static const String mdfGetPendingReviews =
      'local_mdf_api_get_pending_reviews';
  static const String mdfGetCompletedReviews =
      'local_mdf_api_get_completed_reviews';
  static const String mdfGetReviewDetail = 'local_mdf_api_get_review_detail';
  static const String mdfSubmitReview = 'local_mdf_api_submit_review';

  // ─── Social / Collaborative Sessions (local_mdf_api) ───
  static const String mdfGetGroupSessions = 'local_mdf_api_get_group_sessions';
  static const String mdfCreateSession = 'local_mdf_api_create_session';
  static const String mdfJoinSession = 'local_mdf_api_join_session';
  static const String mdfLeaveSession = 'local_mdf_api_leave_session';
  static const String mdfEndSession = 'local_mdf_api_end_session';
  static const String mdfAddSessionNote = 'local_mdf_api_add_session_note';
}
