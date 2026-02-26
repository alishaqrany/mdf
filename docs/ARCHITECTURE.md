<div dir="rtl">

# 🏗 توثيق المعمارية — MDF

دليل شامل لمعمارية المشروع، الأنماط المستخدمة، وكيفية إضافة ميزات جديدة.

---

## 📋 جدول المحتويات

1. [نظرة عامة على المعمارية](#1--نظرة-عامة-على-المعمارية)
2. [الطبقات المعمارية](#2--الطبقات-المعمارية)
3. [إدارة الحالة (Bloc)](#3--إدارة-الحالة-bloc)
4. [حقن التبعيات (DI)](#4--حقن-التبعيات-di)
5. [التوجيه (Routing)](#5--التوجيه-routing)
6. [عميل API](#6--عميل-api)
7. [معالجة الأخطاء](#7--معالجة-الأخطاء)
8. [الثيمات والتصميم](#8--الثيمات-والتصميم)
9. [الترجمة والتعريب](#9--الترجمة-والتعريب)
10. [كيفية إضافة ميزة جديدة](#10--كيفية-إضافة-ميزة-جديدة)
11. [اتفاقيات الكود](#11--اتفاقيات-الكود)

---

## 1. 🎯 نظرة عامة على المعمارية

المشروع يتبع **Clean Architecture** بنمط **Feature-First**، مما يضمن:

- **فصل الاهتمامات** — كل طبقة لها مسؤولية واحدة
- **قابلية الاختبار** — الطبقات مستقلة ويمكن اختبارها منفردة
- **قابلية التوسع** — إضافة ميزات جديدة لا تؤثر على القائمة
- **صيانة سهلة** — التغييرات محصورة في طبقتها

### مخطط المعمارية العام

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    main.dart                          │    │
│  │  (نقطة الدخول: DI → Localization → MaterialApp)     │    │
│  └────────────────────┬────────────────────────────────┘    │
│                       │                                      │
│  ┌────────────────────▼────────────────────────────────┐    │
│  │                   app/ layer                         │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐    │    │
│  │  │ app.dart │ │  router/  │ │     theme/       │    │    │
│  │  │(Material)│ │(GoRouter) │ │(Colors/Fonts/    │    │    │
│  │  │          │ │   +Guards │ │ Dark/Light)      │    │    │
│  │  └──────────┘ └──────────┘ └──────────────────┘    │    │
│  │                ┌──────────┐                         │    │
│  │                │   di/    │                         │    │
│  │                │ (GetIt)  │                         │    │
│  │                └──────────┘                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                       │                                      │
│  ┌────────────────────▼────────────────────────────────┐    │
│  │                  core/ layer                         │    │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────┐  │    │
│  │  │  api/  │ │ error/ │ │network/│ │  widgets/  │  │    │
│  │  │(Moodle)│ │(Fail/  │ │(Check) │ │ (Shared)   │  │    │
│  │  │(Client)│ │ Except)│ │        │ │            │  │    │
│  │  └────────┘ └────────┘ └────────┘ └────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                       │                                      │
│  ┌────────────────────▼────────────────────────────────┐    │
│  │               features/ layer                        │    │
│  │                                                      │    │
│  │  ┌─── auth ───┐  ┌── courses ──┐  ┌─ profile ──┐  │    │
│  │  │ ┌────────┐ │  │ ┌────────┐  │  │ ┌────────┐ │  │    │
│  │  │ │Present.│ │  │ │Present.│  │  │ │Present.│ │  │    │
│  │  │ ├────────┤ │  │ ├────────┤  │  │ ├────────┤ │  │    │
│  │  │ │Domain  │ │  │ │Domain  │  │  │ │Domain  │ │  │    │
│  │  │ ├────────┤ │  │ ├────────┤  │  │ ├────────┤ │  │    │
│  │  │ │ Data   │ │  │ │ Data   │  │  │ │ Data   │ │  │    │
│  │  │ └────────┘ │  │ └────────┘  │  │ └────────┘ │  │    │
│  │  └────────────┘  └─────────────┘  └────────────┘  │    │
│  │  ... (student_dashboard, admin_dashboard, etc.)    │    │
│  └─────────────────────────────────────────────────────┘    │
│                       │                                      │
│  ┌────────────────────▼────────────────────────────────┐    │
│  │              Moodle Server (REST API)                │    │
│  │         POST /webservice/rest/server.php            │    │
│  │              GET /login/token.php                    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### تدفق البيانات

```
User Action → Page → Bloc (Event)
                       ↓
                    UseCase
                       ↓
              Repository (interface)
                       ↓
            Repository Implementation
                       ↓
                  DataSource
                       ↓
               MoodleApiClient
                       ↓
                 Moodle Server
                       ↓
                  JSON Response
                       ↓
                   Model.fromJson()
                       ↓
                 Entity (domain)
                       ↓
            Either<Failure, Entity>
                       ↓
                  Bloc (State)
                       ↓
              BlocBuilder → UI
```

---

## 2. 📚 الطبقات المعمارية

### 2.1 طبقة العرض (Presentation Layer)

**المسؤولية:** واجهة المستخدم وإدارة الحالة

```
features/{name}/presentation/
├── bloc/
│   ├── {name}_bloc.dart       ← Bloc/Cubit للحالة
│   ├── {name}_event.dart      ← الأحداث (part file)
│   └── {name}_state.dart      ← الحالات (part file)
└── pages/
    └── {name}_page.dart       ← صفحة الواجهة
```

**القواعد:**
- الصفحات لا تعرف عن مصادر البيانات
- Bloc هو الوسيط الوحيد بين الصفحة والبيانات
- استخدم `BlocBuilder` و `BlocListener` للتفاعل مع الحالات
- لا منطق أعمال في الصفحات

**مثال — AuthBloc:**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthUseCase checkAuthUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkAuthUseCase,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckAuth);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
  }
}
```

### 2.2 طبقة النطاق (Domain Layer)

**المسؤولية:** منطق الأعمال النقي (لا تبعيات خارجية)

```
features/{name}/domain/
├── entities/
│   └── {name}.dart            ← كيان الأعمال (Equatable)
├── repositories/
│   └── {name}_repository.dart ← واجهة المستودع (abstract)
└── usecases/
    └── {name}_usecase.dart    ← حالة استخدام واحدة
```

**القواعد:**
- الكيانات تمتد `Equatable` ولا تحتوي على JSON
- المستودعات هي واجهات مجرّدة فقط (`abstract class`)
- كل UseCase يؤدي عملية واحدة
- النتائج تُغلّف في `Either<Failure, T>`

**مثال — Entity:**
```dart
class User extends Equatable {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final bool isAdmin;

  const User({...});

  @override
  List<Object?> get props => [id, username, fullName, email];
}
```

**مثال — Repository Interface:**
```dart
abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String serverUrl,
    required String username,
    required String password,
  });
  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, User>> checkAuth();
}
```

**مثال — UseCase:**
```dart
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    return repository.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }
}
```

### 2.3 طبقة البيانات (Data Layer)

**المسؤولية:** الوصول للبيانات، التحويل، التخزين المؤقت

```
features/{name}/data/
├── datasources/
│   ├── {name}_remote_datasource.dart  ← API calls
│   └── {name}_local_datasource.dart   ← Local cache
├── models/
│   └── {name}_model.dart              ← JSON ↔ Dart model
└── repositories/
    └── {name}_repository_impl.dart    ← تنفيذ المستودع
```

**القواعد:**
- Models تمتد Entities وتضيف `fromJson`/`toJson`
- DataSources تتعامل مع MoodleApiClient مباشرة
- Repository Implementation تتعامل مع الأخطاء وتحويلها لـ Failure

**مثال — Model:**
```dart
class UserModel extends User {
  const UserModel({...});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userid'] as int,
      username: json['username'] as String,
      fullName: json['fullname'] as String,
      // ...
    );
  }

  Map<String, dynamic> toJson() => {
    'userid': id,
    'username': username,
    // ...
  };
}
```

**مثال — Repository Implementation:**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, User>> login({...}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.login(...);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    }
  }
}
```

---

## 3. 🔄 إدارة الحالة (Bloc)

### نمط Bloc المستخدم

```
┌──────────┐     Event      ┌──────────┐     State      ┌──────────┐
│   Page   │ ──────────────→│   Bloc   │ ──────────────→│   Page   │
│  (UI)    │                │ (Logic)  │                │  (UI)    │
│          │                │          │                │ Rebuild  │
└──────────┘                └──────────┘                └──────────┘
                                 │
                                 ↓
                            ┌──────────┐
                            │ UseCase  │
                            └──────────┘
```

### هيكل الأحداث (Events)

```dart
// auth_event.dart
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String serverUrl;
  final String username;
  final String password;

  AuthLoginRequested({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [serverUrl, username, password];
}

class AuthLogoutRequested extends AuthEvent {}
```

### هيكل الحالات (States)

```dart
// auth_state.dart
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}
```

### استخدام BlocBuilder في الصفحات

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return const AppLoadingWidget();
    }
    if (state is AuthError) {
      return AppErrorWidget(message: state.message);
    }
    if (state is AuthAuthenticated) {
      return _buildContent(state.user);
    }
    return const SizedBox.shrink();
  },
)
```

---

## 4. 💉 حقن التبعيات (DI)

### نظرة عامة

نستخدم **GetIt** كـ Service Locator لحقن التبعيات. جميع التسجيلات في ملف واحد:

```
lib/app/di/injection.dart
```

### أنواع التسجيل

| النوع | الاستخدام | مثال |
|-------|----------|------|
| `registerLazySingleton` | مثيل واحد يُنشأ عند الحاجة | Repositories, DataSources, UseCases |
| `registerFactory` | مثيل جديد كل مرة | Blocs, Cubits |
| `registerSingleton` | مثيل واحد يُنشأ فوراً | SharedPreferences |

### ترتيب التسجيل

```dart
Future<void> initDependencies() async {
  // 1. External (مكتبات خارجية)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Connectivity());

  // 2. Core (البنية التحتية)
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<MoodleApiClient>(
    () => MoodleApiClient(secureStorage: sl()),
  );

  // 3. Features (كل ميزة على حدة)
  // DataSource → Repository → UseCase → Bloc
  _initAuthFeature();
  _initCoursesFeature();
  _initCourseContentFeature();
  _initStudentDashboardFeature();
  _initAdminDashboardFeature();
  _initProfileFeature();
}
```

### الاستخدام

```dart
// في أي مكان بالتطبيق
final authBloc = sl<AuthBloc>();
final apiClient = sl<MoodleApiClient>();
```

### إضافة ميزة جديدة

```dart
// أضف هذه الأسطر في initDependencies()

// DataSource
sl.registerLazySingleton<NewFeatureRemoteDataSource>(
  () => NewFeatureRemoteDataSourceImpl(apiClient: sl()),
);

// Repository
sl.registerLazySingleton<NewFeatureRepository>(
  () => NewFeatureRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
);

// UseCases
sl.registerLazySingleton(() => NewFeatureUseCase(sl()));

// Bloc
sl.registerFactory(() => NewFeatureBloc(useCase: sl()));
```

---

## 5. 🗺 التوجيه (Routing)

### نظرة عامة

نستخدم **GoRouter** مع حراسة المسارات حسب دور المستخدم.

### هيكل المسارات

```
/login                          ← صفحة تسجيل الدخول

/student                        ← لوحة الطالب (ShellRoute)
/student/courses                ← مقررات الطالب
/student/course/:courseId       ← محتوى مقرر
/student/profile                ← ملف الطالب الشخصي

/admin                          ← لوحة الإدارة (ShellRoute)
/admin/courses                  ← إدارة المقررات
/admin/profile                  ← ملف المدير الشخصي
```

### حراسة المسارات (Route Guards)

```dart
redirect: (context, state) {
  final authState = _authBloc.state;
  final isAuthenticated = authState is AuthAuthenticated;
  final isLoginRoute = state.matchedLocation == '/login';

  // غير مصادق → صفحة الدخول
  if (!isAuthenticated && !isLoginRoute) return '/login';

  // مصادق → لوحة حسب الدور
  if (isAuthenticated && isLoginRoute) {
    return authState.user.isAdmin ? '/admin' : '/student';
  }

  return null; // لا إعادة توجيه
}
```

### ShellRoute مع شريط التنقل السفلي

كل قسم (طالب/مدير) يستخدم `ShellRoute` لعرض `BottomNavigationBar` مشترك:

```dart
ShellRoute(
  builder: (context, state, child) => _StudentShell(child: child),
  routes: [
    GoRoute(path: '/student', ...),
    GoRoute(path: '/student/courses', ...),
    GoRoute(path: '/student/profile', ...),
  ],
)
```

### التنقل

```dart
// التنقل لصفحة
context.go('/student/courses');

// التنقل مع بارامترات
context.goNamed(
  AppRoutes.courseContent,
  pathParameters: {'courseId': '123'},
  queryParameters: {'title': 'Math 101'},
);

// التنقل للخلف
context.pop();
```

---

## 6. 🌐 عميل API

### MoodleApiClient

عميل مركزي للتواصل مع Moodle REST API:

```dart
class MoodleApiClient {
  late final Dio _dio;

  // تكوين Dio مع:
  // - Timeout: 30 ثانية
  // - Content-Type: application/x-www-form-urlencoded
  // - 3 Interceptors: Auth, Error, Logging
}
```

### Interceptors

| Interceptor | الوظيفة |
|-------------|---------|
| **AuthInterceptor** | يُضيف التوكن تلقائياً لكل طلب |
| **ErrorInterceptor** | يحوّل أخطاء Dio لاستثناءات مخصصة |
| **LoggingInterceptor** | يطبع تفاصيل الطلبات للتصحيح |

### كيفية استدعاء API

```dart
// استدعاء دالة Moodle
final result = await apiClient.callFunction(
  function: 'core_course_get_courses',
  params: {'options[ids][0]': '123'},
);

// تسجيل الدخول
final token = await apiClient.login(
  username: 'admin',
  password: 'pass',
);
```

### نقاط النهاية (API Endpoints)

جميع النقاط معرّفة في `lib/core/api/api_endpoints.dart`:

```dart
abstract class ApiEndpoints {
  // Auth
  static const getSiteInfo = 'core_webservice_get_site_info';
  
  // Users
  static const getUsers = 'core_user_get_users';
  static const getUsersByField = 'core_user_get_users_by_field';
  static const createUsers = 'core_user_create_users';
  
  // Courses
  static const getCourses = 'core_course_get_courses';
  static const searchCourses = 'core_course_search_courses';
  
  // ... 70+ نقطة نهاية أخرى
}
```

---

## 7. ⚠️ معالجة الأخطاء

### التسلسل الهرمي

```
                    Exception (طبقة البيانات)
                         │
         ┌───────────────┼───────────────────┐
         │               │                   │
  ServerException  NetworkException   CacheException
         │
    AuthException
    MoodleException

                    Failure (طبقة النطاق)
                         │
     ┌───────┬───────┬───────┬────────┬─────────────┐
     │       │       │       │        │             │
  Server  Network  Cache   Auth  Permission  Validation
  Failure Failure Failure Failure  Failure    Failure
```

### تدفق معالجة الأخطاء

```
API Call → DioException
              ↓
         ErrorInterceptor
              ↓
       ServerException / AuthException
              ↓
     Repository Implementation
              ↓ (try-catch)
       Left(ServerFailure) / Left(AuthFailure)
              ↓
            Bloc
              ↓
         ErrorState(message)
              ↓
      AppErrorWidget(message)
```

### مثال كامل

```dart
// في Repository
@override
Future<Either<Failure, List<Course>>> getEnrolledCourses(int userId) async {
  if (!await networkInfo.isConnected) {
    return const Left(NetworkFailure());
  }
  try {
    final courses = await remoteDataSource.getEnrolledCourses(userId);
    return Right(courses);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message));
  } on AuthException {
    return const Left(AuthFailure());
  } catch (e) {
    return Left(UnexpectedFailure(message: e.toString()));
  }
}

// في Bloc
final result = await getEnrolledCoursesUseCase(userId);
result.fold(
  (failure) => emit(CoursesError(message: failure.message)),
  (courses) => emit(CoursesLoaded(courses: courses)),
);
```

---

## 8. 🎨 الثيمات والتصميم

### بنية الثيمات

```
lib/app/theme/
├── app_theme.dart     ← ThemeData الفاتح والداكن
├── colors.dart        ← لوحة الألوان
└── typography.dart    ← أنماط الخطوط
```

### لوحة الألوان

```dart
abstract class AppColors {
  // Primary
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9D97FF);
  static const primaryDark = Color(0xFF4A42E8);

  // Accent/Secondary
  static const secondary = Color(0xFFFF6584);

  // Background
  static const backgroundLight = Color(0xFFF5F5F5);
  static const backgroundDark = Color(0xFF1A1A2E);

  // Surface
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF16213E);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);
}
```

### الخطوط حسب اللغة

| اللغة | الخط |
|-------|------|
| العربية | Cairo |
| English | Poppins |

```dart
// يتم اختيار الخط تلقائياً حسب اللغة
static TextTheme _getTextTheme(Locale locale) {
  return locale.languageCode == 'ar'
    ? GoogleFonts.cairoTextTheme()
    : GoogleFonts.poppinsTextTheme();
}
```

### Material 3

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
)
```

---

## 9. 🌍 الترجمة والتعريب

### الإعداد

- مكتبة: **easy_localization**
- ملفات الترجمة: `assets/translations/{ar,en}.json`
- عدد المفاتيح: **307 مفتاح** لكل لغة

### هيكل ملف الترجمة

```json
{
  "app_name": "منصة MDF التعليمية",
  "auth": {
    "login": "تسجيل الدخول",
    "logout": "تسجيل الخروج",
    "username": "اسم المستخدم",
    "password": "كلمة المرور",
    "server_url": "عنوان السيرفر"
  },
  "dashboard": {
    "welcome_back": "مرحباً بعودتك",
    "continue_learning": "أكمل التعلم"
  }
}
```

### الاستخدام

```dart
// في الكود
Text('auth.login'.tr())

// مع بارامترات
Text('welcome_message'.tr(args: ['أحمد']))

// تغيير اللغة
context.setLocale(const Locale('ar'));
```

### دعم RTL

```dart
// يتم تلقائياً — easy_localization يضبط الاتجاه
// يمكن أيضاً التحقق يدوياً:
Directionality.of(context) // TextDirection.rtl or ltr
```

---

## 10. 🆕 كيفية إضافة ميزة جديدة

### الخطوات بالترتيب

#### الخطوة 1: إنشاء هيكل المجلدات

```bash
# مثال: ميزة "الاختبارات" (quizzes)
mkdir -p lib/features/quizzes/data/datasources
mkdir -p lib/features/quizzes/data/models
mkdir -p lib/features/quizzes/data/repositories
mkdir -p lib/features/quizzes/domain/entities
mkdir -p lib/features/quizzes/domain/repositories
mkdir -p lib/features/quizzes/domain/usecases
mkdir -p lib/features/quizzes/presentation/bloc
mkdir -p lib/features/quizzes/presentation/pages
```

#### الخطوة 2: Domain Layer (ابدأ من هنا دائماً)

```dart
// 1. Entity
// lib/features/quizzes/domain/entities/quiz.dart
class Quiz extends Equatable {
  final int id;
  final String name;
  final int courseId;
  final int timeLimit;
  final int attempts;
  // ...
}

// 2. Repository Interface
// lib/features/quizzes/domain/repositories/quiz_repository.dart
abstract class QuizRepository {
  Future<Either<Failure, List<Quiz>>> getQuizzesByCourse(int courseId);
  Future<Either<Failure, QuizAttempt>> startAttempt(int quizId);
  Future<Either<Failure, Unit>> submitAttempt(int attemptId, List<Answer> answers);
}

// 3. Use Cases
// lib/features/quizzes/domain/usecases/get_quizzes_usecase.dart
class GetQuizzesUseCase {
  final QuizRepository repository;
  GetQuizzesUseCase(this.repository);
  
  Future<Either<Failure, List<Quiz>>> call(int courseId) {
    return repository.getQuizzesByCourse(courseId);
  }
}
```

#### الخطوة 3: Data Layer

```dart
// 1. Model
// lib/features/quizzes/data/models/quiz_model.dart
class QuizModel extends Quiz {
  factory QuizModel.fromJson(Map<String, dynamic> json) {...}
  Map<String, dynamic> toJson() => {...};
}

// 2. DataSource
// lib/features/quizzes/data/datasources/quiz_remote_datasource.dart
abstract class QuizRemoteDataSource {
  Future<List<QuizModel>> getQuizzesByCourse(int courseId);
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final MoodleApiClient apiClient;
  // ...
}

// 3. Repository Implementation
// lib/features/quizzes/data/repositories/quiz_repository_impl.dart
class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  // ...
}
```

#### الخطوة 4: Presentation Layer

```dart
// 1. Bloc
// lib/features/quizzes/presentation/bloc/quiz_bloc.dart
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final GetQuizzesUseCase getQuizzesUseCase;
  // ...
}

// 2. Page
// lib/features/quizzes/presentation/pages/quiz_page.dart
class QuizPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuizBloc>()..add(LoadQuizzes(courseId: courseId)),
      child: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) { ... },
      ),
    );
  }
}
```

#### الخطوة 5: التسجيل في DI

```dart
// في lib/app/di/injection.dart
// أضف imports وتسجيلات GetIt
```

#### الخطوة 6: إضافة المسار

```dart
// في lib/app/router/app_router.dart
GoRoute(
  path: '/student/quizzes',
  name: AppRoutes.quizzes,
  builder: (context, state) => const QuizPage(),
),
```

#### الخطوة 7: إضافة الترجمات

```json
// في assets/translations/ar.json
{
  "quizzes": {
    "title": "الاختبارات",
    "start_quiz": "بدء الاختبار",
    "time_remaining": "الوقت المتبقي"
  }
}
```

---

## 11. 📏 اتفاقيات الكود

### تسمية الملفات
- **snake_case** لجميع ملفات Dart: `auth_bloc.dart`, `user_model.dart`
- **PascalCase** للكلاسات: `AuthBloc`, `UserModel`
- **camelCase** للدوال والمتغيرات: `getEnrolledCourses`, `userId`

### تنظيم الـ imports
```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. مكتبات خارجية (أبجدياً)
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. ملفات المشروع (نسبية)
import '../../core/api/moodle_api_client.dart';
import '../domain/entities/user.dart';
```

### أنماط التسمية

| الشيء | النمط | مثال |
|-------|-------|------|
| ملف | snake_case | `auth_repository.dart` |
| كلاس | PascalCase | `AuthRepository` |
| دالة/متغير | camelCase | `getUsers()` |
| ثابت | camelCase أو SCREAMING_CASE | `maxRetries` |
| Bloc Event | PascalCase + فعل | `AuthLoginRequested` |
| Bloc State | PascalCase + صفة | `AuthAuthenticated` |
| Failure | PascalCase + Failure | `ServerFailure` |
| Exception | PascalCase + Exception | `ServerException` |

### قواعد عامة
- لا تستخدم `dynamic` إلا للضرورة
- استخدم `const` كلما أمكن
- استخدم `final` للمتغيرات غير القابلة للتغيير
- كل كلاس في ملف منفصل
- لا ملفات أكبر من 500 سطر (قسّم إلى ودجات فرعية)
- اكتب تعليقات `///` للكلاسات والدوال العامة

</div>
