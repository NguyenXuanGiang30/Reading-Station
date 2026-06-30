/// Trạm Đọc - Main Entry Point
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'router.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/theme/theme_cubit.dart';
import 'blocs/book/book_bloc.dart';
import 'blocs/flashcard/flashcard_bloc.dart';
import 'blocs/note/note_bloc.dart';
import 'blocs/settings/settings_bloc.dart';
import 'blocs/settings/settings_event.dart';
import 'blocs/social/social_bloc.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting
  await initializeDateFormatting('vi_VN', null);
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const TramDocApp());
}

class TramDocApp extends StatefulWidget {
  const TramDocApp({super.key});

  @override
  State<TramDocApp> createState() => _TramDocAppState();
}

class _TramDocAppState extends State<TramDocApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(const AuthCheckRequested());
    _router = AppRouter.router(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(create: (context) => BookBloc()),
          BlocProvider(create: (context) => FlashcardBloc()),
          BlocProvider(create: (context) => NoteBloc()),
          BlocProvider(create: (context) => SettingsBloc()..add(SettingsLoadRequested())),
          BlocProvider(create: (context) => SocialBloc()),
        ],
        child: Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp.router(
                  title: 'Trạm Đọc',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  locale: localeProvider.locale,
                  supportedLocales: S.supportedLocales,
                  localizationsDelegates: const [
                    S.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: _router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
