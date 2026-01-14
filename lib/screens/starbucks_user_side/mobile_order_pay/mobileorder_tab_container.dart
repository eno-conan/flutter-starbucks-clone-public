import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/my_colors.dart';
import '../../../constants/supabase_rpcs.dart';
import '../../../core/models/mobile_order_history.dart';
import '../../../provider/auth_state_provider.dart';
import '../../../provider/connectivity_check_provider.dart';
import '../../../shared/widgets/error_screen.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/splash_screen.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'mobile_order_guest_content.dart';
import 'offline_content.dart';
import 'tab_histories/histories.dart';
import 'tab_order/order.dart';

///ヘッダーのテキスト
const String headerText = 'Mobile Order & Pay';

// モバイルオーダーのTabBarViewコンテナ
class MobileOrderTabContainer extends ConsumerStatefulWidget {
  const MobileOrderTabContainer({super.key, this.initialTabIndex = 0});
  static String routeName = '/mobileorder_pay_top';
  final int initialTabIndex;

  @override
  ConsumerState<MobileOrderTabContainer> createState() => _MobileOrderTabContainerState();
}

class _MobileOrderTabContainerState extends ConsumerState<MobileOrderTabContainer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 読み込み状態
  bool _isLoading = true;
  // 履歴一覧
  List<MobileOrderHistory> userOrders = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);

    // 初期化処理を実行
    _initialize();
  }

  @override
  void didUpdateWidget(MobileOrderTabContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // initialTabIndexが変更された場合、タブを更新
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 初期化処理：データ取得を実行
  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // データ取得
      await _fetchUserOrders();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('初期化中にエラーが発生しました: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserOrders() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            userOrders = [];
            _isLoading = false;
          });
        }
        return;
      }

      final response = await supabase.rpc<List<Map<String, dynamic>>>(
        Rpcs.getUserOrders,
        params: {'p_user_id': userId},
      );

      final orderHistories = (response as List).map((item) {
        return MobileOrderHistory.fromJson(item as Map<String, dynamic>);
      }).toList();

      if (mounted) {
        setState(() {
          userOrders = orderHistories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user orders: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // リフレッシュ処理
  Future<void> _refresh() async {
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    // ネットワーク接続状態を監視
    final nwConnectivity = ref.watch(connectivityCheckProvider);

    return nwConnectivity.when(
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: MyColors.circularProgressIndicatorColor,
            strokeWidth: 4,
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: MyColors.circularProgressIndicatorColor,
            strokeWidth: 4,
          ),
        ),
      ),
      data: (connectivityResults) {
        final isOffline =
            connectivityResults.isEmpty ||
            connectivityResults.every((result) => result == ConnectivityResult.none);

        return isOffline
            ? FixedHeaderCommonComponent(
                isLeadingIcon: false,
                headerText: headerText,
                isFab: false,
                body: OfflineContents(onRefresh: _refresh),
              )
            : _ContentsByAuthState(
                tabController: _tabController,
                onRefreshOrders: _fetchUserOrders,
                userOrders: userOrders,
                isLoading: _isLoading,
              );
      },
    );
  }
}

//認証状態に応じた表示制御
class _ContentsByAuthState extends ConsumerStatefulWidget {
  const _ContentsByAuthState({
    required this.tabController,
    required this.onRefreshOrders,
    required this.userOrders,
    required this.isLoading,
  });

  final TabController tabController;
  final Future<void> Function() onRefreshOrders;
  final List<MobileOrderHistory> userOrders;
  final bool isLoading;

  @override
  ConsumerState<_ContentsByAuthState> createState() => _ContentsByAuthStateState();
}

class _ContentsByAuthStateState extends ConsumerState<_ContentsByAuthState> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.tabController.index;
    widget.tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = widget.tabController.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final Size size = MediaQuery.sizeOf(context);

    return authAsync.when(
      loading: () => const SliverToBoxAdapter(child: SplashScreen()),
      error: (error, _) =>
          SliverToBoxAdapter(child: ErrorScreen(error: 'mobileorder_tab_container:$error')),
      data: (user) => user != null
          ? Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                toolbarHeight: 100,
                title: Column(
                  spacing: 5,
                  crossAxisAlignment: .start,
                  children: const [
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: .end,
                      children: [
                        MyCustomText(text: 'ご利用ガイド', textColor: Colors.green, fontSize: 16),
                      ],
                    ),
                    SizedBox(height: 5),
                    MyCustomText(text: headerText, fontSize: 28),
                  ],
                ),
                automaticallyImplyLeading: false,
                bottom: TabBar(
                  controller: widget.tabController,
                  isScrollable: true,
                  onTap: (index) {},
                  indicatorWeight: 2.5,
                  indicatorAnimation: TabIndicatorAnimation.linear,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorColor: Colors.green,
                  labelColor: Colors.black,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                  unselectedLabelColor: Color(0xFF848484),
                  padding: .all(0),
                  tabAlignment: size.width > 600 ? TabAlignment.center : TabAlignment.start,
                  tabs: const [
                    Tab(text: 'オーダー'),
                    Tab(text: '履歴･再注文'),
                  ],
                ),
              ),
              body: widget.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: MyColors.circularProgressIndicatorColor,
                        strokeWidth: 4,
                      ),
                    )
                  : TabBarView(
                      controller: widget.tabController,
                      children: [
                        MobileOrderPayTabOrder(
                          onRefreshOrders: widget.onRefreshOrders,
                          isVisible: _currentTabIndex == 0, // オーダータブ（インデックス0）が可視の時true
                        ),
                        MobileOrderPayTabHistories(orders: widget.userOrders),
                      ],
                    ),
            )
          : const FixedHeaderCommonComponent(
              isLeadingIcon: false,
              headerText: headerText,
              isFab: true,
              body: MobileOrderGuestContent(),
            ),
    );
  }
}
