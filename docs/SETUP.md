<div dir="rtl">

# 🛠 دليل الإعداد التفصيلي — MDF

هذا الدليل يشرح خطوة بخطوة كيفية إعداد بيئة التطوير وتكوين سيرفر Moodle وتشغيل التطبيق.

---

## 📋 جدول المحتويات

1. [متطلبات النظام](#1--متطلبات-النظام)
2. [إعداد بيئة Flutter](#2--إعداد-بيئة-flutter)
3. [إعداد المشروع](#3--إعداد-المشروع)
4. [تكوين سيرفر Moodle](#4--تكوين-سيرفر-moodle)
5. [إعداد Firebase](#5--إعداد-firebase)
6. [بناء التطبيق للإنتاج](#6--بناء-التطبيق-للإنتاج)
7. [استكشاف الأخطاء](#7--استكشاف-الأخطاء)

---

## 1. 💻 متطلبات النظام

### لتطوير Android
| المتطلب | التفاصيل |
|---------|----------|
| نظام التشغيل | Windows 10/11, macOS, Linux |
| Flutter SDK | 3.38.0 أو أحدث |
| Android Studio | أحدث إصدار مستقر |
| Android SDK | API Level 21+ (الهدف: 34) |
| Java JDK | 17 |
| ذاكرة RAM | 8 GB كحد أدنى |

### لتطوير iOS (macOS فقط)
| المتطلب | التفاصيل |
|---------|----------|
| macOS | Ventura 13.0+ أو أحدث |
| Xcode | 15.0+ |
| CocoaPods | أحدث إصدار |

### سيرفر Moodle
| المتطلب | التفاصيل |
|---------|----------|
| Moodle | 4.0+ (الموصى: 5.1+) |
| PHP | 8.1+ |
| قاعدة البيانات | MySQL 8.0+ / MariaDB 10.6+ / PostgreSQL 14+ |
| SSL | شهادة HTTPS صالحة (موصى بها للإنتاج) |

---

## 2. 🔧 إعداد بيئة Flutter

### تثبيت Flutter SDK

#### Windows
```powershell
# باستخدام Chocolatey
choco install flutter

# أو التحميل اليدوي
# 1. حمّل Flutter SDK من https://docs.flutter.dev/get-started/install/windows
# 2. فك الضغط في مسار مثل C:\flutter
# 3. أضف C:\flutter\bin إلى متغير PATH
```

#### macOS
```bash
# باستخدام Homebrew
brew install flutter

# أو
git clone https://github.com/flutter/flutter.git ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
```

#### Linux
```bash
sudo snap install flutter --classic
# أو
git clone https://github.com/flutter/flutter.git ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
```

### التحقق من التثبيت
```bash
flutter doctor -v
```

تأكد من ظهور ✓ بجانب:
- Flutter
- Android toolchain
- Xcode (macOS فقط)
- Android Studio أو VS Code

---

## 3. 📦 إعداد المشروع

### الخطوة 1: استنساخ المشروع
```bash
git clone https://github.com/your-org/mdf.git
cd mdf
```

### الخطوة 2: تثبيت التبعيات
```bash
flutter pub get
```

### الخطوة 3: إنشاء ملفات الأصول (إذا لم تكن موجودة)
```bash
# تأكد من وجود مجلدات الأصول
mkdir -p assets/animations assets/icons assets/images assets/translations
```

### الخطوة 4: التأكد من صحة الكود
```bash
dart analyze
```

### الخطوة 5: التشغيل
```bash
# قائمة الأجهزة المتاحة
flutter devices

# تشغيل على جهاز محدد
flutter run -d <device_id>
```

---

## 4. 🌐 تكوين سيرفر Moodle

### 4.1 تفعيل Web Services

1. سجّل دخول كمدير (Admin) في Moodle
2. اذهب إلى: **Site administration → Advanced features**
3. فعّل ✅ **Enable web services**
4. اضغط **Save changes**

### 4.2 تفعيل بروتوكول REST

1. اذهب إلى: **Site administration → Plugins → Web services → Manage protocols**
2. فعّل 👁 **REST protocol** (اضغط أيقونة العين)

### 4.3 إنشاء خدمة خارجية مخصصة

1. اذهب إلى: **Site administration → Plugins → Web services → External services**
2. اضغط **Add**
3. املأ البيانات:
   - **Name:** `mdf_mobile_service`
   - **Short name:** `mdf_mobile_service`
   - **Enabled:** ✅
   - **Authorised users only:** حسب الحاجة
4. اضغط **Add service**

### 4.4 إضافة الدوال للخدمة

بعد إنشاء الخدمة، اضغط **Functions** وأضف الدوال التالية:

#### دوال أساسية (مطلوبة)
```
core_webservice_get_site_info
core_user_get_users_by_field
```

#### دوال المقررات
```
core_course_get_courses
core_course_get_enrolled_courses_by_timeline_classification
core_course_get_recent_courses
core_course_search_courses
core_course_get_contents
core_course_get_categories
core_course_create_courses
core_course_update_courses
core_course_delete_courses
core_course_duplicate_course
```

#### دوال التسجيل
```
core_enrol_get_enrolled_users
core_enrol_get_users_courses
enrol_manual_enrol_users
enrol_manual_unenrol_users
```

#### دوال المستخدمين (للمدير)
```
core_user_get_users
core_user_create_users
core_user_update_users
core_user_delete_users
```

#### دوال الاختبارات
```
mod_quiz_get_quizzes_by_courses
mod_quiz_get_user_attempts
mod_quiz_get_attempt_data
mod_quiz_get_attempt_summary
mod_quiz_get_attempt_review
mod_quiz_start_attempt
mod_quiz_process_attempt
mod_quiz_save_attempt
mod_quiz_get_quiz_access_information
```

#### دوال الواجبات
```
mod_assign_get_assignments
mod_assign_get_submission_status
mod_assign_save_submission
mod_assign_submit_for_grading
mod_assign_save_grade
mod_assign_get_grades
```

#### دوال الدرجات
```
gradereport_user_get_grade_items
gradereport_overview_get_course_grades
```

#### دوال المراسلة
```
core_message_get_conversations
core_message_get_messages
core_message_send_instant_messages
core_message_get_unread_conversations_count
```

#### دوال المنتديات
```
mod_forum_get_forums_by_courses
mod_forum_get_forum_discussions
mod_forum_get_discussion_posts
mod_forum_add_discussion
mod_forum_add_discussion_post
```

#### دوال التقويم
```
core_calendar_get_calendar_events
core_calendar_get_calendar_monthly_view
core_calendar_create_calendar_events
core_calendar_delete_calendar_events
```

#### دوال إكمال النشاط
```
core_completion_get_activities_completion_status
core_completion_get_course_completion_status
core_completion_update_activity_completion_status_manually
```

#### دوال الملفات
```
core_files_get_files
core_files_upload
```

### 4.5 إنشاء توكن المستخدم

1. اذهب إلى: **Site administration → Plugins → Web services → Manage tokens**
2. اضغط **Create token**
3. اختر المستخدم وحدد الخدمة `mdf_mobile_service`
4. اضغط **Save changes**
5. انسخ التوكن المُولّد

> ⚠️ **ملاحظة:** التطبيق يحصل على التوكن تلقائياً عند تسجيل الدخول عبر `/login/token.php`، لذا هذه الخطوة مطلوبة فقط للاختبار اليدوي.

### 4.6 إعدادات أمان إضافية

```php
// في config.php لـ Moodle

// السماح بـ CORS (للتطوير فقط)
$CFG->allowframembedding = true;

// تحديد فترة انتهاء التوكن (بالثواني)
// 0 = بلا انتهاء
$CFG->tokenduration = 0;
```

### 4.7 تفعيل تسجيل الدخول عبر التوكن

1. اذهب إلى: **Site administration → Plugins → Web services → External services**
2. تأكد أن خدمة `mdf_mobile_service` مفعّلة
3. اذهب إلى: **Site administration → Plugins → Authentication → Manage authentication**
4. تأكد من تفعيل **Web services authentication**

---

## 5. 🔔 إعداد Firebase (اختياري)

### 5.1 إنشاء مشروع Firebase

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اضغط **Create a project**
3. أدخل اسم المشروع: `mdf-app`
4. فعّل/عطّل Google Analytics حسب الحاجة
5. اضغط **Create project**

### 5.2 تكوين Flutter مع Firebase

```bash
# تثبيت Firebase CLI
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli

# تكوين المشروع
flutterfire configure --project=mdf-app
```

هذا الأمر سينشئ تلقائياً:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 5.3 تكوين Android

في `android/app/build.gradle` تأكد من وجود:
```gradle
apply plugin: 'com.google.gms.google-services'
```

في `android/build.gradle`:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

### 5.4 تكوين iOS

1. افتح المشروع في Xcode:
```bash
open ios/Runner.xcworkspace
```

2. تأكد من إضافة **Push Notifications** capability
3. تأكد من إضافة **Background Modes** → Remote notifications

### 5.5 اختبار الإشعارات

```bash
# إرسال إشعار اختباري عبر Firebase CLI
firebase messaging:send --project=mdf-app \
  --title="اختبار" \
  --body="رسالة اختبارية"
```

---

## 6. 📱 بناء التطبيق للإنتاج

### بناء Android APK
```bash
# APK عام
flutter build apk --release

# APK مقسم حسب المعمارية (حجم أصغر)
flutter build apk --split-per-abi --release

# App Bundle لـ Google Play
flutter build appbundle --release
```

الملفات الناتجة:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### بناء iOS
```bash
# بناء أرشيف iOS
flutter build ios --release

# ثم افتح Xcode
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

### إعداد التوقيع (Android)

1. أنشئ keystore:
```bash
keytool -genkey -v -keystore mdf-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mdf-key
```

2. أنشئ ملف `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=mdf-key
storeFile=../mdf-release-key.jks
```

3. حدّث `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## 7. 🔍 استكشاف الأخطاء

### مشاكل شائعة

#### خطأ اتصال بـ Moodle
```
ServerException: Connection error
```
**الحل:**
- تأكد أن عنوان URL صحيح ويحتوي على `https://`
- تأكد أن Web Services مفعّلة
- تأكد أن REST protocol مفعّل
- تأكد أن التوكن صالح

#### خطأ CORS
```
XMLHttpRequest error
```
**الحل:**
- هذا طبيعي في بيئة الويب، التطبيق مصمم للموبايل
- للتطوير، استخدم emulator أو جهاز حقيقي

#### خطأ "Function not available"
```
accessexception: Function xxx is not available
```
**الحل:**
- أضف الدالة المطلوبة إلى خدمة `mdf_mobile_service`
- تأكد أن المستخدم لديه الصلاحيات المناسبة

#### خطأ في التبعيات
```bash
# مسح الكاش وإعادة التثبيت
flutter clean
flutter pub get

# إذا استمرت المشكلة
flutter pub cache repair
```

#### خطأ في iOS pods
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### خطأ في Gradle (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### أدوات التشخيص

```bash
# تحليل الكود
dart analyze

# فحص بيئة Flutter
flutter doctor -v

# سجلات التصحيح
flutter run --verbose

# تتبع أداء التطبيق
flutter run --profile
```

---

## 📞 الدعم

إذا واجهت مشكلة لم تجد حلها هنا:

1. تحقق من [Issues](https://github.com/your-org/mdf/issues) على GitHub
2. افتح Issue جديد مع:
   - وصف المشكلة
   - خطوات إعادة الإنتاج
   - مخرجات `flutter doctor -v`
   - سجلات الأخطاء

</div>
