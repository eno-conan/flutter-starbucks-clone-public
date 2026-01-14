import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/supabase_rpcs.dart';
import '../../../provider/auth_state_provider.dart';
import '../../../provider/connectivity_check_provider.dart';
import '../../../services/home/star_points_cache_service.dart';
import '../../../shared/helpers/timezone_util.dart';
import '../../../shared/widgets/dialogs/offline_dialog.dart';
import '../../../shared/widgets/offline.dart';
import '../../../shared/widgets/signup_signin_floating_acttion_button.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'widgets/mobileorder.dart';
import 'widgets/navigation_bar.dart';
import 'widgets/new_product.dart';
import 'widgets/star_reward.dart';
import 'widgets/time_limited_widget.dart';

// https://karthikponnam.medium.com/custom-scroll-view-in-flutter-a-guide-f0b57226fc5d
/// スタバのアプリなどにみられるヘッダー部分の折りたたみ
/// ホーム画面
class Home extends ConsumerStatefulWidget {
  const Home({super.key});
  static String routeName = '/starbucks_top_page';

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  @override
  void initState() {
    super.initState();
    // 非同期処理を別メソッドに移動し、initState内で呼び出す
    _initializeData();
  }

  // 非同期処理を行う別メソッド
  Future<void> _initializeData() async {
    // initialAuthStateProvider を使用
    final authAsync = ref.read(initialAuthStateProvider);
    if (authAsync.hasValue) {
      final user = authAsync.value;
      if (user != null) {
        await _getStarPoints();
      }
    }
  }

  Future<void> _getStarPoints() async {
    final StarPointsCacheService starPointsCacheService = StarPointsCacheService();
    starPointsCacheService.refreshData(Rpcs.getTotalPointsWithExpirationFlagZero);
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getGreeting() {
    // 現在のUTC時刻を取得
    final now = DateTime.now().toUtc();

    // ローカル時刻に変換
    final localTime = TimezoneUtil.toLocalTime(now);
    final hour = localTime.hour;

    if (hour >= 5 && hour < 10) {
      return 'おはようございます';
    } else if (hour >= 10 && hour < 17) {
      return 'こんにちは';
    } else {
      return 'こんばんは';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nwConnectivity = ref.watch(connectivityCheckProvider);
    nwConnectivity.when(
      loading: () {
        return SizedBox();
      },
      error: (error, stackTrace) {
        return const OfflinePage();
      },
      data: (data) {
        if (data[0] == ConnectivityResult.none) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showOfflineDialog(context);
          });
        }
      },
    );
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                _SliverAppBar(greeting: _getGreeting()),
                const _PinnedNavigationBar(),
              ];
            },
            body: const _MainContent(),
          ),
        ),
        floatingActionButton: const SignupSignInFloatingActionButton(),
      ),
    );
  }
}

class _SliverAppBar extends StatelessWidget {
  const _SliverAppBar({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      key: const ValueKey('top_page_sliver_app_bar'),
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      expandedHeight: 100, // Set the height of the header when expanded
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: MyCustomText(text: greeting, fontSize: 28, fontWeight: FontWeight.bold),
      ),
      titleSpacing: 0,
    );
  }
}

class _PinnedNavigationBar extends StatelessWidget {
  const _PinnedNavigationBar();

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverPersistentHeaderDelegate(
        child: const RepaintBoundary(child: HomeNavigationSection()),
        minHeight: 60.0,
        maxHeight: 60.0,
      ),
    );
  }
}

class _MainContent extends ConsumerWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ネットワーク接続状況に応じた表示
    final nwConnectivity = ref.watch(connectivityCheckProvider);

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            RepaintBoundary(
              child: nwConnectivity.when(
                loading: () {
                  return SizedBox();
                },
                error: (error, stackTrace) {
                  return const OfflinePage();
                },
                data: (data) {
                  if (data[0] == ConnectivityResult.none) {
                    return const OfflinePage();
                  } else {
                    return HomeStarRewardSection();
                  }
                },
              ),
            ),
            const RepaintBoundary(child: TimeLimitedWidget()),
            const RepaintBoundary(child: HomeMobileOrderSection()),
            const RepaintBoundary(child: HomeNewProductSection()),
            const RewardCard(
              title: 'カスタマイズ無料チケット',
              description: '期限: 2024年2月5日',
              icon: Icons.local_cafe,
            ),
            const RewardCard(
              title: 'ドリンク無料チケット',
              description: '期限: 2024年2月10日',
              icon: Icons.free_breakfast,
            ),
          ]),
        ),
      ],
    );
  }
}

/// リワードカード
class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.title, required this.description, required this.icon});
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

///固定表示
class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SliverPersistentHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });
  final Widget child;
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
