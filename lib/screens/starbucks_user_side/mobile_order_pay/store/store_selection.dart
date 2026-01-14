import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/my_colors.dart';
import '../../../../core/models/store_mobile_order.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../mobileorder_tab_container.dart';
import 'search.dart';
import 'tab_close_distance_store/tab_close_distance_store.dart';
import 'tab_favorite_stores/tab_favorite_stores.dart';
import 'tab_map/store_map.dart';

/// 店舗選択
class StoreSelect extends StatefulWidget {
  const StoreSelect({super.key});
  static String routeName = '/store_select_top';

  @override
  State<StoreSelect> createState() => _StoreSelectState();
}

class _StoreSelectState extends State<StoreSelect> {
  // メイン変数
  StoreMobileOrder? targetStoreTabMap;
  // 現在表示中のUI (メインUI:true, 値選択UI:false)
  bool isMainView = true;

  // キー追加：GoogleMapの状態を保持するため
  final _mapKey = GlobalKey();

  // メイン画面に戻る
  void backMain() {
    setState(() {
      isMainView = true;
    });
  }

  // 現在地を更新
  void updateValue(StoreMobileOrder newValue) {
    setState(() {
      targetStoreTabMap = newValue;
      isMainView = true;
    });
  }

  // 店舗検索画面を表示
  void showValueSelector() {
    setState(() {
      isMainView = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // メインビュー（常に構築しておき、表示・非表示を切り替える）
            Visibility(
              visible: isMainView,
              maintainState: true, // これが重要：非表示時も状態を維持
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (context.mounted) {
                                  context.go(MobileOrderTabContainer.routeName);
                                }
                              },
                              child: Icon(Icons.arrow_back_ios),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(children: [MyCustomText(text: 'Store Select', fontSize: 28)]),
                      ],
                    ),
                  ),
                  _TabControllerWidget(
                    key: _mapKey,
                    targetStoreTabMap: targetStoreTabMap,
                    onShowSelector: showValueSelector,
                  ),
                ],
              ),
            ),

            // 検索ビュー
            Visibility(
              visible: !isMainView,
              child: StoreSearch(
                onValueSelected: updateValue,
                backMain: backMain,
                isMainView: isMainView,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///タブ管理
class _TabControllerWidget extends StatefulWidget {
  const _TabControllerWidget({super.key, this.targetStoreTabMap, required this.onShowSelector});
  final StoreMobileOrder? targetStoreTabMap;
  final VoidCallback onShowSelector;

  @override
  State<_TabControllerWidget> createState() => _TabControllerWidgetState();
}

class _TabControllerWidgetState extends State<_TabControllerWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  // AutomaticKeepAliveClientMixin用のオーバーライド
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AutomaticKeepAliveClientMixinを使用するときは必ずsuperを呼ぶ
    super.build(context);

    final Size size = MediaQuery.sizeOf(context);
    return Expanded(
      child: Column(
        children: [
          ColoredBox(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorWeight: 2.5,
              indicatorAnimation: TabIndicatorAnimation.linear,
              indicatorSize: TabBarIndicatorSize.tab, //これだ！（端っこまでIndicator表示）
              indicatorColor: Colors.green,
              labelColor: Colors.black,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
              unselectedLabelColor: Color(0xFF848484),
              padding: .all(0),
              tabAlignment: size.width > 600 ? TabAlignment.center : TabAlignment.start,
              tabs: const [
                Tab(text: 'MAP'),
                Tab(text: '近くの店舗'),
                Tab(text: 'お気に入り'),
              ],
            ),
          ),
          Flexible(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                //Map - 状態を保持するようにKeepAliveを追加
                ColoredBox(
                  color: MyColors.backgroundGrey,
                  child: KeepAliveWrapper(
                    child: StoreSelectTabMapViewMap(
                      targetStoreTabMap: widget.targetStoreTabMap,
                      onShowSelector: widget.onShowSelector,
                    ),
                  ),
                ),
                //周辺店舗
                ColoredBox(
                  color: MyColors.backgroundGrey,
                  child: KeepAliveWrapper(child: StoreSelectTabCloseDistanceStore()),
                ),
                // お気に入り店舗
                ColoredBox(color: MyColors.backgroundGrey, child: StoreSelectTabFavoriteStore()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ウィジェットの状態を維持するためのラッパークラス
class KeepAliveWrapper extends StatefulWidget {
  const KeepAliveWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
