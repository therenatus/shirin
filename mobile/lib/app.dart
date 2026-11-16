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
import 'core/push/push_service.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/notifications/presentation/bloc/notifications_cubit.dart';

class ShirinApp extends StatelessWidget {
  const ShirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
        BlocProvider<CartBloc>(
          create: (_) => di.sl<CartBloc>()..add(const LoadCart()),
        ),
        BlocProvider<HomeBloc>(create: (_) => di.sl<HomeBloc>()),
        BlocProvider<NotificationsCubit>.value(
          value: di.sl<NotificationsCubit>(),
        ),
      ],
      child: _Session(
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
      ),
    );
  }
}

/// Ties notifications to the session: on sign-in registers the device for
/// push and loads the unread count; on sign-out clears them. Also refreshes
/// the count when the app comes back to the foreground or a push arrives.
class _Session extends StatefulWidget {
  final Widget child;
  const _Session({required this.child});

  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> with WidgetsBindingObserver {
  final _push = di.sl<PushService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final notifications = context.read<NotificationsCubit>();
    _push.onForegroundMessage = (_) => notifications.refreshUnread();
    _push.onOpenOrder = (id) => AppRouter.router.push('/orders/$id');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        context.read<AuthBloc>().state is Authenticated) {
      context.read<NotificationsCubit>().refreshUnread();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.runtimeType != b.runtimeType,
      listener: (context, state) {
        final notifications = context.read<NotificationsCubit>();
        if (state is Authenticated) {
          notifications.refreshUnread();
          _push.registerForUser();
        } else if (state is Unauthenticated) {
          notifications.clear();
          _push.unregister();
        }
      },
      child: widget.child,
    );
  }
}
