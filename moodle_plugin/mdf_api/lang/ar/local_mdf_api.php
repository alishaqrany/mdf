<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

/**
 * Language strings for local_mdf_api (Arabic).
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

$string['pluginname'] = 'واجهة MDF Academy API';

// Capabilities.
$string['mdf_api:viewstats'] = 'عرض إحصائيات لوحة التحكم';
$string['mdf_api:viewlogs'] = 'عرض سجلات النشاط';
$string['mdf_api:bulkenrol'] = 'تسجيل مستخدمين بالجملة';
$string['mdf_api:sendnotification'] = 'إرسال إشعارات الدفع';

// Settings page.
$string['settings_heading'] = 'إعدادات MDF Academy API';
$string['settings_heading_desc'] = 'ضبط إعدادات إضافة واجهة MDF Academy للجوال.';
$string['enable_push'] = 'تفعيل إشعارات الدفع';
$string['enable_push_desc'] = 'عند التفعيل، سيتم إرسال إشعارات الدفع إلى الأجهزة المحمولة عبر Firebase Cloud Messaging للأحداث الرئيسية (التسجيل، الدرجات، منشورات المنتدى، إلخ).';
$string['fcm_server_key'] = 'مفتاح خادم FCM (قديم)';
$string['fcm_server_key_desc'] = 'مفتاح خادم Firebase Cloud Messaging (القديم، متوقف). يُستخدم فقط إذا لم يتم إعداد FCM V1 أدناه.';

// FCM V1 API settings.
$string['fcm_v1_heading'] = 'FCM V1 API (مُوصى به)';
$string['fcm_v1_heading_desc'] = 'إعداد Firebase Cloud Messaging V1 API باستخدام حساب خدمة. هذه هي الطريقة المُوصى بها لأن API القديم متوقف من قِبل Google.';
$string['fcm_project_id'] = 'معرّف مشروع Firebase';
$string['fcm_project_id_desc'] = 'معرّف مشروع Firebase، يوجد في وحدة تحكم Firebase ← إعدادات المشروع ← عام.';
$string['fcm_service_account_json'] = 'JSON حساب الخدمة';
$string['fcm_service_account_json_desc'] = 'الصق المحتوى الكامل لملف مفتاح JSON لحساب الخدمة. يمكنك إنشاؤه من وحدة تحكم Firebase ← إعدادات المشروع ← حسابات الخدمة ← إنشاء مفتاح خاص جديد.';
$string['fcmauthfailed'] = 'فشل المصادقة مع FCM V1 API. تحقق من بيانات اعتماد حساب الخدمة.';

// Error strings.
$string['fcmkeynotconfigured'] = 'لم يتم إعداد مفتاح خادم FCM. يرجى ضبطه في إعدادات الإضافة.';
$string['notokenfound'] = 'لا يوجد رمز FCM مسجّل لهذا المستخدم.';
$string['usernotfound'] = 'المستخدم غير موجود.';
$string['useralreadyenrolled'] = 'المستخدم مسجّل بالفعل في هذا المقرر.';
$string['enrolpluginnotavailable'] = 'إضافة التسجيل اليدوي غير متاحة.';
$string['invalidjsondata'] = 'حقل البيانات يجب أن يحتوي على JSON صالح.';

// Bulk enrol.
$string['bulkenrol_success'] = 'تم تسجيل المستخدم بنجاح.';
$string['bulkenrol_failed'] = 'فشل تسجيل المستخدم.';

// Push notification templates.
$string['push_enrolled_title'] = 'تسجيل جديد في مقرر';
$string['push_enrolled_body'] = 'تم تسجيلك في: {$a}';

$string['push_completed_title'] = 'تم إكمال المقرر! 🎉';
$string['push_completed_body'] = 'تهانينا! لقد أكملت: {$a}';

$string['push_submitted_title'] = 'تسليم واجب جديد';
$string['push_submitted_body'] = '{$a->student} سلّم واجبًا في {$a->course}';

$string['push_graded_title'] = 'درجة جديدة متاحة';
$string['push_graded_body'] = 'تم نشر درجة جديدة في: {$a}';

$string['push_forum_title'] = 'منشور جديد في المنتدى';
$string['push_forum_body'] = '{$a->author} نشر: {$a->subject}';

// Privacy API.
$string['privacy:metadata:local_mdf_fcm_tokens'] = 'يخزّن رموز Firebase Cloud Messaging لإشعارات الدفع.';
$string['privacy:metadata:local_mdf_fcm_tokens:userid'] = 'معرّف المستخدم.';
$string['privacy:metadata:local_mdf_fcm_tokens:token'] = 'رمز FCM للجهاز.';
$string['privacy:metadata:local_mdf_fcm_tokens:platform'] = 'منصة الجهاز (أندرويد/iOS).';
$string['privacy:metadata:local_mdf_fcm_tokens:devicename'] = 'اسم الجهاز.';

$string['privacy:metadata:local_mdf_push_log'] = 'سجل إشعارات الدفع المرسلة للمستخدمين.';
$string['privacy:metadata:local_mdf_push_log:userid'] = 'معرّف المستخدم المستلم.';
$string['privacy:metadata:local_mdf_push_log:title'] = 'عنوان الإشعار.';
$string['privacy:metadata:local_mdf_push_log:body'] = 'نص الإشعار.';

// ── صلاحيات التلعيب ──
$string['mdf_api:viewgamification'] = 'عرض بيانات التلعيب';
$string['mdf_api:managegamification'] = 'إدارة إعدادات التلعيب';
$string['mdf_api:awardpoints'] = 'منح نقاط التلعيب للمستخدمين';
$string['mdf_api:viewleaderboard'] = 'عرض لوحة المتصدرين';

// ── صلاحيات التعلم الاجتماعي ──
$string['mdf_api:managestudygroups'] = 'إنشاء وإدارة مجموعات الدراسة';
$string['mdf_api:viewstudygroups'] = 'عرض مجموعات الدراسة';
$string['mdf_api:managenotes'] = 'إنشاء وإدارة ملاحظات الدراسة';
$string['mdf_api:viewpeerreviews'] = 'عرض تقييمات الأقران';
$string['mdf_api:submitreview'] = 'تقديم تقييمات الأقران';
$string['mdf_api:managesessions'] = 'إنشاء وإدارة الجلسات التعاونية';

// ── إعدادات التلعيب ──
$string['gamification_heading'] = 'التلعيب';
$string['gamification_heading_desc'] = 'ضبط ميزات التلعيب: النقاط، الشارات، التحديات، ولوحة المتصدرين.';
$string['enable_gamification'] = 'تفعيل التلعيب';
$string['enable_gamification_desc'] = 'عند التفعيل، سيحصل المستخدمون على نقاط ويفتحون شارات ويشاركون في التحديات.';
$string['points_course_enroll'] = 'نقاط التسجيل في المقرر';
$string['points_course_enroll_desc'] = 'النقاط الممنوحة عند تسجيل المستخدم في مقرر.';
$string['points_module_complete'] = 'نقاط إكمال المقرر';
$string['points_module_complete_desc'] = 'النقاط الممنوحة عند إكمال المستخدم لمقرر.';
$string['points_assignment_submit'] = 'نقاط تسليم الواجب';
$string['points_assignment_submit_desc'] = 'النقاط الممنوحة عند تسليم المستخدم لواجب.';
$string['points_forum_post'] = 'نقاط منشور المنتدى';
$string['points_forum_post_desc'] = 'النقاط الممنوحة عند إنشاء المستخدم لمنشور في المنتدى.';
$string['points_daily_login'] = 'نقاط تسجيل الدخول اليومي';
$string['points_daily_login_desc'] = 'النقاط الممنوحة لأول تسجيل دخول يومي.';

// ── إعدادات التعلم الاجتماعي ──
$string['social_heading'] = 'الميزات الاجتماعية';
$string['social_heading_desc'] = 'ضبط ميزات التعلم الاجتماعي: مجموعات الدراسة، الملاحظات المشتركة، تقييم الأقران، والجلسات التعاونية.';
$string['enable_social'] = 'تفعيل الميزات الاجتماعية';
$string['enable_social_desc'] = 'عند التفعيل، يمكن للمستخدمين إنشاء مجموعات دراسة ومشاركة الملاحظات والمشاركة في الجلسات التعاونية.';
$string['max_group_members'] = 'الحد الأقصى لأعضاء المجموعة';
$string['max_group_members_desc'] = 'الحد الأقصى لعدد الأعضاء المسموح بهم في مجموعة دراسة واحدة.';
$string['max_session_participants'] = 'الحد الأقصى للمشاركين في الجلسة';
$string['max_session_participants_desc'] = 'الحد الأقصى لعدد المشاركين المسموح بهم في جلسة تعاونية.';

// ── رسائل الخطأ للتلعيب والتعلم الاجتماعي ──
$string['alreadymember'] = 'أنت عضو بالفعل في هذه المجموعة.';
$string['groupfull'] = 'وصلت مجموعة الدراسة إلى الحد الأقصى من الأعضاء.';
$string['notamember'] = 'أنت لست عضوًا في هذه المجموعة.';
$string['lastadmincantleave'] = 'لا يمكن للمسؤول الأخير مغادرة المجموعة. احذف المجموعة أو رقِّ مسؤولًا آخر أولاً.';
$string['invalidrole'] = 'دور غير صالح. يجب أن يكون مسؤول أو مشرف أو عضو.';
$string['nopermission'] = 'ليس لديك إذن لتنفيذ هذا الإجراء.';
$string['challengenotfound'] = 'لم يتم العثور على تقدم التحدي لهذا المستخدم.';
$string['challengenotcompleted'] = 'لم يتم إكمال هذا التحدي بعد.';
$string['sessionnotactive'] = 'هذه الجلسة لم تعد نشطة.';
$string['sessionfull'] = 'وصلت هذه الجلسة إلى الحد الأقصى من المشاركين.';
$string['notaparticipant'] = 'أنت لست مشاركًا في هذه الجلسة.';
$string['reviewnotfound'] = 'لم يتم العثور على تقييم المراجعة.';

// ── صلاحيات إدارة ظهور الدورات ──
$string['mdf_api:managecoursevisibility'] = 'إدارة إعدادات ظهور الدورات';

// ── صلاحيات إدارة الدفعات ──
$string['mdf_api:managecohorts'] = 'إدارة الدفعات عبر MDF API';

// ── أخطاء ظهور الدورات ──
$string['coursenotfound'] = 'الدورة غير موجودة.';
$string['visibilitynotfound'] = 'إعداد الظهور غير موجود.';
$string['invalidtargettype'] = 'نوع الهدف غير صالح. يجب أن يكون: الكل، مستخدم، أو دفعة.';
$string['cohortnotfound'] = 'الدفعة غير موجودة.';
