# Flutterパフォーマンス最適化完全ガイド

## 概要

- Flutter アプリは、適切な実装で 60fps 以上の滑らかな動作を実現できる。
- 性能を維持するには、開発者がベストプラクティスを理解していることが不可欠。
- このガイドの範囲:
    - パフォーマンス測定
    - Firebase 監視
    - 具体的な最適化手法
    - トラブルシューティング
- 対象は中級者から上級者。コード例を多く載せている（コードは折り畳み）。
- 扱う手法:
    - Flutter DevTools による詳細分析
    - Firebase Performance Monitoring による本番監視
    - メモリリーク検出
    - 起動時間の改善
    - ビルドサイズの削減

!!! warning "原則: 測定してから最適化する（メトリクス駆動）"
    - プロファイルモードでの実機テストが必須。
    - デバッグモードでの測定は、意図的に犠牲にされたパフォーマンスを示す。そのため誤った結果を導く。

## パフォーマンス測定の基礎と環境セットアップ

第一歩は、正確な測定環境を作ること。

!!! warning "必ずプロファイルモードで実機テストする"
    - デバッグモード: JIT（Just In Time）コンパイルを使い、開発用のアサーションが有効。リリース時のパフォーマンスを反映しない。
    - プロファイルモード: リリースと同じ AOT（Ahead Of Time）コンパイルを使いつつ、パフォーマンストレースが有効。正確に測れる。
    - **エミュレータやシミュレータは絶対に使わない。**
    - ユーザーが使う最も低スペックの実機でテストすると、実際の使用環境での問題を早期に見つけられる。

### プロファイルモードの起動方法

| 環境 | 方法 |
|---|---|
| コマンドライン | `flutter run --profile` |
| VS Code | `launch.json` に `"flutterMode": "profile"` を設定 |
| Android Studio | 「Run > Flutter Run main.dart in Profile Mode」を選ぶ |

### 目標となる指標

- **60fps: 1 フレームあたり約 16ms**。
- **120fps 対応デバイス: 約 8.3ms**。
- この枠を超えたフレームは「ジャンク（jank）」。ユーザーには視覚的なカクつきとして見える。

??? info "パフォーマンスオーバーレイの見方"
    - 最新 300 フレームの描画時間を、2 つのグラフで表示する。
    - 上: Raster（GPU）スレッド。下: UI スレッド。
    - 16ms を示す白線を超える赤いバーが、ジャンクフレーム。

## Flutter DevToolsによる詳細なプロファイリング

- Flutter DevTools は、パフォーマンス分析の中核となるツールセット。
- ブラウザベースで、次の 4 つの主要機能を提供する。
    - Timeline View
    - Memory View
    - CPU Profiler
    - Network Profiler
- プロファイルモードで起動すると、コンソールに表示される DevTools の URL から開ける。

### Timeline View の活用

- フレームレンダリングチャートで、ジャンクの発生パターンを特定する。
- 赤色のオーバーレイが付いたフレームが、問題のあるフレーム。
- シェーダーコンパイルによるジャンクは、濃い赤または黒で表示される。初回アニメーション時に数百ミリ秒のフリーズを起こしうる。

!!! success "Impeller でシェーダーコンパイルジャンクは大幅に軽減"
    - Flutter 3.10 以降、新しいレンダリングエンジン Impeller が iOS でデフォルトになった。
    - 実測: Flutter 3.3.10 で 4.4ms だったシェーダーコンパイル時間が、Flutter 3.10.6 では完全に消えた。

### 診断の基本フロー

まず、UI グラフと GPU グラフのどちらに赤が出ているかを確認する。

| 赤いグラフ | 意味 | 主な原因 |
|---|---|---|
| **UI グラフ** | Dart コードの実行が遅い | `build()` の処理が重い、不要なウィジェット再構築、同期的な重い計算。CPU Profiler でボトルネックを特定する |
| **GPU グラフのみ** | レイヤーツリーのレンダリングが複雑すぎる | `saveLayer()` の呼び出し、複数オブジェクトの透明度処理、クリッピング、シャドウ |
| 両方 | — | まず UI スレッドから調査する |

### Memory View によるリーク検出

- アプリの安定性にとって極めて重要。
- 500ms 間隔で更新される時系列グラフを表示する。追跡するもの:
    - Dart / Flutter ヒープ
    - ネイティブメモリ
    - RasterCache
    - RSS（Resident Set Size）
- リーク検出には「Diff Snapshots」を使う。
    1. 機能を実行する前に、スナップショットを取る。
    2. 機能を複数回実行する。
    3. ガベージコレクションを強制実行する。
    4. 2 回目のスナップショットを取る。
- オブジェクト数や使用メモリが増え続けるクラスが、リークの疑い。

### 一般的なメモリリークの原因

- **クローズされていない Stream と StreamSubscription**（最も頻繁）。`dispose()` で `subscription.cancel()` を忘れると、ストリームがメモリに残り続ける。
- **コントローラの未破棄。** `TextEditingController`・`AnimationController`・`ScrollController` などは、必ず `dispose()` で破棄する。
- **クロージャによるコンテキストリーク。** 大きなオブジェクトを参照するクロージャが長く存在すると、参照先全体がメモリに残る。必要なデータだけを取り出してからクロージャを作る。
- **BuildContext の保持。** `StatefulWidget` の State のフィールドに `BuildContext` を保存すると、ウィジェットのライフサイクルより長く残りうる。

### メモリ管理のベストプラクティス

- `const` コンストラクタを徹底して使い、不要なオブジェクト生成を減らす。
- `StatelessWidget` を優先し、メモリフットプリントを下げる。
- 大量のアイテムは、`ListView.builder` / `GridView.builder` で遅延読み込みする（必須）。
- Singleton パターンでインスタンスを再利用する。
- `dispose()` でサブスクリプションをキャンセルする。
- `AutomaticKeepAliveClientMixin` は慎重に使う。

!!! success "効果の目安"
    - 適切な破棄処理で、**メモリ使用量を 30-50% 削減**できる。
    - `const` ウィジェットで、**リビルドのパフォーマンスが 15-25% 向上**する。

## UI・レンダリングパフォーマンスの最適化テクニック

ウィジェットの再構築の最適化は、パフォーマンス改善の最も効果的なアプローチ。

### `const` コンストラクタを徹底する

- 基本中の基本。`const` で宣言したウィジェットはキャッシュされ、一度も再構築されない。
- 実例（本番アプリ）: スクロール操作ごとに 847 回あったリビルドが、`const` の使用で 228 回になった（**73% の改善**）。

??? example "コード例（19 行）"
    ```dart
    // アンチパターン: 毎フレーム再構築
    class MyWidget extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return Container(
          child: Text('静的テキスト'), // 不要な再構築
        );
      }
    }

    // ベストプラクティス: constで最適化
    class MyWidget extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return Container(
          child: const Text('静的テキスト'), // キャッシュされ再構築なし
        );
      }
    }
    ```

- `analysis_options.yaml` で `prefer_const_constructors` と `prefer_const_literals_to_create_immutables` を有効にすると、`const` にできる箇所を自動検出できる。

!!! tip "クラス分けと const の組み合わせ（日本の技術記事で強調されている発見）"
    - 同じ `build()` の中に `const` を書いても、毎回「変わらないか」の判断コストがかかる。
    - 別クラスに抽出すると、Flutter は一度だけ判断すれば済む。パフォーマンスが大幅に向上する。

### RepaintBoundary による再描画の隔離

- ウィジェットツリーの一部を隔離して、不要な再描画を防ぐ。
- 効果的な対象:
    - 複雑なグラフィックス
    - 静的で、変換・フェード処理されるシーン
    - 独立してアニメーションするウィジェット
    - 重いコンテンツのリストアイテム
- 注意: 各 `RepaintBoundary` はオフスクリーンバッファを作ってメモリを消費する。過度に使わず、プロファイルで改善を確かめる。

??? example "コード例（12 行）"
    ```dart
    // ベストプラクティス: 高価なウィジェットを隔離
    Column(
      children: [
        RepaintBoundary(
          child: ComplexChart(), // 自身のみ再描画
        ),
        StaticHeader(),
        RepaintBoundary(
          child: AnimatedWidget(), // アニメーションが兄弟に影響しない
        ),
      ],
    )
    ```

### リビルドスコープの最小化

- `setState` がツリー全体を再構築しないよう、`ValueNotifier` や `ChangeNotifier` を使う。
- 下の例では、カウンター更新時に高価なウィジェットを再構築せず、`ValueListenableBuilder` で囲んだ `Text` だけを更新する。

??? example "コード例（28 行）"
    ```dart
    class _CounterPageState extends State<CounterPage> {
      final _counter = ValueNotifier<int>(0);

      @override
      void dispose() {
        _counter.dispose();
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          body: Column(
            children: [
              const ExpensiveBackgroundWidget(), // 再構築なし
              ValueListenableBuilder<int>(
                valueListenable: _counter,
                builder: (context, value, child) => Text('$value'), // これだけ更新
              ),
              const ComplexChart(), // 再構築なし
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _counter.value++, // ターゲット更新
          ),
        );
      }
    }
    ```

### AnimatedBuilder の `child` でキャッシュする

- `AnimatedBuilder` は、アニメーション中に `builder` を毎フレーム呼ぶ。
- `child` パラメータで渡したウィジェットは、一度だけ構築され、キャッシュから再利用される。
- 高価なウィジェットは `child` で渡し、毎フレームの再構築を避ける。

## リストビューとスクロールの高速化戦略

### `ListView.builder` による遅延読み込み

- 大量のアイテムを扱うときの必須テクニック。
- `ListView(children: ...)` は全アイテムを即座に生成する。`ListView.builder` は表示中のアイテムだけ（約 10-15 個）を生成する。
- 10,000 アイテムの場合:
    - `ListView`: 2-5 秒のフリーズ。
    - `ListView.builder`: 1 フレームあたり約 16ms で滑らかに表示。

??? example "コード例（16 行）"
    ```dart
    // アンチパターン: 10,000ウィジェットを即座に生成
    ListView(
      children: List.generate(
        10000,
        (i) => ListTile(title: Text('Item $i')),
      ),
    )

    // ベストプラクティス: 表示中のアイテムのみ生成
    ListView.builder(
      itemCount: 10000,
      itemBuilder: (context, index) => ListTile(
        key: ValueKey(index), // パフォーマンスに重要
        title: Text('Item $index'),
      ),
    )
    ```

### `itemExtent` の指定

- 均一な高さのリストで、劇的に改善する。
- 10,000 アイテムのリストで末尾へジャンプする時間:
    - `itemExtent` なし: 約 10 秒。
    - `itemExtent` あり: 瞬時。
- 理由: `ScrollView` が子要素を測定せずに、O(1) でスクロール位置を計算できる。

??? example "コード例（19 行）"
    ```dart
    // itemExtentなし: 遅い、UIブロック
    ListView.builder(
      itemCount: 10000,
      itemBuilder: (context, index) => Container(
        height: 200, // Flutterが各要素を測定
        child: ListTile(title: Text('$index')),
      ),
    )
    // 結果: 末尾へのジャンプに約10秒

    // itemExtentあり: 瞬時のスクロール
    ListView.builder(
      itemCount: 10000,
      itemExtent: 200, // 事前に既知のサイズ、O(1)計算
      itemBuilder: (context, index) => ListTile(
        title: Text('$index'),
      ),
    )
    // 結果: 末尾へのジャンプが瞬時
    ```

### GridView と `shrinkWrap: true` の組み合わせは避ける

- 日本の実践例で、パフォーマンス問題を起こすと報告されている。
- `shrinkWrap: true` だと、`GridView` が子要素に合わせて高さを調整する。全要素が同時にビルドされ、遅延描画されない。
- 解決策: `CustomScrollView` と `SliverGrid` を組み合わせる。

??? example "コード例（28 行）"
    ```dart
    // アンチパターン: 遅延描画されない
    SingleChildScrollView(
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,  // これが問題
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: ...
          ),
        ],
      ),
    )

    // ベストプラクティス: CustomScrollViewとSliverGrid
    CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: ListTile(...)),
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => GridItem(items[index]),
            childCount: items.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
        ),
      ],
    )
    ```

### AutomaticKeepAlive によるスクロール改善

- 複雑なスクロールシナリオで効果がある。
- CyberAgent の実践例: 縦スクロール内に横スクロール（カルーセル）を置くと、Pixel 6a でも 60FPS を下回った。
- 対策: `AutomaticKeepAliveClientMixin` を使い、`wantKeepAlive = true` にする。一度生成した `RenderObject` を画面外でも保持し、再構築コストを減らす。

??? example "コード例（16 行）"
    ```dart
    ListView(
      addAutomaticKeepAlives: true,  // これを有効化
      children: children,
    );

    // 子WidgetのState
    class HogeChildState extends State with AutomaticKeepAliveClientMixin {
      @override
      bool get wantKeepAlive => true;

      @override
      Widget build(BuildContext context) {
        super.build(context);  // 重要: 必ず呼ぶ
        return SomeWidget();
      }
    }
    ```

!!! warning "`wantKeepAlive = true` はメモリを消費し続ける"
    - そのため、フラグは動的にコントロールする必要がある。
    - 無限スクロールでは、チャンク処理で `RenderObject` をまとめて生成・破棄する。常時 60FPS は無理でも、カクつきの頻度を大幅に減らせる。

## 画像最適化とキャッシング戦略

### 画像キャッシュの上限

- Flutter はネットワーク画像を自動でキャッシュするが、上限がある。
- 既定値: `maximumSize` = 1000 画像、`maximumSizeBytes` = 100MB。
- `maxByteSize` より大きい画像はキャッシュされない。上限を増やすか、画像をリサイズする。

```dart
void main() {
  // グローバル画像キャッシュ設定
  PaintingBinding.instance.imageCache.maximumSize = 100; // 最大画像数
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB

  runApp(MyApp());
}
```

### cached_network_image

- より高度なキャッシュ機能を提供するパッケージ。
- 初回ロードは通常の `Image.network` と同じ速さ。
- 2 回目以降はキャッシュから瞬時（0ms。通常は 200-500ms）にロードされ、帯域幅を 100% 節約できる。

```dart
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fadeInDuration: Duration(milliseconds: 500),
  memCacheWidth: 400, // 表示用にリサイズ
  memCacheHeight: 400,
)
```

### 画像最適化のベストプラクティス

- **適切なサイズの画像を配信する。** 100x100 のサムネイルに 4K 画像を読み込まず、サイズ別の画像をリクエストする。
- **画像を圧縮する。** WebP は JPEG / PNG より 25-35% 小さい。CDN によるサーバーサイド最適化も効果的。
- **重要な画像をプリキャッシュする。** 初回表示時の待ち時間を 200-500ms 改善できる。

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(AssetImage('assets/hero-image.png'), context);
  precacheImage(NetworkImage('https://example.com/logo.png'), context);
}
```

!!! success "日本のプロダクション環境での実測"
    - `flutter_image_compress` による圧縮で、**約 90% のサイズ削減**（10MB → 1MB）。
    - 画像品質を 80% にし、適切な解像度に調整すると、視覚的な劣化を抑えつつ大幅に小さくできる。

## アニメーションパフォーマンスの最適化

### Opacity をアニメーションで直接使わない

- 毎フレーム全サブツリーを再構築し、2-3 倍遅くなる。
- 代わりに `FadeTransition`（または `AnimatedOpacity`）を使う。

??? example "コード例（21 行）"
    ```dart
    // アンチパターン: 毎フレーム再構築
    AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: controller.value,
        child: ExpensiveWidget(), // 毎フレーム再構築!
      ),
    )

    // ベストプラクティス: FadeTransition
    FadeTransition(
      opacity: Tween(begin: 0.0, end: 1.0).animate(controller),
      child: ExpensiveWidget(), // 一度だけ構築
    )

    // または AnimatedOpacity
    AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 500),
      child: ExpensiveWidget(),
    )
    ```

### saveLayer 操作を避ける

- レンダリングパフォーマンスに直結する。
- `saveLayer()` は Flutter フレームワークで最も高価なメソッドの 1 つ。
- 次のものが、暗黙的に `saveLayer` を呼ぶ。
    - 部分的に透明な `Opacity` ウィジェット
    - `ClipPath`、`ClipOval`（可能なら `ClipRect` を使う）
    - `ColorFilter`、`ImageFilter`
    - `ShaderMask`

??? example "コード例（14 行）"
    ```dart
    // アンチパターン: 複数の透明レイヤー
    Container(
      color: Colors.black.withOpacity(0.5), // saveLayer
      child: Container(
        color: Colors.white.withOpacity(0.7), // 別のsaveLayer
        child: Text('Text'),
      ),
    )

    // ベストプラクティス: 単一レイヤー
    Container(
      color: Colors.grey, // 透明度なし
      child: Text('Text'),
    )
    ```

!!! warning "画面外で動くアニメーションはバッテリーを大量に消費する（日本の実践例）"
    - `SingleChildScrollView` の中で `CircularProgressIndicator` を使うと、画面外でも回り続ける。
    - バッテリー消費: 30 分で 14% から、90 分で 47% に悪化した。
    - `ListView.builder` による遅延描画に変えると、バッテリー寿命が 3 倍（90 分で 16% 消費）になり、発熱もほぼなくなった。

## メモリ管理と起動時間の改善

### 起動時間の目標

- 業界標準は、**2 秒以内のコールドローンチ**。ユーザーの 49% が 2 秒以内の起動を期待している。
- 起動プロセスの順序:
    1. Engine と Dart VM の初期化
    2. Dart アイソレートの起動
    3. `main()` の実行
    4. 初回フレームのレンダリング

### `main()` での作業を最小化する

- 最も効果的。並列初期化で大幅に改善できる。
- 実測: **並列初期化で起動時間が 76% 改善**（2500ms → 600ms）したケースがある。

??? example "コード例（17 行）"
    ```dart
    // アンチパターン: 逐次初期化
    void main() async {
      await initDatabase();
      await initAnalytics();
      await initPrefs();
      runApp(MyApp());
    }

    // ベストプラクティス: 並列初期化
    void main() async {
      await Future.wait([
        initDatabase(),
        initAnalytics(),
        initPrefs(),
      ]);
      runApp(MyApp());
    }
    ```

### 非同期データローディング

- `FutureBuilder` で、初期化処理を UI をブロックせずに実行する。
- 重い計算は `compute()` でバックグラウンドアイソレートに移し、UI の応答性を保つ。

```dart
Future<MyData> parseJsonInBackground(String jsonStr) async {
  return jsonDecode(jsonStr);
}

// バックグラウンドアイソレートにオフロード
MyData result = await compute(parseJsonInBackground, bigJsonString);
```

### Deferred Components（遅延読み込み）

- 非クリティカルな機能のロードを遅れさせ、初回ロード時間を 30-50% 減らせる。

```dart
import 'package:my_app/heavy_feature.dart' deferred as heavyFeature;

Future<void> openFeature(BuildContext context) async {
  await heavyFeature.loadLibrary();
  Navigator.push(context,
    MaterialPageRoute(builder: (_) => heavyFeature.Screen())
  );
}
```

!!! tip "起動パフォーマンスの測り方"
    - `flutter run --profile --trace-startup` を使い、`build/start_up_info.json` の `timeToFirstFrameMicros` を確認する。
    - 本番環境では、Firebase Performance Monitoring で継続的に監視する。

## ビルドサイズの削減とアセット最適化

### Tree Shaking

- リリースビルドで自動的に実行される。エントリーポイントから到達できないコードを削除する。
- フォントグリフも、未使用の文字が削除される。
    - **MaterialIcons: 1645KB → 10KB**（99.3% 削減）。
    - **CupertinoIcons: 283KB → 1.5KB**（99.5% 削減）。

```bash
# Tree Shakingを有効化(リリースで自動)
flutter build apk --release
flutter build ios --release

# ビルドサイズ分析
flutter build apk --analyze-size
flutter build ios --analyze-size
```

### ABI 別 APK 分割

- ユニバーサル APK の 50MB から、各 ABI 用の 5MB へ。**90% のサイズ削減**。

```bash
# アーキテクチャ別の個別APKを生成
flutter build apk --split-per-abi

# 結果:
# ユニバーサルAPK: 50MB
# ABI別APK: 各5MB (90%削減)
```

### App Bundle（推奨）

- Google Play がデバイスごとに最適化された APK を生成する。
- ユニバーサル APK と比べて、**30-40% のサイズ削減**が典型的。

```bash
flutter build appbundle

# Google Playがデバイスごとに最適化されたAPKを生成
# 典型的な削減率: ユニバーサルAPKより30-40%小さい
```

### アセット最適化

画像フォーマットの選び方:

| 用途 | フォーマット |
|---|---|
| 写真 | WebP（最高の圧縮率）または JPEG |
| グラフィック / UI | PNG または SVG |
| アイコン | SVG（スケーラブルで極小） |
| アニメーション | Lottie JSON（GIF より小さい） |

- **WebP 変換で 25-35% の画像サイズ削減**。総合的な最適化で **60-75% のサイズ削減**が可能。

!!! success "日本の実測データ"
    - Android App Bundle の利用: 30-40% 削減。
    - WebP 形式: 約 1/10 のファイルサイズ。
    - 未使用リソースの削除: APK 容量が 18% 削減。

## Firebase Performance Monitoringの実装と活用

- 本番環境でのアプリのパフォーマンスを追跡する、公式サポートの無料ツール。
- アプリライフサイクルのメトリクス（起動時間、ネットワークリクエスト）を自動収集する。
- 特定のコードを監視するカスタムトレースにも対応する。

!!! warning "重要な制限"
    Flutter のアーキテクチャ上、個別の Flutter スクリーンについて、自動の画面レンダリングパフォーマンス監視は利用できない。

### セットアップ（3 ステップ）

1. `flutter pub add firebase_performance` でプラグインを追加する。
2. `flutterfire configure` で Firebase を設定する。
3. アプリを再ビルドする。

`main.dart` での初期化コード:

??? example "コード例（3 ステップ）（15 行）"
    ```dart
    import 'package:firebase_core/firebase_core.dart';
    import 'package:firebase_performance/firebase_performance.dart';
    import 'firebase_options.dart';

    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // オプション: パフォーマンス収集の有効化/無効化
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

      runApp(MyApp());
    }
    ```

- 検証の手順:
    1. アプリをバックグラウンド / フォアグラウンドで切り替える。
    2. 画面遷移を行う。
    3. ネットワークリクエストを起こす。
- データは数分以内に、Firebase Console のパフォーマンスダッシュボードに表示される。

### カスタムトレース

- 特定のタスク（画像ロード、データベースクエリなど）の時間を測れる。
- 既定のメトリックは継続時間。カスタムメトリック（キャッシュヒット、メモリ警告など）も追加できる。

??? example "コード例（13 行）"
    ```dart
    Future<void> performHeavyOperation() async {
      // トレースインスタンスを作成
      final Trace trace = FirebasePerformance.instance.newTrace('heavy_operation_trace');

      // トレース開始
      await trace.start();

      // 監視するコード
      await someExpensiveOperation();

      // トレース停止
      await trace.stop();
    }
    ```

### traceWrapper ユーティリティ

- 日本の技術記事で紹介されている。コード量を最小限にしながら、メトリクスを保てる。
- 使用例では、API リクエストとローカルデータベース保存の各処理時間を、個別に記録できる。

??? example "コード例（34 行）"
    ```dart
    /// 関数をラップして実行時間を測定
    Future<T> traceWrapper<T>(
      String functionName,
      Future<T> Function(Trace? trace, void Function(String name) recordTime)
        function,
    ) async {
      final trace = Firebase.apps.isEmpty
        ? null
        : FirebasePerformance.instance.newTrace(functionName);
      final startTime = DateTime.now();
      unawaited(trace?.start());
      var tempTime = 0;
      T result;

      try {
        result = await function(
          trace,
          (name) {
            final time = DateTime.now().difference(startTime).inMilliseconds;
            final diff = time - tempTime;
            tempTime = time;
            trace?.setMetric(name, diff);
          },
        );
        trace?.putAttribute('success', 'true');
      } catch (e) {
        trace?.putAttribute('success', 'false');
        rethrow;
      } finally {
        unawaited(trace?.stop());
      }

      return result;
    }
    ```

??? example "コード例（17 行）"
    ```dart
    void fetchAndSave(String postId) async {
      traceWrapper("PostRepository.fetchAndSave",
        (trace, recordTime) async {
          // APIリクエスト実行
          final httpClient = ref.read(httpClientProvider);
          final response =
            await httpClient.get('https://jsonplaceholder.typicode.com/posts/1');
          recordTime("api request");

          // ローカルデータベースに保存
          final sharedPreferences =
            await ref.read(sharedPreferencesProvider.future);
          await sharedPreferences.setString(
            "post:${postId}", response.data.toString());
          recordTime("save local database");
        });
    }
    ```

### ネットワークリクエスト監視

- 標準の HTTP ライブラリは、自動で監視される。
- **Dio パッケージは手動の計装が必要。**
- 日本の技術記事で詳しく解説されている Dio インターセプターを使うと、次を記録できる。
    - リクエスト / レスポンスのサイズ
    - ステータスコード
    - カスタム属性

??? example "コード例（57 行）"
    ```dart
    class PerformanceInterceptor extends Interceptor {
      late final FirebasePerformance _performance = FirebasePerformance.instance;

      Future<void> onRequest(
        RequestOptions options,
        RequestInterceptorHandler handler,
      ) async {
        try {
          if (Firebase.apps.isEmpty) return handler.next(options);

          // デバッグモードでメトリクス収集しない
          // ブレークポイントで不正確なタイミングになる
          // if (kDebugMode) return handler.next(options);

          // メトリクス作成
          final metric = _performance.newHttpMetric(
            options.uri.toString(),
            switch (options.method) {
              'GET' => HttpMethod.Get,
              'POST' => HttpMethod.Post,
              'PUT' => HttpMethod.Put,
              'DELETE' => HttpMethod.Delete,
              'PATCH' => HttpMethod.Patch,
              _ => HttpMethod.Get,
            },
          );

          await metric.start();
          metric.requestPayloadSize = await _calculatePayloadSize(options.data);
          options.extra['metric'] = metric;
        } catch (e, s) {
          logger.e('Failed to setup metrics.', error: e, stackTrace: s);
        }
        return handler.next(options);
      }

      Future<void> onResponse(
        Response response,
        ResponseInterceptorHandler handler,
      ) async {
        handler.next(response);

        try {
          if (Firebase.apps.isEmpty) return;
          final metric = response.requestOptions.extra['metric'] as HttpMetric?;
          if (metric == null) return;

          metric
            ..responsePayloadSize = await _calculatePayloadSize(response.data)
            ..httpResponseCode = response.statusCode ?? 0;

          await metric.stop();
        } catch (e, s) {
          logger.e('Failed to analyze metrics.', error: e, stackTrace: s);
        }
      }
    }
    ```

### Firebase Console でのデータ分析

- **メトリクスボード（上部）**:
    - 最大 6 つの主要メトリクスを追跡し、グラフでトレンドと変化率を表示する。
    - 既定で 90 パーセンタイルを表示する（調整可能）。
    - 色の意味:

        | 色 | 意味 |
        |---|---|
        | 赤 | 負のトレンド（例: 起動時間の増加） |
        | 緑 | 正のトレンド（例: ロード時間の減少） |
        | グレー | 中立、または明確なトレンド方向なし |

- **トレーステーブル（下部）**:
    - タブ: カスタムトレース、ネットワークリクエスト、画面レンダリング（Flutter では制限あり）。
    - メトリック値または変化率でソートできる。
    - トレース名をクリックすると詳細を表示する。
    - パーセンタイル（50th・90th・95th・99th）でフィルターできる。
    - 時間範囲を選べる（24 時間・7 日・30 日・カスタム）。

??? info "属性によるフィルタリングと分析フローの例"
    - セグメント化できる属性:
        - アプリバージョン（リリース比較）
        - 国（地域パフォーマンス）
        - デバイス（モデル固有の問題）
        - OS バージョン
        - ネットワークタイプ（WiFi、4G、5G）
    - 分析フローの例:
        1. ダッシュボードで、ネットワークのレスポンス時間が遅いことに気づく。
        2. 国の属性でフィルターする。
        3. 最新値でソートする。
        4. レスポンス時間が最も高い国を特定する。
        5. 選んだ国をグラフにプロットする。
        6. デバイスフィルターを足して、さらに深掘りする。

??? info "パーセンタイルの読み方"
    | パーセンタイル | 意味 | 使いどころ |
    |---|---|---|
    | 50th（P50） | 中央値。半数のユーザーはこれより良い / 悪い体験をする | 典型的なユーザー体験の理解 |
    | 90th（P90） | 90% のユーザーがこれより良いパフォーマンスを経験する。Android Vitals の標準に準拠 | Android Vitals 標準への準拠の確認 |
    | 95th（P95） | 上位 5% の最悪のパフォーマンス体験 | エッジケースと最悪シナリオの特定 |
    | 99th（P99） | 上位 1% の最悪の体験 | エッジケースと最悪シナリオの特定 |

## 一般的なパフォーマンス問題とトラブルシューティング

各問題を「症状 → 原因 → デバッグ → 解決策」で整理する。

### 過度な再ビルド

- **症状:**
    - DevTools で、ウィジェットの再ビルド回数が多い。
    - 状態が変わるとジャンクが出る。
    - 小さな変更で、ウィジェットツリー全体が再構築される。
- **デバッグ技法:**
    - Android Studio の Widget Rebuild Profiler（View > Tool Windows > Flutter Performance）。
    - DevTools で「Display widget rebuilds」を有効にする。
    - `debugRepaintRainbowEnabled = kDebugMode` で再描画を視覚化する。
- **解決策:**
    - `const` コンストラクタを可能な限り使う。
    - `StreamBuilder`・`BlocBuilder`・`Provider` で、状態変化をウィジェットツリーの下層に押し下げる。
    - `BlocBuilder` の `buildWhen` で、再ビルドをフィルターする。
    - ウィジェットを個別の `StatelessWidget` に抽出する。
    - `RepaintBoundary` で、再ビルドを隔離する。
    - キー（`GlobalKey`・`ValueKey`）で、ウィジェットのアイデンティティを保つ。
- 実践例: `BlocBuilder` が `Column` 全体を再構築する悪い例と、`buildWhen` でフィルターして `Text` だけを再構築する良い例。

??? example "コード例（23 行）"
    ```dart
    // 悪い例 - Column全体を再構築
    BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return Column(children: [
          Text(profileState.profile.name),
          CreatePostForm(),
          Posts(),
        ]);
      },
    )

    // 良い例 - Textウィジェットのみ再構築
    Column(children: [
      BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
          previous.profile.name != current.profile.name,
        builder: (context, profileState) {
          return Text(profileState.profile.name);
        },
      ),
      CreatePostForm(),
      Posts(),
    ])
    ```

### メモリリーク

- **症状:** オブジェクトが必要以上にメモリに残り、徐々にメモリが増えて、最終的にクラッシュする。
- **一般的な原因:**
    - クローズされていない `Stream` と `StreamController`。
    - 破棄されていないコントローラ（`TextEditingController`・`AnimationController`）。
    - 削除されていないリスナー。
    - 大きなオブジェクトを参照するグローバル変数。
    - 大きなオブジェクトをキャプチャするクロージャ。
    - 適切にキャッシュ / 破棄されていない画像。
    - クローズされていない BLoC インスタンス。
- **デバッグ技法:**
    - DevTools Memory View で、ヒープスナップショットを分析する。
    - 「Diff Snapshots」で、操作の前後のスナップショットを比べる。
    - メモリグラフで、徐々に増えるパターンを監視する。
    - Profile Memory タブで、クラス別のオブジェクト数を確認する。
    - テストで `leak_tracker_flutter_testing` パッケージを有効にする。
    - `ImageCache` の肥大化をチェックする。
- **解決策:**
    - `dispose()` で、必ずコントローラを破棄する。
    - `close()` で、BLoC インスタンスをクローズする。
    - `AutomaticKeepAliveClientMixin` を慎重に使う。
    - 画像キャッシュを最適化する（`maximumSize` と `maximumSizeBytes` を調整）。
    - 短命なオブジェクトへの、グローバル / 静的参照を避ける。

```dart
@override
void dispose() {
  _controller.dispose();
  _streamController.close();
  _subscription.cancel();
  super.dispose();
}
```

??? example "実践事例: Impeller のメモリリークによる Out of Memory（日本の技術記事）"
    - 症状: 画面遷移のたびに数百 MB 単位でメモリが増え、10 問で 3GB を超えて Out of Memory になった。
    - 原因: Impeller のバグ（`DecorationImage` で `AssetImage` を使用）。
    - 試したが効果がなかった方法（記事に詳しく記録されている）:
        - `imageCache.clear()`
        - `AssetImage.evict()`
        - 手動のガベージコレクション
        - `MemoryImage` への変更
    - 最終的な解決策（どちらか）:
        - `AndroidManifest.xml` で `io.flutter.embedding.android.EnableImpeller` を `false` にする。
        - 実行時に `flutter run --no-impeller` を使う。

### 低速スクロール

- **症状:** `ListView` / `GridView` のパフォーマンスがスクロール中に落ち、FPS が 60 を下回る。
- **一般的な原因:**
    - `ListView.builder` を使わず、全アイテムを先にビルドしている。
    - リストアイテムのウィジェットツリーが複雑。
    - 最適化されていない大きな画像。
    - クリッピング操作。
    - 適切な設定なしの、ネストされた `ListView`。
    - `shrinkWrap: true` によって、全リストのビルドが強制される。
- **デバッグ技法:**
    - パフォーマンスオーバーレイを監視する（上段 = UI スレッド、下段 = GPU / Raster）。
    - DevTools Timeline で、高価なビルド操作を特定する。
    - 「Track layouts」を有効にして、過度な intrinsic パスをチェックする。
    - フレームレンダリングチャートで、ジャンク（赤フレーム > 16ms）を確認する。
- **解決策:**
    - 遅延ロードには、必ず `ListView.builder` または `GridView.builder` を使う。
    - 全アイテムが同じサイズなら、`itemExtent` を指定する。
    - ネットワーク画像には `CachedNetworkImage` を使う。
    - 画像サイズを最適化する（サムネイルに 4K 画像を読み込まない）。
    - ネストされたスクロールには、`CustomScrollView` と Slivers を使う。
    - `addAutomaticKeepAlives` を慎重に使う。
    - 複雑なリストアイテムを、個別の `StatelessWidget` に抽出する。
    - スクロールコールバックで `setState()` を避ける。

!!! example "CyberAgent のブログの事例: 縦 ListView 内の横 ListView による FPS 低下"
    - 問題: ネストされた横 `ListView`（と縦 `ListView`）による FPS 低下。
    - 解決策: 適切な `wantKeepAlive` 管理と、チャンクベースの破棄による `AutomaticKeepAlive` の使用。
    - 結果: メモリの増加を抑えながら、60FPS を維持できた。

### 低速起動（コールドローンチ）

- **症状:** 最初のフレームが出るまで 2 秒以上かかる。起動時に黒画面が出る。
- **一般的な原因:**
    - Flutter エンジン初期化のオーバーヘッド。
    - 起動時に構築される大きなウィジェットツリー。
    - メインアイソレートでの、重い同期操作。
    - 過度なプラグイン初期化。
    - 初回アニメーション時のシェーダーコンパイル。
- **デバッグ技法:**
    - `flutter run --profile --trace-startup` を使い、トレース出力の `timeToFirstFrameMicros` を確認する。
    - DevTools Timeline で起動フレームをキャプチャし、「Framework initialization」と「First frame rasterized」のイベントを探す。
    - 本番では Firebase Performance Monitoring で追跡する。
    - Android Logcat で「Displayed」の時間を確認する。
- **解決策:**
    - `Future.delayed()` や `addPostFrameCallback()` で、重い初期化を遅らせる。
    - `compute()` で、別アイソレートで JSON をパースする。
    - 非クリティカルな機能に、deferred loading を使う。
    - シェーダーをプリコンパイルする。
    - プラグインとサービスを遅延ロードする。
    - 目標: シンプルなアプリで 800ms 未満、複雑なアプリで 2 秒未満。

??? example "コード例（コールドローンチ）（17 行）"
    ```dart
    // 悪い例 - 逐次初期化
    void main() async {
      await initDatabase();
      await initAnalytics();
      await initPrefs();
      runApp(MyApp());
    }

    // 良い例 - 並列初期化
    void main() async {
      await Future.wait([
        initDatabase(),
        initAnalytics(),
        initPrefs(),
      ]);
      runApp(MyApp());
    }
    ```

### シェーダーコンパイルジャンク

- **症状:** 初回アニメーションが、シェーダーコンパイルでカクつく。
- **手動でシェーダーをコンパイルする手順:**
    1. 全アニメーションを実行しながら、アプリを動かす（`flutter run --profile --cache-sksl`）。
    2. `M` キーを押して、シェーダーキャッシュを書き込む。
    3. プリコンパイル済みのシェーダーでビルドする（`flutter build apk --bundle-sksl-path=flutter_01.sksl.json`）。

!!! success "Flutter 3.10 以降の解決策: Impeller"
    - Impeller レンダリングエンジン（iOS でデフォルト）が、シェーダーコンパイルジャンクを排除する。
    - Flutter 3.10.6 以降で、自動的に有効になっている。
    - Performance View で、赤 / 黒の Shader Compilation バーが出ないことを確認できる。

## 実践的なベストプラクティスとアンチパターン

### 推奨される実践方法

- `const` コンストラクタを可能な限り使う。
- 20 アイテム以上のリストには `ListView.builder` を使う。
- 均一なリストアイテムには `itemExtent` を指定する。
- 高価な静的ウィジェットには `RepaintBoundary` を使う。
- `cached_network_image` で画像をキャッシュする。
- `Opacity` ではなく `FadeTransition` を使う。
- 実機のリリースモード（プロファイル）で測る。
- ウィジェットは、メソッドではなくクラスに分割する。
- スコープ付き更新に `ValueNotifier` / `ChangeNotifier` を使う。
- コントローラとストリームを破棄する。

### 避けるべきアンチパターン

- アニメーションで `Opacity` を使わない（`FadeTransition` を使う）。
- 必要でない限り、`saveLayer` を使わない。
- `ListView` で、全子要素を事前に作らない。
- `ListView` で `shrinkWrap: true` を使わない。
- 同期操作で UI スレッドをブロックしない。
- 不必要に `operator ==` をオーバーライドしない。
- デバッグモードでパフォーマンステストをしない。
- 深くネストされたウィジェットツリーを使わない。
- 重要な画像のプリキャッシュを忘れない。
- DevTools プロファイラーの警告を無視しない。

### 測定値とベンチマーク

公式の Flutter ソースと、本番アプリでの実測データ。

| 対象 | 変化 | 効果 |
|---|---|---|
| SkSL ウォームアップ（Moto G4） | 最悪フレーム 90ms → 40ms | 56% 高速化 |
| SkSL ウォームアップ（iPhone 4s） | 最悪フレーム 300ms → 80ms | 73% 高速化 |
| `const` ウィジェット | スクロールあたり 847 → 228 再ビルド | 73% 削減 |
| `ListView.builder` | 10,000 アイテムのロード 10 秒 → 1 秒未満 | 10 倍高速化 |
| `itemExtent` | 末尾へのジャンプ 10 秒 → 瞬時 | 100 倍高速化 |
| `cached_network_image` | 500ms のリロード → 0ms（キャッシュ済み） | 瞬時化 |
| `FadeTransition` vs `Opacity` | 32ms/フレーム → 12ms/フレーム | 2.7 倍高速化 |

??? info "日本語リソースの独自視点"
    - **実測データが豊富:** 具体的なデバイス名での測定、バッテリー消費の時系列データ、メモリ使用量の具体的な数値。
    - **実プロダクションでの問題:**
        - ネットスーパーアプリでの `GridView` の問題。
        - 動画配信アプリでのバッテリーの問題。
        - クイズアプリでのメモリリーク。
    - **企業エンジニアリングブログの質:** CyberAgent、DELISH KITCHEN、Future Architect。
    - **最新バージョンへの対応:**
        - Flutter 3.10 の Impeller 導入効果の実測。
        - Flutter 3.27 の最新のパフォーマンス向上施策。
    - **トラブルシューティングの詳細:** 試行錯誤の過程を詳しく記録し、失敗した方法も載せている。

## アクションアイテムと実装チェックリスト

### プロファイリング前の準備

- [ ] プロファイルモードでビルドする。
- [ ] 物理デバイスでテストする。
- [ ] 最低スペックのターゲットデバイスを使う。
- [ ] 他のアプリを閉じる。
- [ ] パフォーマンスのベースラインを確立する。

### プロファイリング中の実施事項

- [ ] 特定のユーザーフローを記録する。
- [ ] 前後のスナップショットを取る。
- [ ] 再現手順をメモする。
- [ ] 複数のサンプルをキャプチャする。
- [ ] 所見を文書化する。

### 分析段階でのチェック

- [ ] Timeline でジャンクを確認する。
- [ ] CPU のホットスポットをレビューする。
- [ ] メモリのトレンドを調べる。
- [ ] ネットワーク呼び出しを検査する。
- [ ] 最適化のターゲットを特定する。

### 最適化の優先順位

1. UI スレッドの問題を最初に直す。
2. 高価なメソッドを最適化する。
3. ウィジェットの再ビルドを減らす。
4. 画像を最適化する。
5. 測定によって、改善を検証する。

### 継続的監視の設定

- [ ] Firebase Performance Monitoring を統合する。
- [ ] 重要なカスタムトレースを追加する。
- [ ] パフォーマンスアラートを設定する。
- [ ] 自動化されたパフォーマンステストを実装する。
- [ ] リグレッション追跡のため、CI/CD パイプラインに統合する。

## 結論と今後の展望

Flutter のパフォーマンス最適化に必要なこと:

- **プロファイルモードでの実機テスト。**
- **DevTools の徹底活用。**
- **最適化の階層を理解する。** 過度な再ビルドを最初に直し、次にメモリリーク、その後にレンダリング問題。
- **プラットフォームを意識する。** iOS と Android の違いを理解する。
- **プロアクティブな監視。** 自動化されたパフォーマンステストで、リグレッションを早期に検出する。

!!! note "フレームワークは既定で高性能"
    ただし、本番品質のアプリには、一般的な落とし穴とデバッグツールへの、開発者の理解が不可欠。

このガイドの技法を実践した場合に見込める効果:

- 60fps 以上の滑らかな体験を提供できる。
- メモリ使用量を 30-50% 削減できる。
- 起動時間を 76% 改善できる。
- ビルドサイズを 60-75% 削減できる。

DevTools と Firebase Performance Monitoring を活用し、継続的に測定して改善するサイクルを確立する。
