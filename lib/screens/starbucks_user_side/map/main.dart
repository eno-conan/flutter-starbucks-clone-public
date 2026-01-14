// ignore_for_file: use_setters_to_change_properties, library_private_types_in_public_api
import 'dart:async';
import 'dart:ui' as ui;

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../provider/location_state_provider.dart';
import '../../../provider/selected_tab_provider.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import 'bubble.dart';

const String pinLocationIconPath = 'assets/starbucks/png/store_marker.png';

final markerIconCache = _MarkerIconCache();

// 親ウィジェットから可視性情報を受け取るように変更
// 親ウィジェットから可視性情報を受け取るように変更
class Store extends ConsumerStatefulWidget {
  const Store({super.key}); // isVisibleパラメータを削除

  static String routeName = '/starbucks_map_top_page';

  @override
  ConsumerState<Store> createState() => _StoreState();
}

class _StoreState extends ConsumerState<Store> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // navigationShellから現在のタブインデックスを取得
    final navigationShell = StatefulNavigationShell.of(context);
    final isVisible = navigationShell.currentIndex == 2; // Storeタブのインデックスは2

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        ref.read(selectedTabProvider.notifier).setTab(0);
      },
      child: FixedHeaderCommonComponent(
        isLeadingIcon: false,
        headerText: 'Stores',
        isFab: false,
        body: _MapScreen(isVisible: isVisible), // 動的に可視性を渡す
      ),
    );
  }
}

// 東京周辺のスターバックス店舗を想定したマーカー
final List<Map<String, dynamic>> storeData = [
  {'id': 'nihonbashi_takashimaya', 'name': '日本橋高島屋店', 'lat': 35.6802, 'lng': 139.7736},
  {'id': 'shibuya_scramble', 'name': '渋谷スカランブル店', 'lat': 35.6598, 'lng': 139.7006},
  {'id': 'shinjuku_southern_terrace', 'name': '新宿サザンテラス店', 'lat': 35.6870, 'lng': 139.7003},
  {'id': 'ginza_marronnier_gate', 'name': '銀座マロニエゲート店', 'lat': 35.6719, 'lng': 139.7648},
  {'id': 'kinshicho_termina', 'name': '錦糸町テルミナ店', 'lat': 35.6969, 'lng': 139.8147},
  {'id': 'roppongi_hills', 'name': '六本木ヒルズ店', 'lat': 35.6606, 'lng': 139.7298},
  {'id': 'akihabara_station', 'name': '秋葉原駅前店', 'lat': 35.6984, 'lng': 139.7731},
  {'id': 'ueno_park', 'name': '上野公園店', 'lat': 35.7148, 'lng': 139.7753},
  {'id': 'asakusa_kaminarimon', 'name': '浅草雷門店', 'lat': 35.7106, 'lng': 139.7967},
  {'id': 'tokyo_station_marunouchi', 'name': '東京駅丸の内店', 'lat': 35.6812, 'lng': 139.7671},
];

// _MapScreenは単純化
class _MapScreen extends ConsumerStatefulWidget {
  const _MapScreen({required this.isVisible});

  final bool isVisible;

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<_MapScreen> with AutomaticKeepAliveClientMixin {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  final _customInfoWindowController = CustomInfoWindowController();

  Set<ClusterManager> clusterManagers = {
    ClusterManager(clusterManagerId: ClusterManagerId('1'), onClusterTap: (Cluster cluster) {}),
  };

  @override
  bool get wantKeepAlive => true; // タブ切り替え時に状態を保持

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  // didUpdateWidgetを追加して可視性の変化を検知
  @override
  void didUpdateWidget(_MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // タブの可視性が変わったときの処理
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        // タブが表示されたとき：位置情報を再有効化
        _enableLocation();
      } else {
        // タブが非表示になったとき：位置情報を無効化
        _disableLocation();
      }
    }
  }

  // 位置情報を有効化
  void _enableLocation() {
    if (mapController != null && mounted) {
      mapController!.setMapStyle(null); // マップスタイルをリセット（位置情報を再描画）
    }
  }

  // 位置情報を無効化
  void _disableLocation() {
    // 特に処理は不要（myLocationEnabledがfalseになるため）
  }

  Future<void> _createMarkers() async {
    final markerIcon = await markerIconCache.getMarkerIcon();

    const batchSize = 5;
    final List<Marker> newMarkers = [];

    for (int i = 0; i < storeData.length; i += batchSize) {
      final batch = storeData.skip(i).take(batchSize);

      final batchMarkers = batch
          .map(
            (store) => Marker(
              markerId: MarkerId(store['id'] as String),
              position: LatLng(store['lat'] as double, store['lng'] as double),
              icon: markerIcon,
              clusterManagerId: ClusterManagerId('1'),
              onTap: () {
                _customInfoWindowController.addInfoWindow!(
                  _CustomInfoWindowContent(storeName: store['name'] as String),
                  LatLng((store['lat'] as double) - 0.004, store['lng'] as double),
                );
              },
            ),
          )
          .toList();

      newMarkers.addAll(batchMarkers);

      if (mounted) {
        setState(() {
          markers = Set.from(newMarkers);
        });
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    _customInfoWindowController.dispose(); // これも追加
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final locationState = ref.watch(locationProvider);

    final LatLng center = locationState.position != null
        ? LatLng(locationState.position!.latitude, locationState.position!.longitude)
        : const LatLng(35.6812, 139.7671);

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(target: center, zoom: 15.0),
          myLocationEnabled: widget.isVisible, // タブ表示時のみ有効
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          markers: markers,
          clusterManagers: clusterManagers,
          onTap: (LatLng position) {
            _customInfoWindowController.hideInfoWindow!();
          },
          onCameraMove: (position) {
            _customInfoWindowController.onCameraMove!();
          },
        ),
        CustomInfoWindow(
          controller: _customInfoWindowController,
          height: 200,
          width: MediaQuery.sizeOf(context).width - 32,
        ),
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _customInfoWindowController.googleMapController = controller;
    if (kDebugMode) {
      debugPrint('Map created successfully');
    }
  }
}

// InfoWindowのコンテンツをカスタマイズ
class _CustomInfoWindowContent extends StatelessWidget {
  const _CustomInfoWindowContent({required this.storeName});
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: () async {
        if (kDebugMode) {
          debugPrint('Overlay container tapped - navigating to Google');
        }
        // 実装中：Google.comに遷移
        try {
          final Uri url = Uri.parse('https://www.google.com');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (kDebugMode) {
              debugPrint('Could not launch URL');
            }
          }
          // _selectedMarkerId = store['id'];
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error launching URL: $e');
          }
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenWidth * 0.7,
          constraints: BoxConstraints(
            maxWidth: screenWidth - 20, // 最小マージン20px
            maxHeight: 200,
          ),
          child: Bubble(storeName: storeName),
        ),
      ),
    );
  }
}

class _MarkerIconCache {
  BitmapDescriptor? _cachedIcon;

  Future<BitmapDescriptor> getMarkerIcon() async {
    if (_cachedIcon != null) {
      return _cachedIcon!;
    }

    try {
      // 方法1: 標準的な方法でアイコンを読み込む
      _cachedIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.0),
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
