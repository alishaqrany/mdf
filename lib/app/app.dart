import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

class MdfApp extends StatelessWidget {
  const MdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(context.read<AuthBloc>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ─── Title ───
      title: 'MDF Education',

      // ─── Localization ───
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // ─── Theme ───
      theme: AppTheme.light(locale: context.locale.languageCode),
      darkTheme: AppTheme.dark(locale: context.locale.languageCode),
      themeMode: ThemeMode.system,

      // ─── Router ───
      routerConfig: _appRouter.router,

      // ─── Debug ───
      debugShowCheckedModeBanner: false,
    );
  }
}
