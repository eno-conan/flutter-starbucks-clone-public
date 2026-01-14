import 'package:go_router/go_router.dart';

import 'routes/auth_routes.dart';
import 'routes/main_routes.dart';
import 'routes/poc_routes.dart';

///ルート一覧を定義
final class AppRouter {
  static List<RouteBase> get routes => [
    ...AuthRoutes.routes,
    ...MainRoutes.routes,
    ...PocRoutes.routes,
  ];

  // 他、必要になるかもしれないルート
  static List<RouteBase> routeListOld = [];
}
