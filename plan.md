

  

Read [](file:///c%3A/xampp/htdocs/mdf)

Research Moodle Flutter app

Read [](file:///c%3A/Users/alial/AppData/Roaming/Code/User/workspaceStorage/88dd36da8a4f91b864c6c80b4d2378f0/GitHub.copilot-chat/chat-session-resources/59ff41c7-c128-4aae-b672-abe94abc16ad/toolu_vrtx_01QFkWoCzfHRpRVwbZHhpv4A__vscode-1772142827268/content.txt#1-1), lines 1 to 500

Read [](file:///c%3A/Users/alial/AppData/Roaming/Code/User/workspaceStorage/88dd36da8a4f91b864c6c80b4d2378f0/GitHub.copilot-chat/chat-session-resources/59ff41c7-c128-4aae-b672-abe94abc16ad/toolu_vrtx_01QFkWoCzfHRpRVwbZHhpv4A__vscode-1772142827268/content.txt#500-500), lines 500 to 773

Excellent research completed. Let me clarify a few key decisions before drafting the plan: 

Asked 4 questions (MoodleVer, Languages, Content, Push)

ممتاز! Moodle 5.1.3 يوفر جميع الـ APIs الحديثة. المحتوى سيشمل كل شيء بما في ذلك المنتديات والمحادثات واجتماعات الفيديو المباشرة. دعني أعد الخطة الشاملة.

---

## Plan: Flutter Moodle Educational Platform (MDF)

**ملخص**: بناء تطبيق Flutter متكامل (Android + iOS) كمنصة تعليمية حديثة مبنية على Moodle 5.1.3 REST API. التطبيق يحل محل تطبيق Moodle الرسمي بواجهة جذابة مشابهة لتطبيقات Udemy/Coursera وتطبيقات CodeCanyon التعليمية. يتكون من قسمين: **لوحة إدارة** (إدارة الطلاب، المقررات، الصلاحيات) و**واجهة الطلاب** (عرض المحتوى، الاختبارات، المنتديات، المحادثات، اجتماعات الفيديو). يدعم العربية (RTL) والإنجليزية، وإشعارات Firebase، وتحميل المحتوى للوصول بدون إنترنت.

**الهندسة المعمارية**: Clean Architecture + Feature-First مع Bloc/Cubit لإدارة الحالة، Dio للتواصل مع Moodle REST API، GoRouter للتنقل مع Role-based guards.

---

### Steps

#### المرحلة 0: التجهيز والإعداد

1. **إنشاء مشروع Flutter** في مجلد mdf باستخدام `flutter create --org com.mdf mdf_app` مع تفعيل Android + iOS
2. **إعداد هيكل المشروع** بنمط Clean Architecture:
   - `lib/app/` — إعدادات التطبيق (Router, Theme, DI)
   - `lib/core/` — المكونات المشتركة (API client, Storage, Utils, Widgets)
   - `lib/features/` — الميزات (كل ميزة بمجلد مستقل يحتوي `data/`, `domain/`, `presentation/`)
3. **تثبيت الحزم الأساسية**:
   - **Networking**: `dio`, `connectivity_plus`
   - **State**: `flutter_bloc`, `equatable`
   - **Navigation**: `go_router`
   - **DI**: `get_it`, `injectable`
   - **Storage**: `hive_flutter`, `flutter_secure_storage`, `sqflite`
   - **UI**: `flutter_screenutil`, `shimmer`, `lottie`, `flutter_svg`, `google_fonts`, `cached_network_image`, `percent_indicator`, `fl_chart`
   - **Content**: `flutter_widget_from_html`, `webview_flutter`, `chewie`/`video_player`, `pdfx`
   - **Notifications**: `firebase_messaging`, `flutter_local_notifications`
   - **Localization**: `easy_localization`, `intl`
   - **Models**: `freezed`, `json_serializable`, `build_runner`
   - **Files**: `path_provider`, `file_picker`, `permission_handler`, `open_file`
   - **Other**: `url_launcher`, `share_plus`, `package_info_plus`
4. **إعداد Firebase Project** (Android + iOS) للإشعارات الفورية
5. **إعداد نظام الثيم** — Light/Dark mode مع خطوط عربية (Cairo أو Tajawal) وإنجليزية، ألوان احترافية تعليمية
6. **إعداد الترجمة** — ملفات `ar.json` و `en.json` مع دعم RTL/LTR التلقائي
7. **إعداد Moodle Server**:
   - تفعيل Web Services + REST Protocol
   - إنشاء **External Service مخصص** (`mdf_mobile_service`) يشمل جميع الدوال المطلوبة بما فيها دوال الإدارة
   - إنشاء مستخدم خدمة (service user) مع الصلاحيات اللازمة
   - تثبيت/تفعيل `mod_bigbluebuttonbn` أو Jitsi لاجتماعات الفيديو

---

#### المرحلة 1: الأساسيات (Auth + Dashboard + Profile)

8. **بناء `MoodleApiClient`** في `lib/core/api/` — عميل Dio مع:
   - `AuthInterceptor` — يضيف `wstoken` تلقائياً لكل طلب
   - `ErrorInterceptor` — يحول أخطاء Moodle إلى Exceptions مفهومة
   - `LogInterceptor` — للتطوير
   - ثوابت جميع الـ API functions في `api_endpoints.dart`
   - تحويل `@@PLUGINFILE@@` URLs تلقائياً
9. **ميزة Auth** (`lib/features/auth/`):
   - شاشة تسجيل الدخول — حقل URL السيرفر + اسم المستخدم + كلمة المرور + زر SSO
   - استدعاء `login/token.php` ثم `core_webservice_get_site_info` لجلب بيانات المستخدم ودوره
   - تخزين Token في `flutter_secure_storage`
   - `AuthBloc` يدير حالات (Unauthenticated → Authenticating → Authenticated(user, role))
   - كشف الدور: `userissiteadmin` للمدير + `core_user_get_users_by_field` للتفاصيل
10. **إعداد GoRouter** مع Role-based routing:
    - `/login` — شاشة الدخول
    - `/student/*` — شاشات الطالب (ShellRoute بـ BottomNavigationBar)
    - `/admin/*` — شاشات المدير (ShellRoute بـ Drawer/BottomNav مختلف)
    - Guards تمنع الطالب من الوصول لصفحات الإدارة
11. **لوحة تحكم الطالب** (`lib/features/student_dashboard/`):
    - بانر ترحيبي مع اسم الطالب وصورته
    - قسم "أكمل التعلم" — آخر المقررات التي تم الوصول إليها (`core_course_get_recent_courses`)
    - كروت إحصائيات (مقررات مسجلة، اختبارات قادمة، رسائل جديدة)
    - قسم "المقررات الموصى بها" (carousel أفقي)
    - قسم "الأحداث القادمة" من التقويم
12. **لوحة تحكم المدير** (`lib/features/admin_dashboard/`):
    - كروت إحصائيات (عدد الطلاب، المقررات، التسجيلات النشطة، الاختبارات)
    - رسم بياني (fl_chart) للنشاط الأخير
    - قائمة النشاطات الأخيرة
    - روابط سريعة لأهم العمليات الإدارية
13. **الملف الشخصي** (`lib/features/profile/`):
    - عرض/تعديل بيانات المستخدم (`core_user_get_users_by_field` + `core_user_update_users`)
    - تغيير الصورة (`core_user_update_picture`)
    - إعدادات التطبيق (اللغة، الوضع الليلي، حجم الخط)

---

#### المرحلة 2: المقررات والمحتوى

14. **قائمة المقررات** (`lib/features/courses/`):
    - **للطالب**: مقرراتي (`enrol_get_users_courses`) + استعراض المقررات المتاحة (`core_course_search_courses`)
    - **للمدير**: جميع المقررات (`core_course_get_courses`) مع أزرار التعديل والحذف
    - عرض Grid/List مع Toggle
    - بطاقة المقرر: صورة + عنوان + مدرس + نسبة التقدم + تقييم
    - فلترة بالتصنيف (`core_course_get_categories`)
    - بحث
15. **تفاصيل المقرر** (`lib/features/course_detail/`):
    - Hero image/video في الأعلى
    - Tabs: نظرة عامة | المنهج | المدرس | التقييمات
    - زر "سجل الآن" (`enrol_self_enrol_user`) أو "أكمل التعلم"
    - شريط التقدم الكلي
16. **محتوى المقرر** (`lib/features/course_content/`):
    - جلب المحتوى عبر `core_course_get_contents` (sections + modules)
    - عرض الأقسام كـ expandable tiles
    - كل عنصر يحمل أيقونة حسب نوعه + حالة الإكمال (checkmark)
    - النقر يفتح العارض المناسب حسب نوع المحتوى
17. **عارض المحتوى** (`lib/features/content_viewer/`):
    - **فيديو**: `chewie` player مع دعم mp4 المباشر + استخراج YouTube/Vimeo من HTML
    - **PDF**: `pdfx` viewer مع تكبير/تصغير وقائمة الصفحات
    - **HTML/نصوص**: `flutter_widget_from_html` مع تحويل `PLUGINFILE` URLs
    - **SCORM**: `webview_flutter` يحمل `mod/scorm/player.php` مع حقن Token
    - **H5P**: `webview_flutter` يحمل H5P player URL مع authentication
    - **كتاب (Book)**: جلب الفصول عبر `mod_book_get_books_by_courses` وعرضها كصفحات متتابعة
    - **درس (Lesson)**: تدفق متعدد الصفحات عبر `mod_lesson_get_pages`
    - شريط تنقل (السابق/التالي) بين عناصر المقرر
    - تحديث حالة الإكمال (`core_completion_update_activity_completion_status_manually`)
18. **إدارة المقررات — المدير** (`lib/features/admin_courses/`):
    - إنشاء مقرر جديد (`core_course_create_courses`)
    - تعديل إعدادات المقرر (`core_course_update_courses`)
    - إدارة التصنيفات (`core_course_get_categories`)
    - تبديل إمكانية الرؤية
    - **ملاحظة**: إضافة/تعديل الأنشطة داخل المقرر سيحتاج WebView لواجهة Moodle الويب بسبب محدودية الـ API في إنشاء المحتوى

---

#### المرحلة 3: الاختبارات والواجبات والدرجات

19. **الاختبارات** (`lib/features/quiz/`):
    - **شاشة معلومات الاختبار**: القواعد، المدة الزمنية، عدد المحاولات، الدرجة المطلوبة
    - **بدء المحاولة**: `mod_quiz_start_attempt` → `QuizAttemptBloc`
    - **شاشة الأسئلة**: عرض سؤال/صفحة واحدة في كل مرة
      - أنواع الأسئلة الأصلية (Flutter widgets): اختيار متعدد، صح/خطأ، إجابة قصيرة، مقالي، مطابقة، رقمي
      - أنواع معقدة (سحب وإفلات، cloze): WebView fallback
    - **مؤقت العد التنازلي** مع تحذيرات
    - **حفظ تلقائي** كل 30 ثانية (`mod_quiz_save_attempt`)
    - **تنقل بين الأسئلة** مع مؤشر حالة الإجابة
    - **إرسال نهائي** (`mod_quiz_submit_attempt`) مع تأكيد
    - **مراجعة المحاولة** (`mod_quiz_get_attempt_review`) — عرض الإجابات الصحيحة والخاطئة
    - **سجل المحاولات** (`mod_quiz_get_user_attempts`)
20. **الواجبات** (`lib/features/assignments/`):
    - **للطالب**: عرض التعليمات + رفع الملفات (`webservice/upload.php`) + إرسال (`mod_assign_submit_for_grading`)
    - **للمدير/المعلم**: قائمة التسليمات (`mod_assign_get_submissions`) + التقييم (`mod_assign_save_grade`)
    - دعم النص المكتوب + رفع ملفات متعددة
21. **الدرجات** (`lib/features/grades/`):
    - **للطالب**: دفتر الدرجات (`gradereport_user_get_grade_items`) — عرض كل مقرر مع تفاصيل الدرجات
    - **للمدير**: نظرة عامة (`gradereport_overview_get_course_grades`) + تقرير تفصيلي لكل مقرر

---

#### المرحلة 4: إدارة المستخدمين والتسجيل (Admin)

22. **إدارة المستخدمين** (`lib/features/users/`):
    - قائمة المستخدمين مع بحث وفلترة (`core_user_get_users`)
    - إنشاء مستخدم (`core_user_create_users`) — نموذج شامل
    - تعديل بيانات المستخدم (`core_user_update_users`)
    - حذف مستخدم (`core_user_delete_users`) مع تأكيد
    - عرض تفاصيل المستخدم ومقرراته ونشاطه
    - عمليات جماعية (Bulk actions)
23. **إدارة التسجيل** (`lib/features/enrollment/`):
    - تسجيل طلاب في مقرر (`enrol_manual_enrol_users`) — اختيار فردي أو جماعي
    - إلغاء تسجيل (`enrol_manual_unenrol_users`)
    - عرض المسجلين في مقرر (`enrol_get_enrolled_users`)
    - إسناد الأدوار (طالب/معلم/مدير)
24. **إدارة الصلاحيات** (`lib/features/roles/`):
    - عرض الأدوار المتاحة
    - إسناد/إزالة أدوار من المستخدمين عبر `core_role_assign_roles` / `core_role_unassign_roles`

---

#### المرحلة 5: التواصل والمنتديات والاجتماعات

25. **المراسلات** (`lib/features/messaging/`):
    - قائمة المحادثات (`core_message_get_conversations`)
    - شاشة الدردشة (`core_message_get_conversation_messages` + `core_message_send_instant_messages`)
    - واجهة مشابهة لـ WhatsApp/Telegram — فقاعات رسائل + إدخال نص
    - عدد الرسائل غير المقروءة في Badge على Tab
    - بحث في المحادثات
26. **المنتديات** (`lib/features/forums/`):
    - قائمة المنتديات في كل مقرر (`mod_forum_get_forums_by_courses`)
    - المناقشات (`mod_forum_get_forum_discussions`) — عرض كبطاقات
    - المشاركات في المناقشة (`mod_forum_get_discussion_posts`) — عرض شجري
    - إضافة مناقشة جديدة (`mod_forum_add_discussion`)
    - الرد على مناقشة (`mod_forum_add_discussion_post`)
27. **اجتماعات الفيديو المباشرة** (`lib/features/video_meetings/`):
    - جلب اجتماعات BigBlueButton عبر `mod_bigbluebuttonbn_get_bigbluebuttonbns_by_courses`
    - عرض الاجتماعات القادمة والنشطة
    - الانضمام عبر `mod_bigbluebuttonbn_meeting_info` + فتح رابط الاجتماع في WebView أو المتصفح
    - **بديل**: إذا كان Jitsi مستخدماً، استخدام `jitsi_meet_flutter_sdk` للانضمام مباشرة من التطبيق
    - عرض تسجيلات الاجتماعات السابقة

---

#### المرحلة 6: الإشعارات والتقويم والبحث

28. **الإشعارات** (`lib/features/notifications/`):
    - إعداد Firebase Messaging (Android + iOS)
    - بناء **Moodle Plugin مخصص** (`local_mdf_push`) يربط أحداث Moodle بـ FCM:
      - درجة جديدة → إشعار
      - رسالة جديدة → إشعار
      - موعد اختبار → إشعار
      - إعلان جديد → إشعار
    - تسجيل FCM Token عبر web service مخصص
    - شاشة الإشعارات (`message_popup_get_popup_notifications`)
    - Badge عدد غير مقروءة
29. **التقويم** (`lib/features/calendar/`):
    - عرض شهري (`core_calendar_get_calendar_monthly_view`)
    - الأحداث القادمة (`core_calendar_get_calendar_upcoming_view`)
    - ألوان مختلفة حسب النوع (اختبار، واجب، حدث، اجتماع)
30. **البحث الشامل** (`lib/features/search/`):
    - بحث في المقررات (`core_course_search_courses`)
    - بحث في المستخدمين (Admin) (`core_user_get_users`)
    - سجل البحث المحلي
    - اقتراحات بحث

---

#### المرحلة 7: الوصول بدون إنترنت والتحميل

31. **مدير التحميلات** (`lib/features/downloads/`):
    - تحميل مقرر كامل أو أقسام محددة
    - تتبع التقدم بشريط تحميل لكل ملف
    - تخزين في `getApplicationDocumentsDirectory()` + تسجيل في SQLite
    - عرض المحتوى المحمّل بدون إنترنت
    - حذف المحتوى المحمّل مع عرض المساحة المستخدمة
    - **صف الإجراءات المؤجلة** (Offline Actions Queue): حفظ إجابات الاختبار ومشاركات المنتدى ومزامنتها عند الاتصال

---

#### المرحلة 8: Moodle Plugin المخصص

32. **بناء `local_mdf_api` plugin** على سيرفر Moodle:
    - إنشاء External Service مخصص يشمل جميع الدوال المطلوبة
    - إضافة Web Service functions مفقودة:
      - `local_mdf_get_dashboard_stats` — إحصائيات لوحة تحكم المدير
      - `local_mdf_register_device` — تسجيل FCM token
      - `local_mdf_send_push` — إرسال إشعارات عبر FCM
      - `local_mdf_get_admin_reports` — تقارير مخصصة
    - ربط أحداث Moodle (Events API) بإرسال Push عبر Firebase Admin SDK

---

#### المرحلة 9: التحسين والتلميع

33. **Splash Screen + Onboarding** — شاشات تعريفية عند أول استخدام مع Lottie animations
34. **نظام التخزين المؤقت** — Cache-first strategy لتسريع التحميل
35. **Error Handling شامل** — شاشات خطأ جذابة مع إعادة المحاولة
36. **Skeleton Loading** — Shimmer effect أثناء التحميل بدل spinner
37. **تجاوب التصميم** — دعم أحجام شاشات مختلفة (هواتف + تابلت)
38. **اختبار شامل** — Unit tests لـ Blocs و Repositories + Widget tests للشاشات الرئيسية
39. **تحسين الأداء** — Lazy loading, pagination, image optimization

---

### Verification

- **اختبار API**: استخدام Postman للتحقق من جميع Moodle API endpoints قبل التنفيذ
- **اختبار الأدوار**: تسجيل دخول بحساب مدير وحساب طالب والتأكد من ظهور الواجهة المناسبة لكل دور
- **اختبار المحتوى**: التأكد من عرض كل نوع محتوى (فيديو، PDF، SCORM، H5P، HTML) بشكل صحيح
- **اختبار الاختبارات**: تنفيذ اختبار كامل (بدء → إجابة → إرسال → مراجعة)
- **اختبار RTL**: التأكد من عرض الواجهة العربية بشكل صحيح (الاتجاه، الخطوط، التنسيق)
- **اختبار Offline**: تحميل مقرر → قطع الإنترنت → التأكد من إمكانية التصفح
- **اختبار Push**: إرسال إشعار من Moodle والتأكد من وصوله للتطبيق
- تشغيل `flutter test` و `flutter analyze` بشكل دوري
- اختبار على أجهزة Android + iOS فعلية

### Decisions

- **State Management**: Bloc/Cubit — الأنسب لتطبيق بهذا الحجم والتعقيد (اختبارات، أدوار، حالات معقدة) بدلاً من GetX أو Riverpod
- **Architecture**: Clean Architecture + Feature-First — يفصل بوضوح بين الطبقات ويسهل الصيانة والتوسع
- **SCORM/H5P**: WebView — لا يوجد بديل لعرضها أصلياً في Flutter
- **Push Notifications**: Firebase مع Moodle Plugin مخصص — أكثر موثوقية من Airnotifier
- **Content Creation (Admin)**: بعض عمليات إنشاء المحتوى ستفتح WebView لواجهة Moodle الويب بسبب محدودية الـ API — هذا أفضل من بناء محرر محتوى كامل
- **Video Meetings**: WebView/Browser launch لـ BigBlueButton — لأن BBB يحتاج بيئة متصفح كاملة
- **Moodle External Service مخصص**: ضروري لأن خدمة `moodle_mobile_app` الافتراضية لا تشمل دوال الإدارة
- **ترتيب التطوير مرحلي**: يسمح بنسخة عاملة مبكرة (MVP بعد المرحلة 2-3) مع إضافة ميزات تدريجياً