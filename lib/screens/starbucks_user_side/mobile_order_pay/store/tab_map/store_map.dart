// ignore_for_file: use_setters_to_change_properties, library_private_types_in_public_api

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../constants/my_colors.dart';
import '../../../../../core/models/store_mobile_order.dart';
import '../../../../../provider/location_state_provider.dart';
import '../../../../../provider/selected_tab_provider.dart';
import '../../../../../services/mobile_order_pay/store/store_cache_service.dart';
import '../../../../../services/mobile_order_pay/store/tab_favorite_stores_service.dart';
import '../../../../../services/mobile_order_pay/store/update_cart_service.dart';
import '../../../../../shared/widgets/buttons/store_select_button.dart';
import '../../mobileorder_tab_container.dart';
import '../../tab_order/pickup_method.dart';

///ピンの画像ファイルパス
const String pinLocationIconPath = 'assets/starbucks/png/destination_map_marker.png';

// マーカーをキャッシュするためのグローバルインスタンス
final markerIconCache = _MarkerIconCache();

// 親ウィジェットから可視性情報を受け取るように変更
class StoreSelectTabMapViewMap extends ConsumerStatefulWidget {
  // 親から渡される可視性情報
  const StoreSelectTabMapViewMap({
    super.key,
    this.isVisible = false,
    required this.onShowSelector,
    this.targetStoreTabMap,
  });
  final bool isVisible;
  final StoreMobileOrder? targetStoreTabMap;
  final VoidCallback onShowSelector;

  @override
  ConsumerState<StoreSelectTabMapViewMap> createState() => _StoreSelectTabMapViewMapState();
}

class _StoreSelectTabMapViewMapState extends ConsumerState<StoreSelectTabMapViewMap> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 可視性がtrueならすぐに初期化(オフラインとの兼ね合いの関係）
    if (widget.isVisible) {
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(StoreSelectTabMapViewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 可視性が変更された場合
    if (widget.isVisible && !_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // アプリのHome画面に戻る
        ref.read(selectedTabProvider.notifier).setTab(0);
      },
      child: _MapContents(
        onShowSelector: widget.onShowSelector,
        targetStoreTabMap: widget.targetStoreTabMap,
      ),
    );
  }
}

// アイコンキャッシュ用クラス
class _MarkerIconCache {
  BitmapDescriptor? _cachedIcon;

  Future<BitmapDescriptor> getMarkerIcon() async {
    if (_cachedIcon != null) {
      return _cachedIcon!;
    }

    try {
      // 方法1: 標準的な方法でアイコンを読み込む
      _cachedIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        pinLocationIconPath,
      );
    } catch (e) {
      try {
        // 方法2: カスタムリサイズしたBitmapを生成
        final ByteData data = await rootBundle.load(pinLocationIconPath);
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final Uint8List resizedMarkerImageBytes = byteData.buffer.asUint8List();
          _cachedIcon = BitmapDescriptor.fromBytes(resizedMarkerImageBytes);
        } else {
          _cachedIcon = BitmapDescriptor.defaultMarker;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error creating custom marker: $e');
        }
        _cachedIcon = BitmapDescriptor.defaultMarker;
      }
    }

    return _cachedIcon!;
  }
}

// GoogleMapの表示
class _MapContents extends ConsumerStatefulWidget {
  const _MapContents({required this.onShowSelector, this.targetStoreTabMap});
  final VoidCallback onShowSelector;
  final StoreMobileOrder? targetStoreTabMap;

  @override
  _MapContentsState createState() => _MapContentsState();
}

class _MapContentsState extends ConsumerState<_MapContents> with AutomaticKeepAliveClientMixin {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final Set<Marker> _markers = {};
  final StoreCacheService cacheService = StoreCacheService();
  final FavoriteStoreService favoriteService = FavoriteStoreService();

  CameraPosition? centerCameraPosition;
  bool _isMapInitialized = false;
  bool _isLoading = true;
  bool _isMarkerLoading = true;

  // 店舗情報取得
  List<StoreMobileOrder> _stores = [];
  Map<String, bool> favoriteStatusMap = {};
  Map<String, int> _storeNumberToIndexMap = {}; // 店舗番号→インデックスマップ（高速検索用）

  // お気に入り処理用
  final Set<String> _pendingRemovalStores = {};
  final Set<String> _pendingAddStores = {};

  int? selectedMarkerIndex;

  // クラスター管理
  Set<ClusterManager> clusterManagers = {
    ClusterManager(
      clusterManagerId: ClusterManagerId('1'),
      onClusterTap: (Cluster cluster) {
        // クラスタータップ時の処理
      },
    ),
  };

  @override
  bool get wantKeepAlive => true; // タブ切り替え時に状態を保持

  @override
  void initState() {
    super.initState();
    // 初期化ロジックを最適化
    _initializeMap();
  }

  @override
  void didUpdateWidget(_MapContents oldWidget) {
    super.didUpdateWidget(oldWidget);

    // targetStoreTabMapの変更を検知して処理
    if (widget.targetStoreTabMap != oldWidget.targetStoreTabMap) {
      _setCurrentPosition();
    }
  }

  @override
  void dispose() {
    // 画面を離れるときに保留中の変更を適用
    _applyPendingChanges();
    super.dispose();
  }

  // 初期化処理を非同期で行う
  Future<void> _initializeMap() async {
    // マップが既に初期化されているが、targetStoreTabMapが変更された場合も処理する
    if (_isMapInitialized) {
      if (widget.targetStoreTabMap != null) {
        await _setCurrentPosition();
      }
      return;
    }

    _isMapInitialized = true;

    // 現在位置を取得
    await _setCurrentPosition();

    // 店舗データを取得
    _getStores().then((_) {
      // マーカーを追加 (アイコンとデータ取得後)
      _addMarkers().then((_) {
        if (mounted) {
          setState(() {
            _isMarkerLoading = false;
            _isLoading = false;
          });

          // マーカーが追加された後に、ターゲットの店舗を選択状態にする
          if (widget.targetStoreTabMap != null) {
            _selectTargetStoreMarker();
          }
        }
      });
    });
  }

  // 保留中の操作を実行する（並列化で高速化）
  Future<void> _applyPendingChanges() async {
    try {
      // 削除と追加を並列実行
      final removalFutures = _pendingRemovalStores
          .map((storeNumber) => favoriteService.removeFavoriteStore(storeNumber))
          .toList();

      final addFutures = _pendingAddStores
          .map((storeNumber) => favoriteService.addFavoriteStore(storeNumber))
          .toList();

      // 削除と追加を同時に実行
      await Future.wait([...removalFutures, ...addFutures]);

      // 実行済みのリストをクリア
      _pendingRemovalStores.clear();
      _pendingAddStores.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('お気に入り処理エラー: $e');
      }
    }
  }

  Future<void> _setCurrentPosition() async {
    final locationState = ref.read(locationProvider);

    // targetStoreTabMapがある場合はそちらを優先
    if (widget.targetStoreTabMap != null &&
        widget.targetStoreTabMap!.latitude != null &&
        widget.targetStoreTabMap!.longitude != null) {
      final storeLocation = LatLng(
        widget.targetStoreTabMap!.latitude! - 0.003, // 少しだけ、上に移動
        widget.targetStoreTabMap!.longitude!,
      );

      final position = CameraPosition(
        target: storeLocation,
        zoom: 15, // 指定された店舗の場合はズームを15に
      );

      setState(() {
        centerCameraPosition = position;
      });

      // マップコントローラーがある場合はカメラを移動
      if (_controller.isCompleted) {
        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(position));

        // 対象の店舗のマーカーを選択状態にする
        _selectTargetStoreMarker();
      }

      return;
    }

    // 通常の現在位置処理
    if (locationState.position != null && _controller.isCompleted) {
      final controller = await _controller.future;
      final userLocation = LatLng(
        locationState.position!.latitude,
        locationState.position!.longitude,
      );
      controller.animateCamera(CameraUpdate.newLatLng(userLocation));
    }

    // 位置情報が利用できない場合のデフォルト位置（東京）
    final position = CameraPosition(
      target: locationState.position != null
          ? LatLng(locationState.position!.latitude, locationState.position!.longitude)
          : const LatLng(35.6812, 139.7671),
      zoom: 14,
    );
    setState(() {
      centerCameraPosition = position;
    });
  }

  // 対象店舗のマーカーを選択状態にするメソッド（MapキャッシュでO(1)検索）
  void _selectTargetStoreMarker() {
    if (widget.targetStoreTabMap == null || _stores.isEmpty) {
      return;
    }

    // Mapキャッシュを使用してO(1)でインデックスを取得
    final targetStoreNumber = widget.targetStoreTabMap!.storeNumber;
    final index = _storeNumberToIndexMap[targetStoreNumber];

    if (index != null) {
      setState(() {
        selectedMarkerIndex = index;
      });
    }
  }

  Future<void> _getStores() async {
    try {
      // キャッシュからデータ取得（最適化：非同期処理を効率化）
      final storeListJson = await cacheService.getData('stores');

      if (storeListJson.isEmpty) {
        setState(() {
          _stores = [];
        });
        return;
      }

      // リストを作成（効率化：変換処理を最適化）
      final List<StoreMobileOrder> allStores = await compute(_parseStoreData, storeListJson);

      // お気に入りステータスを非同期で別途取得
      final favoriteMap = await _getFavoriteStatusMap(allStores);

      if (mounted) {
        setState(() {
          _stores = allStores;
          favoriteStatusMap = favoriteMap;

          // 店舗番号→インデックスのマップを構築（O(1)検索用）
          _storeNumberToIndexMap = {
            for (int i = 0; i < allStores.length; i++) allStores[i].storeNumber: i,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stores = [];
        });
      }
      debugPrint('Error loading stores: $e');
    }
  }

  // バックグラウンドで店舗データを解析（isolateで処理）
  static List<StoreMobileOrder> _parseStoreData(List<dynamic> storeListJson) {
    return storeListJson
        .map((json) => StoreMobileOrder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // お気に入りステータスを取得（並列化で高速化）
  Future<Map<String, bool>> _getFavoriteStatusMap(List<StoreMobileOrder> stores) async {
    final Map<String, bool> resultMap = {};

    // 全店舗のお気に入りステータス取得を並列実行
    final futures = stores.where((store) => store.storeNumber.isNotEmpty).map((store) async {
      try {
        final isFavorite = await favoriteService.isStoreFavorite(store.storeNumber);
        return MapEntry(store.storeNumber, isFavorite);
      } catch (e) {
        return MapEntry(store.storeNumber, false);
      }
    }).toList();

    final results = await Future.wait(futures);
    for (final entry in results) {
      resultMap[entry.key] = entry.value;
    }

    return resultMap;
  }

  // マーカーを追加する処理 (最適化済み)
  Future<void> _addMarkers() async {
    if (_stores.isEmpty) {
      return;
    }

    // マーカーアイコンをキャッシュから取得
    final markerIcon = await markerIconCache.getMarkerIcon();

    // マーカーを作成
    final markers = <Marker>{};
    for (int i = 0; i < _stores.length; i++) {
      final store = _stores[i];
      // 無効な座標の場合はスキップ
      if ((store.latitude == null || store.longitude == null) ||
          (store.latitude == 0.0 && store.longitude == 0.0)) {
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId('marker_$i'),
          position: LatLng(store.latitude!, store.longitude!),
          icon: markerIcon,
          clusterManagerId: ClusterManagerId('1'),
          onTap: () {
            // マーカータップ時に選択状態にする
            setState(() {
              selectedMarkerIndex = i;
            });
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });
    }
  }

  Widget _buildInfoPanel() {
    if (selectedMarkerIndex == null || selectedMarkerIndex! >= _stores.length) {
      return const SizedBox.shrink();
    }

    final store = _stores[selectedMarkerIndex!];
    final placeName = store.storeName;
    final address = store.address;

    return RepaintBoundary(
      child: Container(
        padding: const .all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
          // BoxShadowのblurRadiusを除去してRaster負荷を軽減
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(placeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(address ?? '', style: const TextStyle(fontSize: 14)),
            const Spacer(),
            StoreSelectButton(
              store: store,
              onPressed: () async {
                // カートテーブルデータを追加/挿入
                try {
                  await CartService.addToCartAndNavigate(store: store);
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    context.go(
                      '${MobileOrderTabContainer.routeName}${MobileOrderPickupMethod.routeName}',
                    );
                  }
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Mapからの注文店舗設定時エラー: $e');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // マップの読み込み中は操作できないことを示すインジケータを表示
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: MyColors.greenButton)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                centerCameraPosition ??
                const CameraPosition(
                  target: LatLng(35.6812, 139.7671), // Default to Tokyo
                  zoom: 14,
                ),
            myLocationEnabled: true, // 現在地表示
            myLocationButtonEnabled: false, // 現在地へ移動するボタン非表示
            zoomControlsEnabled: false, // +/−ボタン非表示
            mapToolbarEnabled: false, // ツールバー非表示
            markers: _markers,
            onMapCreated: (controller) {
              _controller.complete(controller);

              // コントローラが準備できたら、必要に応じて位置を更新
              if (widget.targetStoreTabMap != null) {
                _setCurrentPosition();
              }
            },
            onTap: (_) {
              // マーカー以外をタップしたらパネルを非表示に
              setState(() => selectedMarkerIndex = null);
            },
            clusterManagers: clusterManagers,
          ),

          // マーカー読み込み中の場合はインジケータを表示
          if (_isMarkerLoading)
            const Positioned(
              bottom: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: .all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MyColors.greenButton,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('マーカー読み込み中...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // 下から出てくる情報エリア
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: selectedMarkerIndex != null ? 0 : -200, // 表示・非表示を制御
            left: 0,
            right: 0,
            height: 200,
            child: _buildInfoPanel(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisAlignment: .end,
          crossAxisAlignment: .end,
          children: [
            // 検索ボタン
            FloatingActionButton(
              heroTag: 'searchButton',
              mini: true,
              elevation: 1,
              shape: const CircleBorder(),
              onPressed: () {
                // 店舗検索へ
                widget.onShowSelector();
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.search_outlined, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // 現在地ボタン
            FloatingActionButton(
              heroTag: 'currentLocationButton',
              mini: true,
              elevation: 1,
              shape: const CircleBorder(),
              onPressed: () async {
                final locationState = ref.read(locationProvider);
                if (locationState.position != null && _controller.isCompleted) {
                  final controller = await _controller.future;
                  final userLocation = LatLng(
                    locationState.position!.latitude,
                    locationState.position!.longitude,
                  );
                  controller.animateCamera(CameraUpdate.newLatLng(userLocation));
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.near_me_outlined, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
