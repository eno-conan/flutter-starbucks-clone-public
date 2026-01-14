import 'package:go_router/go_router.dart';
import '../../poc/main.dart';
import '../../utils/sanitization_utils.dart';

/// POC関連のルート定義
final class PocRoutes {
  static List<RouteBase> get routes => [
    // ====================POC====================
    //
    //
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // ブランチ1: ホームタブ
        StatefulShellBranch(
          routes: [GoRoute(path: '/poc-home', builder: (context, state) => HomeTab())],
        ),
        // ブランチ2: 検索タブ
        StatefulShellBranch(
          routes: [GoRoute(path: '/search', builder: (context, state) => SearchTab())],
        ),
        // ブランチ3: プロフィールタブ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                final tabParam = SanitizationUtils.sanitizeQueryParameter(
                  state.uri.queryParameters['tab'] ?? '0',
                );
                final tabIndex = int.tryParse(tabParam) ?? 0;
                return ProfileTabContainer(initialTabIndex: tabIndex);
              },
              routes: [
                // タブ1のルート(A→B→C)
                GoRoute(
                  path: 'tab1/widget-b',
                  builder: (context, state) => WidgetB(),
                  routes: [
                    GoRoute(
                      path: 'widget-c',
                      builder: (context, state) {
                        final dataFromB = state.uri.queryParameters['data'] ?? '';
                        final sanitizedDataFromB = SanitizationUtils.sanitizeQueryParameter(
                          dataFromB,
                        );
                        return WidgetC(dataFromB: sanitizedDataFromB);
                      },
                    ),
                  ],
                ),
                // タブ2のルート(D→E→F→G→H)
                GoRoute(
                  path: 'tab2/widget-e',
                  builder: (context, state) => WidgetE(),
                  routes: [
                    GoRoute(path: 'widget-f', builder: (context, state) => WidgetF()),
                    GoRoute(
                      path: 'widget-g',
                      builder: (context, state) => WidgetG(),
                      routes: [
                        GoRoute(
                          path: 'widget-h',
                          builder: (context, state) {
                            final dataFromG = state.uri.queryParameters['data'] ?? '';
                            final sanitizedDataFromG = SanitizationUtils.sanitizeQueryParameter(
                              dataFromG,
                            );
                            return WidgetH(dataFromG: sanitizedDataFromG);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}
