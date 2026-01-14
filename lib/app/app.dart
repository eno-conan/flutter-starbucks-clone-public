import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_router.dart';
import '../config/deep_link_paths.dart';
import '../constants/id_keys.dart';
import '../constants/my_colors.dart';
import '../core/services/logger_service.dart';
import '../provider/responsive_dimensions_provider.dart';
import '../services/auth_service.dart';
import '../shared/widgets/splash_screen.dart';
import 'menu.dart';

/// アプリケーションのエントリーポイント
class TestingApp extends ConsumerStatefulWidget {
  const TestingApp({super.key});

  @override
  ConsumerState<TestingApp> createState() => _TestingAppState();
}

class _TestingAppState extends ConsumerState<TestingApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isProcessingDeepLink = false;
  bool _isInitializing = true; // ←追加: 初期化中フラグ
  final _authService = AuthService();

  final _router = GoRouter(
    initialLocation: SplashScreen.routeName,
    routes: AppRouter.routes,
    redirect: (context, state) {
      // リダイレクト処理の詳細ログを追加
      if (kDebugMode) {
        debugPrint('GoRouter redirect - location: ${state.uri}, path: ${state.uri.path}');
      }
      return null;
    },
    // 404エラーページの処理を追加
    errorBuilder: (context, state) {
      // App Linksで処理されない未知のパスの場合、メニューページにリダイレクト
      if (kDebugMode) {
        debugPrint('GoRouter error for path: ${state.uri.path}, redirecting to menu');
      }
      return const MenuPage();
    },
  );

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// アプリの初期化処理
  Future<void> _initializeApp() async {
    // コールドスタート時のディープリンク処理
    final uri = await _getInitialDeepLink();

    if (uri != null) {
      if (kDebugMode) {
        LoggerService.info('Got initial deep link: $uri');
      }
      openAppLink(uri);
    } else {
      // ディープリンクがない場合はメニューへ
      _router.go(MenuPage.routeName);
    }

    // アプリ起動後のディープリンク処理を開始
    _listenToDeepLinks();

    // ←追加: 初期化完了
    setState(() {
      _isInitializing = false;
    });
  }

  /// 初期ディープリンクを取得
  Future<Uri?> _getInitialDeepLink() async {
    try {
      _appLinks = AppLinks();
      return await _appLinks.getInitialLink();
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('Error getting initial deep link: $e');
      }
      return null;
    }
  }

  /// ディープリンクのストリームをリッスン
  void _listenToDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (kDebugMode) {
        LoggerService.info('Got deep link while app running: $uri');
      }
      openAppLink(uri);
    });
  }

  void openAppLink(Uri uri) {
    setState(() {
      _isProcessingDeepLink = true;
    });

    if (!_isValidUri(uri)) {
      if (kDebugMode) {
        debugPrint('Invalid URI: $uri');
      }
      _navigateToMenu();
      setState(() {
        _isProcessingDeepLink = false;
      });
      return;
    }

    final path = uri.path.isEmpty ? '/' : uri.path;
    final deepLinkPath = DeepLinkPath.fromString(path);

    if (deepLinkPath != null) {
      deepLinkPath.handle(uri, _router, _authService);
    } else {
      _navigateToMenu();
    }

    // 遷移完了後、即座にローディングを解除
    setState(() {
      _isProcessingDeepLink = false;
    });
  }

  /// メニューページに安全に遷移する
  void _navigateToMenu() {
    // 現在のルーティングコンテキストをリセットしてメニューページに遷移
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.go(MenuPage.routeName);
    });
  }

  /// URIの妥当性を検証(スキームとホストの両方をチェック)
  bool _isValidUri(Uri uri) {
    // カスタムスキーム(開発用)の検証
    if (uri.scheme == 'testingapp') {
      return true; // スキームが正しければOK
    }

    // HTTPSスキーム(本番用)の検証
    if (uri.scheme == 'https') {
      return _isValidHost(uri.host);
    }

    // その他のスキームは許可しない
    return false;
  }

  /// ホストの妥当性を検証(HTTPSスキーム用)
  bool _isValidHost(String host) {
    // 許可されたホストのリスト
    final allowedHosts = [
      // 本番環境のドメインを追加
      AppConstants.firebaseHostingDomain,
    ];

    return allowedHosts.contains(host);
  }

  @override
  Widget build(BuildContext context) {
    // MediaQueryでデバイスサイズを取得してProviderに反映
    final size = MediaQuery.sizeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(responsiveDimensionsProvider.notifier).updateDimensions(size);
    });

    return MaterialApp.router(
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
      debugShowCheckedModeBanner: false,
      title: 'Testing Sample',
      theme: ThemeData(fontFamily: 'NotoSansJP', appBarTheme: const AppBarTheme()),
      themeMode: ThemeMode.light,
      darkTheme: ThemeData.light(),
      // ローディングオーバーレイとして表示
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox(),
            // ←修正: 初期化中またはディープリンク処理中に表示
            if (_isInitializing || _isProcessingDeepLink)
              const ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator(color: MyColors.greenButton)),
              ),
          ],
        );
      },
    );
  }
}
