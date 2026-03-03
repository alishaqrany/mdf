<div dir="rtl">

# 📱 MDF — منصة تعليمية متكاملة مبنية على Moodle

<p align="center">
  <strong>تطبيق موبايل احترافي (Android + iOS) يُحوّل نظام Moodle التعليمي إلى تجربة حديثة وجذابة</strong>
</p>

<p align="center">
  Flutter 3.41+ &nbsp;|&nbsp; Dart 3.11+ &nbsp;|&nbsp; Moodle 5.1+ &nbsp;|&nbsp; عربي + English
</p>

<p align="center">
  <img src="https://img.shields.io/badge/tests-389%20passing-brightgreen" alt="Tests">
  <img src="https://img.shields.io/badge/coverage-40%25%2B-yellow" alt="Coverage">
  <img src="https://img.shields.io/badge/features-25-blue" alt="Features">
  <img src="https://img.shields.io/badge/files-265-blue" alt="Files">
  <img src="https://img.shields.io/badge/LOC-39K%2B-blue" alt="LOC">
  <img src="https://img.shields.io/badge/APK-built%20✓-brightgreen" alt="APK">
  <img src="https://img.shields.io/badge/version-1.0.0-green" alt="Version">
</p>

---

## 📋 جدول المحتويات

- [نظرة عامة](#-نظرة-عامة)
- [المميزات](#-المميزات)
- [المعمارية](#-المعمارية)
- [المتطلبات](#-المتطلبات)
- [التثبيت والإعداد](#-التثبيت-والإعداد)
- [التشغيل](#-التشغيل)
- [هيكل المشروع](#-هيكل-المشروع)
- [التقنيات المستخدمة](#-التقنيات-المستخدمة)
- [إعداد Moodle](#-إعداد-moodle)
- [المساهمة](#-المساهمة)
- [الترخيص](#-الترخيص)

---

## 🌟 نظرة عامة

**MDF** هو تطبيق موبايل حديث يهدف لاستبدال تطبيق Moodle الرسمي بتجربة مستخدم أفضل وأكثر جاذبية، مستوحاة من منصات مثل **Udemy** و **Coursera**. يدعم التطبيق قسمين رئيسيين:

| القسم | الوصف |
|-------|-------|
| 🎓 **قسم الطالب** | تصفح المقررات، مشاهدة المحتوى، حل الاختبارات، تتبع التقدم |
| 🔧 **قسم الإدارة** | إدارة المستخدمين والمقررات والتسجيلات والتقارير |

### لماذا MDF؟
- ❌ تطبيق Moodle الرسمي: واجهة قديمة، UX ضعيف، صلاحيات إدارية محدودة
- ✅ MDF: واجهة حديثة، رسوم متحركة، دعم RTL كامل، لوحة إدارة متكاملة

---

## ✨ المميزات

### المميزات المُنجزة ✅

#### البنية التحتية
- [x] معمارية نظيفة (Clean Architecture) + نمط Feature-First
- [x] إدارة الحالة بـ Bloc/Cubit
- [x] حقن التبعيات (GetIt)
- [x] التوجيه الذكي (GoRouter) مع حراسة المسارات حسب الصلاحيات
- [x] عميل API متكامل لـ Moodle REST مع 70+ نقطة نهاية
- [x] معالجة أخطاء شاملة (Either pattern مع dartz)
- [x] نظام ثيمات كامل (فاتح/داكن) مع دعم RTL
- [x] ترجمة ثنائية اللغة (عربي + إنجليزي) — 307 مفتاح ترجمة

#### المميزات الوظيفية
- [x] 🔐 **المصادقة** — تسجيل دخول، تسجيل خروج، فحص الجلسة، تخزين آمن
- [x] 📊 **لوحة الطالب** — إحصائيات، متابعة التعلم، المقررات الأخيرة
- [x] 🛠 **لوحة الإدارة** — إحصائيات النظام، رسوم بيانية، إجراءات سريعة
- [x] 📚 **المقررات** — عرض شبكي/قائمة، بحث، تصفية، تقدم بصري
- [x] 📄 **محتوى المقرر** — أقسام قابلة للطي، أيقونات حسب النوع، علامات الإنجاز
- [x] 👤 **الملف الشخصي** — معلومات المستخدم، الإعدادات، تسجيل الخروج

#### الميزات المتقدمة ✅
- [x] 📖 **عارض المحتوى** — فيديو (Chewie)، PDF، SCORM، H5P، WebView
- [x] ❓ **الاختبارات** — محاولات، مؤقت، مراجعة، أنواع أسئلة متعددة
- [x] 📝 **الواجبات** — تسليم، تقييم، ملاحظات
- [x] 📈 **دفتر الدرجات** — عرض الدرجات والتقارير
- [x] 👥 **إدارة المستخدمين** — إنشاء/تعديل/حذف، صلاحيات
- [x] 📩 **الرسائل والمنتديات** — محادثات فردية وجماعية
- [x] 🎥 **المؤتمرات المرئية** — تكامل BigBlueButton
- [x] 🔔 **الإشعارات** — Firebase Cloud Messaging
- [x] 📅 **التقويم** — أحداث، مهام، مواعيد
- [x] 📥 **التنزيلات** — عمل بدون اتصال، مزامنة تلقائية
- [x] 🔍 **البحث الشامل** — بحث عبر المحتوى

#### ميزات V2.0+ ✅
- [x] 🤖 **الذكاء الاصطناعي** — AI Chat، AI Insights
- [x] 👫 **التعلم الاجتماعي** — مجموعات دراسة، ملاحظات، مراجعة أقران
- [x] 🎮 **التلعيب** — نقاط، شارات، لوحة متصدرين، تحديات
- [x] 🌐 **منصات متعددة** — Android، iOS، Web، Windows

#### الجودة والأمان ✅
- [x] 🧪 **389 اختبار** — BLoC، Model، Widget، Security، Integration
- [x] 🔒 **أمان متقدم** — HTTPS إجباري، تنظيف XSS، إخفاء التوكن
- [x] ⚡ **أداء محسّن** — CachedNetworkImage، const constructors، lint rules
- [x] 🔄 **CI/CD** — GitHub Actions (6 وظائف: test, security, android, aab, web, windows)

---

## 🏗 المعمارية

```
┌──────────────────────────────────────────────┐
│                Presentation                   │
│  (Pages, Widgets, Bloc/Cubit)                │
├──────────────────────────────────────────────┤
│                  Domain                       │
│  (Entities, Repositories Interface, UseCases)│
├──────────────────────────────────────────────┤
│                   Data                        │
│  (Models, DataSources, Repositories Impl)    │
├──────────────────────────────────────────────┤
│                   Core                        │
│  (API Client, Error Handling, Utils, Theme)   │
└──────────────────────────────────────────────┘
```

**نمط التصميم:** Clean Architecture + Feature-First

```
lib/features/{feature_name}/
├── data/
│   ├── datasources/     ← مصادر البيانات (API، Cache)
│   ├── models/          ← نماذج البيانات (JSON ↔ Dart)
│   └── repositories/    ← تنفيذ المستودعات
├── domain/
│   ├── entities/        ← كيانات الأعمال النقية
│   ├── repositories/    ← واجهات المستودعات (Abstract)
│   └── usecases/        ← حالات الاستخدام
└── presentation/
    ├── bloc/            ← إدارة الحالة
    └── pages/           ← صفحات الواجهة
```

---

## ⚙️ المتطلبات

| المتطلب | الحد الأدنى | الموصى به |
|---------|-----------|----------|
| Flutter | 3.41.0 | أحدث إصدار مستقر |
| Dart | 3.11.0 | أحدث إصدار |
| Android SDK | API 21 (5.0) | API 34 (14) |
| iOS | 12.0 | 17.0+ |
| Moodle | 4.0 | 5.1+ |
| Node.js | - | لأدوات Firebase فقط |

---

## 🚀 التثبيت والإعداد

### 1. استنساخ المشروع
```bash
git clone https://github.com/your-org/mdf.git
cd mdf
```

### 2. تثبيت التبعيات
```bash
flutter pub get
```

### 3. إعداد Moodle
انظر ملف [docs/SETUP.md](docs/SETUP.md) للتعليمات التفصيلية.

**خطوات سريعة:**
1. فعّل **Web Services** في إعدادات Moodle
2. فعّل بروتوكول **REST**
3. أنشئ خدمة خارجية مخصصة باسم `mdf_mobile_service`
4. أضف الدوال المطلوبة للخدمة
5. أنشئ توكن للمستخدم

### 4. تكوين الاتصال
عنوان السيرفر يُدخل في صفحة تسجيل الدخول مباشرة.

### 5. إعداد Firebase (اختياري - للإشعارات)
```bash
npm install -g firebase-tools
firebase login
flutterfire configure
```

---

## ▶️ التشغيل

```bash
# تشغيل بوضع التطوير
flutter run

# تشغيل على Android
flutter run -d android

# تشغيل على iOS
flutter run -d ios

# بناء APK للإنتاج
flutter build apk --release

# بناء App Bundle
flutter build appbundle --release

# بناء iOS
flutter build ios --release
```

---

## 📁 هيكل المشروع

```
mdf/
├── 📁 android/              ← إعدادات Android الأصلية
├── 📁 ios/                  ← إعدادات iOS الأصلية
├── 📁 assets/
│   ├── 📁 animations/      ← ملفات Lottie
│   ├── 📁 icons/           ← أيقونات مخصصة
│   ├── 📁 images/          ← صور التطبيق
│   └── 📁 translations/    ← ملفات الترجمة (ar.json, en.json)
├── 📁 docs/                 ← التوثيق
│   ├── SETUP.md            ← دليل الإعداد التفصيلي
│   ├── ARCHITECTURE.md     ← توثيق المعمارية
│   ├── BLUEPRINT.md        ← المخطط الشامل
│   ├── ROADMAP.md          ← خطة التطوير
│   └── IMPROVEMENT_REPORT.md ← تقرير التحسينات الشامل
├── 📁 lib/
│   ├── main.dart           ← نقطة الدخول
│   ├── 📁 app/
│   │   ├── app.dart        ← MaterialApp الرئيسي
│   │   ├── 📁 di/          ← حقن التبعيات (GetIt)
│   │   ├── 📁 router/      ← التوجيه (GoRouter)
│   │   └── 📁 theme/       ← الألوان والخطوط والثيمات
│   ├── 📁 core/
│   │   ├── 📁 api/         ← عميل Moodle API + Interceptors
│   │   ├── 📁 constants/   ← الثوابت العامة
│   │   ├── 📁 error/       ← الاستثناءات والأخطاء
│   │   ├── 📁 network/     ← فحص الاتصال
│   │   ├── 📁 utils/       ← أدوات مساعدة
│   │   └── 📁 widgets/     ← ودجات مشتركة
│   └── 📁 features/
│       ├── 📁 auth/            ← المصادقة
│       ├── 📁 student_dashboard/ ← لوحة الطالب
│       ├── 📁 admin_dashboard/  ← لوحة الإدارة
│       ├── 📁 courses/         ← المقررات
│       ├── 📁 course_content/  ← محتوى المقرر
│       ├── 📁 profile/        ← الملف الشخصي
│       ├── 📁 grades/         ← الدرجات
│       ├── 📁 notifications/  ← الإشعارات
│       ├── 📁 calendar/       ← التقويم
│       ├── 📁 search/         ← البحث
│       ├── 📁 messaging/      ← المراسلة
│       ├── 📁 downloads/      ← التنزيلات
│       ├── 📁 ai/             ← الذكاء الاصطناعي
│       ├── 📁 social/         ← التعلم الاجتماعي
│       ├── 📁 gamification/   ← التلعيب
│       └── ... (25 ميزة إجمالاً)
├── 📁 test/                 ← 36 ملف اختبار (389 اختبار)
├── 📁 integration_test/     ← اختبارات التكامل (2 ملف)
├── 📁 .github/workflows/   ← CI/CD (6 وظائف بناء)
├── pubspec.yaml            ← التبعيات
└── analysis_options.yaml   ← قواعد التحليل
```

---

## 🔧 التقنيات المستخدمة

| الفئة | التقنية | الوصف |
|-------|---------|-------|
| **Framework** | Flutter 3.41+ | إطار عمل تطوير متعدد المنصات |
| **اللغة** | Dart 3.11+ | لغة البرمجة |
| **الحالة** | flutter_bloc 8.1.6 | إدارة الحالة بنمط Bloc |
| **التوجيه** | GoRouter 14.6+ | توجيه تصريحي مع حراسة المسارات |
| **DI** | GetIt 8.0+ | حقن التبعيات |
| **الشبكة** | Dio 5.7+ | عميل HTTP المتقدم |
| **التخزين** | Hive + SecureStorage | تخزين محلي آمن |
| **الترجمة** | easy_localization | دعم RTL + ثنائي اللغة |
| **الرسوم** | fl_chart | رسوم بيانية تفاعلية |
| **الإشعارات** | Firebase Cloud Messaging | إشعارات فورية |
| **المحتوى** | WebView + Chewie | عرض محتوى متنوع |
| **الأخطاء** | dartz (Either) | معالجة وظيفية للأخطاء |

---

## 🔌 إعداد Moodle

التطبيق يتصل بـ Moodle عبر **REST Web Services API**. يتطلب الإعداد التالي:

### الدوال المطلوبة (Web Service Functions)

<details>
<summary>📋 قائمة الدوال (اضغط للتوسيع)</summary>

#### المصادقة والمستخدمين
- `core_webservice_get_site_info`
- `core_user_get_users`
- `core_user_get_users_by_field`
- `core_user_create_users`
- `core_user_update_users`
- `core_user_delete_users`

#### المقررات
- `core_course_get_courses`
- `core_course_get_enrolled_courses_by_timeline_classification`
- `core_course_get_recent_courses`
- `core_course_search_courses`
- `core_course_get_contents`
- `core_enrol_get_enrolled_users`
- `enrol_manual_enrol_users`
- `enrol_manual_unenrol_users`
- `core_course_get_categories`

#### الاختبارات والواجبات
- `mod_quiz_get_quizzes_by_courses`
- `mod_quiz_get_attempt_data`
- `mod_quiz_start_attempt`
- `mod_quiz_process_attempt`
- `mod_assign_get_assignments`
- `mod_assign_get_submission_status`
- `mod_assign_save_submission`

#### الدرجات والمراسلة
- `gradereport_user_get_grade_items`
- `core_message_get_conversations`
- `core_message_send_instant_messages`
- `core_calendar_get_calendar_events`

</details>

---

## 🤝 المساهمة

1. Fork المشروع
2. أنشئ فرع للميزة: `git checkout -b feature/my-feature`
3. نفذ التغييرات: `git commit -m 'إضافة ميزة جديدة'`
4. ادفع الفرع: `git push origin feature/my-feature`
5. أنشئ Pull Request

### قواعد الكود
- استخدم Clean Architecture لكل ميزة جديدة
- أضف ترجمات عربية وإنجليزية
- اكتب اختبارات وحدة
- اتبع Dart style guide

---

## 📄 الترخيص

هذا المشروع خاص ومحمي بحقوق الملكية. جميع الحقوق محفوظة.

---

## 📚 التوثيق الإضافي

| المستند | الوصف |
|---------|-------|
| [docs/SETUP.md](docs/SETUP.md) | دليل الإعداد التفصيلي خطوة بخطوة |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | توثيق المعمارية والأنماط |
| [docs/BLUEPRINT.md](docs/BLUEPRINT.md) | المخطط الشامل للمشروع |
| [docs/ROADMAP.md](docs/ROADMAP.md) | خطة التطوير والتحديث |
| [docs/IMPROVEMENT_REPORT.md](docs/IMPROVEMENT_REPORT.md) | تقرير التحسينات الشامل |

</div>
