import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// 位置情報の状態を表すクラス
class LocationState {
  LocationState({this.position, this.isLoading = false, this.error});
  final Position? position;
  final bool isLoading;
  final String? error;

  // 新しい状態を作成するためのコピーメソッド
  LocationState copyWith({Position? position, bool? isLoading, String? error}) {
    return LocationState(
      position: position ?? this.position,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier を使用した実装
class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    // 初期状態を設定
    final initialState = LocationState(isLoading: true);
    // 非同期で位置情報を取得開始
    _initializeLocation();
    return initialState;
  }

  Future<void> _initializeLocation() async {
    try {
      // 位置情報の権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(isLoading: false, error: '位置情報の権限が拒否されました。');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(isLoading: false, error: '位置情報の権限が永久に拒否されました。設定から変更してください。');
        return;
      }

      // 位置情報の取得
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      state = state.copyWith(position: position, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '位置情報の取得に失敗しました: $e');
    }
  }

  // 手動で位置情報を更新するメソッド
  Future<void> refreshLocation() async {
    state = state.copyWith(isLoading: true);
    await _initializeLocation();
  }
}

// グローバルにアクセス可能なProvider
final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
