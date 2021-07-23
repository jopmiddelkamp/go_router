import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// sample app using redirection to another location
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>(
        create: (context) => LoginInfo(),
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'Redirection GoRouter Example',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    routes: _routesBuilder,
    error: _errorBuilder,
    redirect: _redirect,
  );

  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
        GoRoute(
          pattern: '/',
          builder: (context, state) => MaterialPage<HomePage>(
            key: const ValueKey('HomePage'),
            child: HomePage(families: Families.data),
          ),
          routes: [
            GoRoute(
              pattern: 'family/:fid',
              builder: (context, state) {
                final family = Families.family(state.params['fid']!);
                return MaterialPage<FamilyPage>(
                  key: ValueKey(family),
                  child: FamilyPage(family: family),
                );
              },
              routes: [
                GoRoute(
                  pattern: 'person/:pid',
                  builder: (context, state) {
                    final family = Families.family(state.params['fid']!);
                    final person = family.person(state.params['pid']!);
                    return MaterialPage<PersonPage>(
                      key: ValueKey(person),
                      child: PersonPage(family: family, person: person),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          pattern: '/login',
          builder: (context, state) => const MaterialPage<LoginPage>(
            key: ValueKey('LoginPage'),
            child: LoginPage(),
          ),
        ),
      ];

  // redirect based on app and routing state
  String? _redirect(BuildContext context, String location) {
    // watching LoginInfo will cause a change in LoginInfo to trigger routing
    final loggedIn = context.watch<LoginInfo>().loggedIn;
    final goingToLogin = location == '/login';

    // the user is not logged in and not headed to /login, they need to login
    if (!loggedIn && !goingToLogin) return '/login';

    // the user is logged in and headed to /login, no need to login again
    if (loggedIn && goingToLogin) return '/';

    // no need to redirect at all
    return null;
  }

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: const ValueKey('ErrorPage'),
        child: ErrorPage(message: state.error.toString()),
      );
}
