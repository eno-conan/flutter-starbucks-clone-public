import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// レスポンシブデザイン用のデバイス情報を管理するクラス
class ResponsiveDimensions {
  const ResponsiveDimensions({required this.width, required this.height});

  final double width;
  final double height;

  /// デバイス幅が384px未満かどうかを判定
  bool get isNarrowDevice => width < 384;

  /// 画像サイズファクター（狭い端末では0.95、通常は1.0）
  double get imageSizeFactor => isNarrowDevice ? 0.95 : 1.0;

  /// 画像と商品名の間の高さ（狭い端末では2.0、通常は4.0）
  double get heightBetweenImageName => isNarrowDevice ? 2.0 : 4.0;

  ResponsiveDimensions copyWith({double? width, double? height}) {
    return ResponsiveDimensions(width: width ?? this.width, height: height ?? this.height);
  }
}

/// レスポンシブディメンションを管理するNotifier
class ResponsiveDimensionsNotifier extends Notifier<ResponsiveDimensions> {
  @override
  ResponsiveDimensions build() {
    // 初期値として基準値を設定
    return const ResponsiveDimensions(width: 384, height: 800);
  }

  /// MediaQueryから取得したサイズで更新
  void updateDimensions(Size size) {
    state = ResponsiveDimensions(width: size.width, height: size.height);
  }
}

final responsiveDimensionsProvider =
    NotifierProvider<ResponsiveDimensionsNotifier, ResponsiveDimensions>(
      ResponsiveDimensionsNotifier.new,
    );
