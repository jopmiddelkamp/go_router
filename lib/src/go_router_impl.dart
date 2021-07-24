import 'package:flutter/widgets.dart';
import '../go_router.dart';

/// GoRouter implementation of the RouterDelegate base class
class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  Uri _loc;
  final _key = GlobalKey<NavigatorState>();
  final GoRouterWidgetBuilder builder;
  final GoRouterGuard? guard;

  GoRouterDelegate({
    required this.builder,
    this.guard,
    Uri? initialLocation,
  }) : _loc = initialLocation ?? Uri() {
    // when the guard's contained listener changes, refresh the route
    guard?.addListener(_refreshRoute);
  }

  void _refreshRoute() {
    setNewRoutePath(_loc);
    notifyListeners();
  }

  void go(String route) {
    setNewRoutePath(Uri.parse(route));
    notifyListeners();
  }

  @override
  void dispose() {
    guard?.removeListener(_refreshRoute);
    super.dispose();
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;

  @override
  Uri get currentConfiguration => _loc;

  @override
  Widget build(BuildContext context) =>
      builder(context, _loc.toString().trim());

  @override
  Future<void> setInitialRoutePath(Uri configuration) => setNewRoutePath(
        // override initial nav to home to whatever the initial location is
        configuration.toString() == '/' ? _loc : configuration,
      );

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    // check for redirect
    final loc = configuration.toString();
    final redirectLoc = guard?.redirect(loc);
    if (redirectLoc == null) {
      _loc = configuration;
      return;
    }

    // check redirect is a valid URI
    final redirectUri = Uri.parse(redirectLoc);

    // check redirect for loop (ignore query params)
    final loop = configuration.path.toLowerCase().trim() ==
        redirectUri.path.toLowerCase().trim();
    if (loop) throw Exception('redirecting to same location: $loc');

    // check for redirect redirecting
    final redirectLoc2 = guard!.redirect(redirectLoc);
    if (redirectLoc2 != null) {
      throw Exception(
        'redirect redirecting: $loc => $redirectLoc => $redirectLoc2',
      );
    }

    // cache redirected loc
    _loc = redirectUri;
  }
}

/// GoRouter implementation of the RouteInformationParser base class
class GoRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async =>
      Uri.parse(routeInformation.location!);

  @override
  RouteInformation restoreRouteInformation(Uri configuration) =>
      RouteInformation(location: configuration.toString());
}

/// GoRouter implementation of InheritedWidget for purposes of finding the
/// current GoRouter in the widget tree. This is useful when routing from
/// anywhere in your app.
class InheritedGoRouter extends InheritedWidget {
  final GoRouter goRouter;
  const InheritedGoRouter({
    required Widget child,
    required this.goRouter,
    Key? key,
  }) : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

class GoRouteMatch {
  final GoRoute route;
  final String loc;
  final Map<String, String> params;
  GoRouteMatch(this.route, this.loc, this.params);

  static GoRouteMatch? match(GoRoute route, String location) {
    final match = route.matchPatternAsPrefix(location);
    if (match == null) return null;
    final params = route.extractPatternParams(match);
    final subloc = GoRouter.locationFor(route.pattern, params);
    return GoRouteMatch(route, subloc, params);
  }
}
