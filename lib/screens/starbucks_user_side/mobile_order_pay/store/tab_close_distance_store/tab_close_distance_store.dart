import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../constants/my_colors.dart';
import '../../../../../core/models/store_mobile_order.dart';
import '../../../../../data/repository/store.dart';
import '../../../../../provider/location_state_provider.dart';
import '../../../../../services/mobile_order_pay/store/update_cart_service.dart';
import '../../../../../shared/widgets/buttons/store_select_button.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import '../../mobileorder_tab_container.dart';
import '../../tab_order/pickup_method.dart';

///店舗選択：周辺店舗
class StoreSelectTabCloseDistanceStore extends ConsumerStatefulWidget {
  const StoreSelectTabCloseDistanceStore({super.key});
  static String routeName = '/store_select_close_distance_store';

  @override
  ConsumerState<StoreSelectTabCloseDistanceStore> createState() =>
      _StoreSelectTabCloseDistanceStoreState();
}

class _StoreSelectTabCloseDistanceStoreState extends ConsumerState<StoreSelectTabCloseDistanceStore>
    with AutomaticKeepAliveClientMixin {
  late final StoreRepository _storeRepository;
  List<StoreMobileOrder> _stores = [];
  Map<String, bool> _favoriteStores = {};
  bool _isLoading = true;
  // String _errorMessage = '';

  @override
  bool get wantKeepAlive => true; // タブ切り替え時に状態を保持

  @override
  void initState() {
    super.initState();
    _storeRepository = StoreRepository(Supabase.instance.client);
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get favorite store numbers first
      final favoriteStoreNumbers = await _storeRepository.getFavoriteStoreNumbers();

      // Create a map for quick lookups
      final Map<String, bool> favoriteMap = {};
      for (final storeNumber in favoriteStoreNumbers) {
        favoriteMap[storeNumber] = true;
      }

      // Supabaseから店舗情報を取得
      final locationState = ref.read(locationProvider);
      if (locationState.position != null) {
        final stores = await _storeRepository.getNearbyStores(
          locationState.position!.latitude,
          locationState.position!.longitude,
        );
        if (stores.isEmpty) {
          if (kDebugMode) {
            debugPrint('周辺店舗がありません');
          }
        }
        setState(() {
          _stores = stores;
          _favoriteStores = favoriteMap;
          _isLoading = false;
        });
      } else {
        if (kDebugMode) {
          debugPrint('現在地の値が空');
        }
      }
    } catch (e) {
      setState(() {
        // _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// お気に入り店舗の追加・削除
  Future<void> _toggleFavorite(StoreMobileOrder store) async {
    final storeNumber = store.storeNumber;
    final isFavorite = _favoriteStores[storeNumber] ?? false;

    try {
      if (isFavorite) {
        await _storeRepository.removeFavoriteStore(storeNumber);
      } else {
        await _storeRepository.addFavoriteStore(storeNumber);
      }

      // Update state
      setState(() {
        _favoriteStores[storeNumber] = !isFavorite;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('お気に入りの更新中にエラーが発生しました: $e');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MyColors.greenButton))
          : CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final store = _stores[index];
                    final isFavorite = _favoriteStores[store.storeNumber] ?? false;

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
                                RowStoreNameAndIcons(
                                  name: store.storeName,
                                  address: store.address ?? '',
                                  isFavorite: isFavorite,
                                  onFavoriteToggle: () => _toggleFavorite(store),
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
                                        debugPrint('近隣店舗の注文店舗設定時にエラー: $e');
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
}

///店舗名・アイコン
class RowStoreNameAndIcons extends StatelessWidget {
  const RowStoreNameAndIcons({
    super.key,
    required this.name,
    required this.address,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });
  final String name;
  final String address;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 3),
              MyCustomText(text: name, fontSize: 16, fontWeight: FontWeight.bold),
              MyCustomText(text: address, fontSize: 14, textColor: Colors.black54),
            ],
          ),
        ),
        InkWell(
          onTap: onFavoriteToggle,
          child: Padding(
            padding: const .all(8.0),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border_sharp,
              color: isFavorite ? MyColors.greenButton : null,
            ),
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.info_outline),
      ],
    );
  }
}

///注文品・アイコン
class RowTimeForWaitAndLastOrderTime extends StatelessWidget {
  const RowTimeForWaitAndLastOrderTime({
    super.key,
    required this.waitTime,
    required this.lastOrderTime,
  });
  final String waitTime;
  final String lastOrderTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: .start,
          children: [
            MyCustomText(text: '受取時間 $waitTime', fontSize: 16),
            MyCustomText(text: '(受付終了時間 $lastOrderTime)', fontSize: 12, textColor: Colors.black54),
          ],
        ),
      ],
    );
  }
}
