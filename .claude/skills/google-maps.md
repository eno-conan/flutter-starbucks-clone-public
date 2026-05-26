---
description: Google Maps カスタムマーカー実装ガイド（Flutter）
---

## Google Maps カスタムマーカーは PNG を使う

**SVG は使わない。**
`flutter_svg` で SVG をラスタライズして `BitmapDescriptor.bytes()` に渡す方法は動作するが、次の問題が残りやすい。

- ズーム時にマーカーのサイズ・アンカーポイントがズレる
- `imagePixelRatio` を端末 DPR に合わせて手動管理する必要がある
- コードが複雑（ラスタライズ → PNG エンコード → bytes 渡し）

**PNG アセットを直接使う方が安全でシンプル。**

---

## 実装例：PNG マーカーの読み込みとキャッシュ

```dart
class _MarkerIconCache {
  BitmapDescriptor? _cachedIcon;

  Future<BitmapDescriptor> getMarkerIcon(BuildContext context) async {
    if (_cachedIcon != null) return _cachedIcon!;
    _cachedIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
      'assets/images/marker_pin.png',
    );
    return _cachedIcon!;
  }
}
```

- `devicePixelRatio` を渡すことで DPR が Google Maps に正しく伝わりズーム連動が正常になる
- 複数マーカーを生成する前に一度だけ読み込んでキャッシュする

## Marker 設定例

```dart
Marker(
  markerId: MarkerId('marker_$i'),
  position: LatLng(lat, lng),
  icon: markerIcon,
  anchor: const Offset(0.5, 1.0), // ピン先端を座標に合わせる場合
)
```

## PNG ファイルの推奨サイズ

Flutter の解像度対応フォルダ構成を使うと `ImageConfiguration` が自動で適切な解像度を選ぶ。

```
assets/images/
  marker_pin.png        # 1x 基準
  2.0x/marker_pin.png   # 2x
  3.0x/marker_pin.png   # 3x
```

| マーカー種別 | 推奨サイズ（1x） |
|------------|----------------|
| 通常（丸型） | 36×36 dp |
| ピン型 | 30×44 dp（アンカー `Offset(0.5, 1.0)`） |
