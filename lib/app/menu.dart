import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/menu_items.dart';
import '../core/services/logger_service.dart';
import '../provider/auth_state_provider.dart';
import '../shared/widgets/splash_screen.dart';

///メニュー画面
class MenuPage extends StatelessWidget {
  const MenuPage({super.key, this.showSnackBar});
  static String routeName = '/';
  final bool? showSnackBar;

  @override
  Widget build(BuildContext context) {
    if (showSnackBar ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('サインインしました。'), duration: Duration(seconds: 3)));
      });
    }
    return const ControlDisplayWidget();
  }
}

class ControlDisplayWidget extends ConsumerWidget {
  const ControlDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // デバイスの幅を取得
    final deviceWidth = MediaQuery.sizeOf(context).width;
    if (kDebugMode) {
      LoggerService.info('デバイス幅: $deviceWidth');
    }

    // 初回起動時は initialAuthStateProvider を使用
    final initialAuthAsync = ref.watch(initialAuthStateProvider);

    return initialAuthAsync.when(
      loading: () => const SplashScreen(),
      error: (error, _) {
        if (kDebugMode) {
          LoggerService.warn('トップ画面表示時にエラー発生: $error');
        }

        final errorString = error.toString().toLowerCase();
        if (errorString.contains('refresh_token_not_found') ||
            errorString.contains('refresh token not found') ||
            errorString.contains('invalid refresh token') ||
            errorString.contains('authapi')) {
          if (kDebugMode) {
            LoggerService.warn('認証エラー（リフレッシュトークン関連）を検出 - 未ログイン画面を表示');
          }
          return const NotLoginedScreen();
        }

        if (errorString.contains('auth')) {
          if (kDebugMode) {
            LoggerService.warn('認証関連エラーを検出 - 未ログイン画面を表示');
          }
          return const NotLoginedScreen();
        }

        return const NotLoginedScreen();
      },
      data: (user) {
        // 初回チェック完了後、Streamの監視も開始
        ref.listen(authStateProvider, (previous, next) {
          // 認証状態の変更を監視（サインアウトなど）
          if (kDebugMode) {
            LoggerService.info('認証状態が変更されました');
          }
        });

        return user != null && !user.email!.startsWith('0011')
            ? const NotLoginedScreen()
            : const NotLoginedScreen();
      },
    );
  }
}

/// 未ログイン時のコンテンツ
class NotLoginedScreen extends StatefulWidget {
  const NotLoginedScreen({super.key});

  @override
  State<NotLoginedScreen> createState() => _NotLoginedScreenState();
}

class _NotLoginedScreenState extends State<NotLoginedScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starbucks and ...', style: TextStyle(color: Colors.white)),
        key: ValueKey('menu_page_app_bar'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        key: ValueKey('menu_page_body'),
        child: Column(
          children: [
            // 🆕 Crashlyticsテストセクション（デバッグモードのみ表示）
            if (kDebugMode) ...[
              const _CrashlyticsTestSection(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // 既存のメニューグリッド
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return const ItemGridBuilder(crossAxisCount: 4);
                  } else {
                    return const ItemGridBuilder(crossAxisCount: 3);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid Builderで各アイコンを表示
class ItemGridBuilder extends StatelessWidget {
  const ItemGridBuilder({super.key, required this.crossAxisCount});
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          key: ValueKey('menu_page_custom_scroll_view'),
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ItemTile(menuItems[index]),
                childCount: menuItems.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.95, // 幅と高さの比率
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemTile extends StatelessWidget {
  const ItemTile(this.item, {super.key});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final routeName = item.routeName;
    return Column(
      children: [
        PlatformIconButton(
          key: Key('menu_item_$routeName'),
          onPressed: () {
            context.go(routeName);
          },
          materialIcon: Icon(item.materialIcon),
          cupertinoIcon: Icon(item.cupertinoIcon, size: 28.0),
        ),
        SizedBox(
          height: 40, // 適切な高さを設定
          child: Text(
            item.label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// 🆕 Firebase Crashlyticsのテスト機能セクション
class _CrashlyticsTestSection extends StatelessWidget {
  const _CrashlyticsTestSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.shade50,
      ),
      child: Column(
        spacing: 12,
        children: [
          Text(
            '🔥 Crashlytics テスト（デバッグのみ）',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // ユーザー情報とログを設定
              await FirebaseCrashlytics.instance.setUserIdentifier('test_user_menu_page');
              await FirebaseCrashlytics.instance.setCustomKey('test_location', 'menu_page');
              await FirebaseCrashlytics.instance.setCustomKey('app_version', '1.0.0');
              await FirebaseCrashlytics.instance.log('Testing crash from MenuPage with user info');

              // 強制的なクラッシュを実行（注意：アプリが終了します）
              FirebaseCrashlytics.instance.crash();
            },
            icon: const Icon(Icons.dangerous, size: 18),
            label: const Text('クラッシュテスト'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
