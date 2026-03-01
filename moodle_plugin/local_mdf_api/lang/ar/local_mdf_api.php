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
$string['fcm_server_key'] = 'مفتاح خادم FCM';
$string['fcm_server_key_desc'] = 'مفتاح خادم Firebase Cloud Messaging (القديم) من وحدة تحكم مشروع Firebase. يوجد ضمن إعدادات المشروع ← المراسلة السحابية ← مفتاح الخادم.';

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
