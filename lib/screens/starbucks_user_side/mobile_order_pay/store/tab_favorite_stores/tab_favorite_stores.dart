import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../constants/my_colors.dart';
import '../../../../../core/models/store_mobile_order.dart';
import '../../../../../services/mobile_order_pay/store/store_cache_service.dart';
import '../../../../../services/mobile_order_pay/store/tab_favorite_stores_service.dart';
import '../../../../../services/mobile_order_pay/store/update_cart_service.dart';
import '../../../../../shared/widgets/buttons/store_select_button.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import '../../mobileorder_tab_container.dart';
import '../../tab_order/pickup_method.dart';
import '../tab_close_distance_store/tab_close_distance_store.dart';

///店舗選択：お気に入り店舗
class StoreSelectTabFavoriteStore extends ConsumerStatefulWidget {
  const StoreSelectTabFavoriteStore({super.key});
  static String routeName = '/store_select_favorite_store';

  @override
  ConsumerState<StoreSelectTabFavoriteStore> createState() => _StoreSelectTabFavoriteStoreState();
}

class _StoreSelectTabFavoriteStoreState extends ConsumerState<StoreSelectTabFavoriteStore> {
  final StoreCacheService cacheService = StoreCacheService();
  List<StoreMobileOrder> _stores = [];
  Map<String, bool> favoriteStatusMap = {}; // storeNumberをキーにお気に入りステータスを管理
  bool _isLoading = true;
  final FavoriteStoreService favoriteService = FavoriteStoreService();

  // 削除予定のお気に入り店舗IDのリスト
  final Set<String> _pendingRemovalStores = {};
  // 追加予定のお気に入り店舗IDのリスト
  final Set<String> _pendingAddStores = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 全店舗データを取得してStoreMobileOrderに変換
      final storeListJson = await cacheService.getData('stores');
      final List<StoreMobileOrder> allStores = storeListJson
          .map((json) => StoreMobileOrder.fromJson(json))
          .toList();

      // 各店舗のお気に入りステータスを並列取得（高速化）
      favoriteStatusMap = {};
      final futures = allStores.where((store) => store.storeNumber.isNotEmpty).map((store) async {
        final isFavorite = await favoriteService.isStoreFavorite(store.storeNumber);
        return MapEntry(store.storeNumber, isFavorite);
      }).toList();

      final results = await Future.wait(futures);
      for (final entry in results) {
        favoriteStatusMap[entry.key] = entry.value;
      }

      // 保留中の操作を反映（UIへの一時的な反映）
      for (final storeNumber in _pendingRemovalStores) {
        favoriteStatusMap[storeNumber] = false;
      }

      for (final storeNumber in _pendingAddStores) {
        favoriteStatusMap[storeNumber] = true;
      }

      // お気に入りの店舗だけをフィルタリング（保留中の削除を考慮）
      final List<StoreMobileOrder> favoriteStores = allStores.where((store) {
        final storeNumber = store.storeNumber;
        final isFavorite = favoriteStatusMap[storeNumber] ?? false;
        // 保留中の削除に含まれていても、UIには表示する
        return isFavorite || _pendingRemovalStores.contains(storeNumber);
      }).toList();

      setState(() {
        _stores = favoriteStores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // エラー処理（実際の実装ではスナックバーなどで表示するとよい）
      debugPrint('Error loading favorite stores: $e');
    }
  }

  // お気に入りの切り替え（即時処理せず状態だけ変更）
  void _toggleFavorite(StoreMobileOrder store) {
    final storeNumber = store.storeNumber;
    final isFavorite = favoriteStatusMap[storeNumber] ?? false;

    setState(() {
      if (isFavorite) {
        // お気に入りから削除予定に追加
        _pendingRemovalStores.add(storeNumber);
        // もし追加予定にあれば、そこから削除
        _pendingAddStores.remove(storeNumber);
      } else {
        // お気に入りに追加予定に追加
        _pendingAddStores.add(storeNumber);
        // もし削除予定にあれば、そこから削除
        _pendingRemovalStores.remove(storeNumber);
      }

      // UIの状態を更新（実際の永続化はまだ行わない）
      favoriteStatusMap[storeNumber] = !isFavorite;
    });

    // お気に入りリストの表示更新（ただし永続化はまだしない）
    _refreshList();
  }

  // リストの表示を更新する（データロードはしない）
  void _refreshList() {
    setState(() {
      // 現在の_storesを更新する必要がなければ何もしない
    });
  }

  // 保留中の操作を実行する
  Future<void> _applyPendingChanges() async {
    try {
      // 削除予定のものを削除
      for (final storeNumber in _pendingRemovalStores) {
        await favoriteService.removeFavoriteStore(storeNumber);
      }

      // 追加予定のものを追加
      for (final storeNumber in _pendingAddStores) {
        await favoriteService.addFavoriteStore(storeNumber);
      }

      // 実行済みのリストをクリア
      _pendingRemovalStores.clear();
      _pendingAddStores.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('お気に入り処理エラー: $e');
      }
    }
  }

  @override
  void dispose() {
    // 画面を離れるときに保留中の変更を適用
    _applyPendingChanges();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MyColors.greenButton))
          : _stores.isEmpty
          ? _buildEmptyFavoriteView()
          : CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final store = _stores[index];
                    final isFavorite = favoriteStatusMap[store.storeNumber] ?? false;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: .start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.symmetric(
                              horizontal: BorderSide(color: MyColors.settingDivider, width: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            child: Column(
                              crossAxisAlignment: .start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: .start,
                                        children: [
                                          const SizedBox(height: 3),
                                          MyCustomText(
                                            text: store.storeName,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          MyCustomText(
                                            text: store.address ?? '',
                                            fontSize: 14,
                                            textColor: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _toggleFavorite(store),
                                      child: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border_sharp,
                                        color: isFavorite ? MyColors.greenButton : null,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.info_outline),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                RowTimeForWaitAndLastOrderTime(
                                  waitTime: '約5～10分後',
                                  lastOrderTime: store.formattedClosingTime ?? '',
                                ),
                                const SizedBox(height: 12),
                                StoreSelectButton(
                                  store: store,
                                  distance: store.formattedDistanceKm ?? '',
                                  onPressed: () async {
                                    // カートテーブルデータを追加/挿入
                                    try {
                                      await CartService.addToCartAndNavigate(store: store);
                                      if (context.mounted) {
                                        context.go(
                                          '${MobileOrderTabContainer.routeName}${MobileOrderPickupMethod.routeName}',
                                        );
                                      }
                                    } catch (e) {
                                      if (kDebugMode) {
                                        debugPrint('お気に入り店舗からの注文店舗設定時エラー: $e');
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }, childCount: _stores.length),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyFavoriteView() {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        children: const [
          Icon(Icons.favorite_border, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          MyCustomText(text: 'お気に入りの店舗がありません', fontSize: 16, textColor: Colors.grey),
          SizedBox(height: 8),
          MyCustomText(
            text: '店舗リストでハートアイコンをタップして\nお気に入りに追加してください',
            fontSize: 14,
            textColor: Colors.grey,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
