import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/cart/presentation/bloc/cart_event.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

class ShirinApp extends StatelessWidget {
  const ShirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>(),
        ),
        BlocProvider<CartBloc>(
          create: (_) => di.sl<CartBloc>()..add(const LoadCart()),
        ),
        BlocProvider<HomeBloc>(
          create: (_) => di.sl<HomeBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Ширин',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('ky'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: AppRouter.router,
      ),
    );
  }
}
