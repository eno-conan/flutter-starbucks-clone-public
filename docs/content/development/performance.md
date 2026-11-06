# Flutterパフォーマンス最適化ガイド

## 概要

- Flutter は、適切に実装すれば 60fps 以上で動く。維持するには、測定と最適化の基本を押さえる必要がある。
- このガイドの範囲:
    - 測定の環境と DevTools の使い方
    - UI・リスト・画像・アニメーション・起動・ビルドサイズの最適化
    - Firebase Performance Monitoring による本番監視
    - 症状別のトラブルシューティング

!!! warning "原則: 測定してから最適化する"
    - 測定は、実機のプロファイルモードで行う。
    - デバッグモードは JIT コンパイルで、アサーションも有効。リリース時の性能を反映しない。
    - エミュレータ・シミュレータでは測らない。ユーザーが使う最も低スペックの実機で測る。

## 測定の基礎

### プロファイルモードの起動方法

| 環境 | 方法 |
|---|---|
| コマンドライン | `flutter run --profile` |
| VS Code | `launch.json` に `"flutterMode": "profile"` を設定 |
| Android Studio | 「Run > Flutter Run main.dart in Profile Mode」を選ぶ |

### 目標となる指標

- 60fps は 1 フレーム約 16ms、120fps 対応デバイスは約 8.3ms。
- この枠を超えたフレームが「ジャンク（jank）」で、カクつきとして見える。

??? info "パフォーマンスオーバーレイの見方"
    - 最新 300 フレームの描画時間を、2 つのグラフで表示する。
    - 上: Raster（GPU）スレッド。下: UI スレッド。
    - 16ms の白線を超える赤いバーが、ジャンクフレーム。

## Flutter DevTools

- ブラウザベースの分析ツール。プロファイルモードで起動すると、コンソールに URL が出る。
- 主な機能は Timeline View・Memory View・CPU Profiler・Network Profiler の 4 つ。

### 診断の基本フロー（Timeline View）

- 赤いオーバーレイが付いたフレームが、問題のフレーム。
- まず、UI グラフと GPU グラフのどちらに赤が出ているかを見る。

| 赤いグラフ | 意味 | 主な原因 |
|---|---|---|
| UI グラフ | Dart コードの実行が遅い | `build()` が重い、不要な再構築、同期的な重い計算。CPU Profiler で特定する |
| GPU グラフのみ | レイヤーツリーの描画が複雑 | `saveLayer()`、透明度、クリッピング、シャドウ |
| 両方 | — | UI スレッドから調査する |

### Memory View によるリーク検出

- 500ms 間隔で、Dart / Flutter ヒープ・ネイティブメモリ・RasterCache・RSS を時系列で表示する。
- リーク検出には「Diff Snapshots」を使う。
    1. 機能の実行前に、スナップショットを取る。
    2. 機能を複数回実行する。
    3. ガベージコレクションを強制実行する。
    4. 2 回目のスナップショットを取り、増え続けるクラスを探す。

### 一般的なメモリリークの原因

| 原因 | 対処 |
|---|---|
| 閉じていない `Stream` / `StreamSubscription`（最も多い） | `dispose()` で `cancel()` / `close()` する |
| 破棄していないコントローラ（`TextEditingController`・`AnimationController`・`ScrollController`） | `dispose()` で破棄する |
| 大きなオブジェクトを参照するクロージャ | 必要なデータだけ取り出してから、クロージャを作る |
| State のフィールドに保存した `BuildContext` | 保持しない |
| 削除していないリスナー、BLoC インスタンス | `removeListener()`、`close()` する |

```dart
@override
void dispose() {
  _controller.dispose();
  _streamController.close();
  _subscription.cancel();
  super.dispose();
}
```

!!! success "効果の目安"
    - 適切な破棄処理で、メモリ使用量を 30-50% 削減できる。
    - `const` ウィジェットで、リビルドのパフォーマンスが 15-25% 向上する。

## UI・レンダリングの最適化

ウィジェットの再構築を減らすのが、最も効果的な改善。

### `const` コンストラクタを徹底する

- `const` で宣言したウィジェットはキャッシュされ、再構築されない。
- 実例: スクロールごとに 847 回あったリビルドが、`const` で 228 回になった（73% 削減）。
- `analysis_options.yaml` で `prefer_const_constructors` と `prefer_const_literals_to_create_immutables` を有効にすると、`const` にできる箇所を自動検出できる。

!!! tip "メソッドではなく、別クラスに抽出する"
    - 同じ `build()` の中に `const` を書いても、毎回「変わらないか」の判断コストがかかる。
    - 別クラスに抽出すると、Flutter は一度判断すれば済む。

### RepaintBoundary による再描画の隔離

- ツリーの一部を隔離して、不要な再描画を防ぐ。
- 効果的な対象: 複雑なグラフィックス、独立してアニメーションするウィジェット、重いリストアイテム。
- 各 `RepaintBoundary` はオフスクリーンバッファでメモリを消費する。使いすぎず、プロファイルで効果を確かめる。

### リビルドスコープの最小化

- `setState` がツリー全体を再構築しないよう、`ValueNotifier` と `ValueListenableBuilder` で更新箇所を絞る。
- `AnimatedBuilder` は、`child` で渡したウィジェットを一度だけ構築して再利用する。高価なウィジェットは `child` で渡す。

??? example "コード例: ValueListenableBuilder（15 行）"
    ```dart
    final _counter = ValueNotifier<int>(0);

    Column(
      children: [
        const ExpensiveBackgroundWidget(), // 再構築なし
        ValueListenableBuilder<int>(
          valueListenable: _counter,
          builder: (context, value, child) => Text('$value'), // これだけ更新
        ),
        const ComplexChart(), // 再構築なし
      ],
    )
    // _counter は dispose() で破棄する
    ```

## リストとスクロール

| 項目 | 内容 | 効果 |
|---|---|---|
| `ListView.builder` | 表示中のアイテム（約 10-15 個）だけ生成する。`ListView(children: …)` は全件を即座に生成する | 10,000 件で、2-5 秒のフリーズが、1 フレーム約 16ms になる |
| `itemExtent` | 均一な高さのリストで指定する。子を測定せず O(1) でスクロール位置を計算できる | 10,000 件の末尾へのジャンプが、約 10 秒から瞬時になる |
| `CustomScrollView` + `SliverGrid` | `GridView` の `shrinkWrap: true` の代わりに使う。`shrinkWrap: true` は全要素を同時にビルドし、遅延描画されない | 遅延描画が効く |
| `AutomaticKeepAliveClientMixin` | 縦スクロール内の横スクロール（カルーセル）で、生成済みの `RenderObject` を画面外でも保持する | CyberAgent の事例では、Pixel 6a でも 60FPS を下回っていた状態を改善 |

- `AutomaticKeepAliveClientMixin` では、`wantKeepAlive` を `true` にし、`build()` の先頭で `super.build(context)` を必ず呼ぶ。
- `wantKeepAlive = true` はメモリを消費し続ける。無限スクロールでは、チャンク単位で生成・破棄する。

??? example "コード例: GridView の置き換え（12 行）"
    ```dart
    // アンチパターン: shrinkWrap で遅延描画されない
    GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), ...)

    // ベストプラクティス
    CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: ListTile(...)),
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => GridItem(items[index]),
            childCount: items.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        ),
      ],
    )
    ```

## 画像の最適化とキャッシュ

- Flutter はネットワーク画像を自動でキャッシュする。既定の上限は `maximumSize` = 1000 画像、`maximumSizeBytes` = 100MB。
- 上限より大きい画像はキャッシュされない。上限を増やすか、画像をリサイズする。
- `cached_network_image` は、2 回目以降をキャッシュから瞬時（通常 200-500ms）に読み込む。`memCacheWidth` / `memCacheHeight` で表示サイズに縮小できる。
- 配信する画像:
    - 表示サイズに合った画像を配信する（100x100 のサムネイルに 4K 画像を読み込まない）。
    - WebP は JPEG / PNG より 25-35% 小さい。
    - 重要な画像は `precacheImage` で先読みすると、初回表示が 200-500ms 改善する。

```dart
PaintingBinding.instance.imageCache.maximumSize = 100; // 最大画像数
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB
```

!!! success "日本のプロダクション環境での実測"
    - `flutter_image_compress` で、約 90% 削減（10MB → 1MB）。
    - 品質 80% + 適切な解像度で、視覚的な劣化を抑えて大幅に小さくできる。

## アニメーションとレンダリング

- アニメーションで `Opacity` を直接使わない。毎フレーム全サブツリーを再構築し、2-3 倍遅くなる（32ms → 12ms/フレーム）。
    - 代わりに `FadeTransition` か `AnimatedOpacity` を使う。
- `saveLayer()` は Flutter で最も高価なメソッドの 1 つ。次のものが暗黙的に呼ぶ。
    - 部分的に透明な `Opacity`
    - `ClipPath`・`ClipOval`（可能なら `ClipRect`）
    - `ColorFilter`・`ImageFilter`・`ShaderMask`
- 透明な `Container` を重ねない。透明度のない色を 1 つ使う。

??? example "コード例: FadeTransition（8 行）"
    ```dart
    // アンチパターン: 毎フレーム再構築
    Opacity(opacity: controller.value, child: ExpensiveWidget())

    // ベストプラクティス: 一度だけ構築
    FadeTransition(
      opacity: Tween(begin: 0.0, end: 1.0).animate(controller),
      child: ExpensiveWidget(),
    )
    ```

!!! warning "画面外で動くアニメーションは、バッテリーを消費する"
    - `SingleChildScrollView` の中の `CircularProgressIndicator` は、画面外でも回り続ける。
    - 動画配信アプリの例: 90 分で 47% 消費していたのが、`ListView.builder` による遅延描画で 16% になった（寿命が約 3 倍）。

## 起動時間

- 目標は、コールドローンチ 2 秒以内（ユーザーの 49% が期待する）。シンプルなアプリなら 800ms 未満。
- 起動の順序: Engine と Dart VM の初期化 → Dart アイソレートの起動 → `main()` の実行 → 初回フレームの描画。
- 改善策:
    - `main()` の作業を最小化する。独立した初期化は `Future.wait` で並列にする。実測で 2500ms → 600ms（76% 改善）。
    - 重い初期化は、`addPostFrameCallback()` や `Future.delayed()` で遅らせる。
    - 重い計算（大きな JSON のパースなど）は、`compute()` で別アイソレートに移す。
    - 非クリティカルな機能は、deferred import で遅延読み込みする。初回ロードを 30-50% 減らせる。
    - プラグインとサービスは、必要になるまで初期化しない。
- 測定は `flutter run --profile --trace-startup` で行い、`build/start_up_info.json` の `timeToFirstFrameMicros` を見る。

??? example "コード例: 並列初期化と deferred import（14 行）"
    ```dart
    // アンチパターン: 逐次初期化
    await initDatabase();
    await initAnalytics();

    // ベストプラクティス: 並列初期化
    await Future.wait([initDatabase(), initAnalytics(), initPrefs()]);

    // deferred import
    import 'package:my_app/heavy_feature.dart' deferred as heavyFeature;
    await heavyFeature.loadLibrary();
    ```

## ビルドサイズの削減

| 手法 | コマンド | 効果 |
|---|---|---|
| Tree Shaking | `flutter build apk --release`（自動） | MaterialIcons 1645KB → 10KB、CupertinoIcons 283KB → 1.5KB |
| ABI 別 APK 分割 | `flutter build apk --split-per-abi` | ユニバーサル APK 50MB → 各 5MB（90% 削減） |
| App Bundle（推奨） | `flutter build appbundle` | ユニバーサル APK より 30-40% 小さい |
| サイズ分析 | `flutter build apk --analyze-size` | 何が大きいかを特定する |

- 画像フォーマットの選び方:

    | 用途 | フォーマット |
    |---|---|
    | 写真 | WebP（最高の圧縮率）または JPEG |
    | グラフィック / UI | PNG または SVG |
    | アイコン | SVG |
    | アニメーション | Lottie JSON（GIF より小さい） |

- 総合的な最適化（WebP 変換で 25-35% 削減）で、60-75% のサイズ削減が可能。未使用リソースの削除でも APK が 18% 削減された事例がある。

## Firebase Performance Monitoring

- 本番環境の性能を追跡する、公式サポートの無料ツール。
- 起動時間とネットワークリクエストは自動で収集する。特定のコードを測るカスタムトレースにも対応する。

!!! warning "Flutter では、画面レンダリングの自動監視が使えない"
    Flutter のアーキテクチャ上、個別の Flutter スクリーンについて、自動の画面レンダリング監視は利用できない。

!!! tip "このプロジェクトの実装"
    - トレースの共通化は、`lib/core/services/performance_monitoring_service.dart`（`PerformanceMonitoringService`）にある。
    - 計測したい処理は、トレースを直接書かず、このサービスで包む。

### セットアップ

1. `flutter pub add firebase_performance` でプラグインを追加する。
2. `flutterfire configure` で Firebase を設定する。
3. アプリを再ビルドし、バックグラウンド / フォアグラウンドの切り替え、画面遷移、ネットワークリクエストを起こす。
4. 数分以内に、Firebase Console のパフォーマンスダッシュボードにデータが出る。

### カスタムトレースとネットワーク監視

- カスタムトレース: `FirebasePerformance.instance.newTrace(名前)` で作り、`start()` と `stop()` で挟む。既定のメトリックは継続時間。カスタムメトリック（キャッシュヒットなど）も足せる。
- `traceWrapper`: 関数をラップして、実行時間と成否（`success` 属性）を記録する。API リクエストと DB 保存の時間を、別々に記録できる。
- ネットワーク: 標準の HTTP ライブラリは自動で監視される。**Dio は手動の計装が必要**で、インターセプターで `HttpMetric` を作る。
    - `onRequest`: `newHttpMetric()` で作り、`start()` し、リクエストサイズを記録する。
    - `onResponse`: レスポンスサイズとステータスコードを記録し、`stop()` する。

??? example "コード例: カスタムトレースと Dio インターセプターの骨格（22 行）"
    ```dart
    final Trace trace = FirebasePerformance.instance.newTrace('heavy_operation_trace');
    await trace.start();
    await someExpensiveOperation();
    await trace.stop();

    class PerformanceInterceptor extends Interceptor {
      final _performance = FirebasePerformance.instance;

      @override
      Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
        final metric = _performance.newHttpMetric(options.uri.toString(), HttpMethod.Get);
        await metric.start();
        options.extra['metric'] = metric;
        handler.next(options);
      }

      @override
      Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
        final metric = response.requestOptions.extra['metric'] as HttpMetric?;
        metric?.httpResponseCode = response.statusCode ?? 0;
        await metric?.stop();
        handler.next(response);
      }
    }
    ```

### Firebase Console でのデータ分析

- メトリクスボード（上部）: 最大 6 つのメトリクスを、トレンドと変化率で表示する。既定は 90 パーセンタイル。
    - 色の意味は、赤が負のトレンド、緑が正のトレンド、グレーが中立。
- トレーステーブル（下部）: タブはカスタムトレース、ネットワークリクエスト、画面レンダリング。パーセンタイルと時間範囲（24 時間・7 日・30 日・カスタム）で絞れる。
- 属性（アプリバージョン、国、デバイス、OS バージョン、ネットワークタイプ）で絞り込み、原因を深掘りする。

??? info "パーセンタイルの読み方"
    | パーセンタイル | 意味 | 使いどころ |
    |---|---|---|
    | P50 | 中央値 | 典型的なユーザー体験の理解 |
    | P90 | 90% のユーザーがこれより良い。Android Vitals の標準 | Android Vitals への準拠の確認 |
    | P95 / P99 | 上位 5% / 1% の最悪の体験 | エッジケースの特定 |

## 症状別のトラブルシューティング

各症状の原因と解決策は、上の該当節にある。ここでは、調べ方と固有の対処をまとめる。

| 症状 | 調べ方 | 解決策 |
|---|---|---|
| 過度な再ビルド（小さな変更でツリー全体が再構築される） | Android Studio の Widget Rebuild Profiler、DevTools の「Display widget rebuilds」、`debugRepaintRainbowEnabled = kDebugMode` | 「UI・レンダリングの最適化」の節。`BlocBuilder` は `buildWhen` で絞る |
| メモリリーク（徐々にメモリが増え、クラッシュする） | Memory View の Diff Snapshots、クラス別オブジェクト数、`ImageCache` の肥大化、テストで `leak_tracker_flutter_testing` | 「一般的なメモリリークの原因」の表 |
| 低速スクロール（FPS が 60 を下回る） | パフォーマンスオーバーレイ、Timeline の赤フレーム、「Track layouts」で過度な intrinsic パスを確認 | 「リストとスクロール」の節。ネスト時は Sliver、アイテムは `StatelessWidget` に抽出し、スクロールコールバックで `setState()` を呼ばない |
| 低速起動（初回フレームまで 2 秒以上、黒画面） | `--trace-startup`、Timeline の「Framework initialization」と「First frame rasterized」、Logcat の「Displayed」、本番は Firebase Performance Monitoring | 「起動時間」の節 |
| シェーダーコンパイルジャンク（初回アニメーションのカクつき） | Timeline の濃い赤・黒のバー | Impeller（下記）。使えない場合は下の手順 |

!!! success "Impeller で、シェーダーコンパイルジャンクは大幅に軽減"
    - Flutter 3.10 以降、Impeller が iOS で既定になった。
    - 実測: Flutter 3.3.10 で 4.4ms だったシェーダーコンパイル時間が、3.10.6 では消えた。
    - Performance View で、赤・黒の Shader Compilation バーが出ないことを確認できる。

??? info "Impeller を使えない場合: SkSL を手動でプリコンパイルする手順"
    1. 全アニメーションを実行しながら、アプリを動かす（`flutter run --profile --cache-sksl`）。
    2. `M` キーを押して、シェーダーキャッシュを書き込む。
    3. プリコンパイル済みのシェーダーでビルドする（`flutter build apk --bundle-sksl-path=flutter_01.sksl.json`）。

??? example "事例: BlocBuilder の再ビルドを絞る（17 行）"
    ```dart
    // 悪い例: Column 全体を再構築
    BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => Column(children: [Text(state.profile.name), CreatePostForm(), Posts()]),
    )

    // 良い例: Text だけ再構築
    Column(children: [
      BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) => previous.profile.name != current.profile.name,
        builder: (context, state) => Text(state.profile.name),
      ),
      CreatePostForm(),
      Posts(),
    ])
    ```

??? example "事例: Impeller のメモリリークによる Out of Memory（日本の技術記事）"
    - 症状: 画面遷移のたびに数百 MB 単位でメモリが増え、10 問で 3GB を超えて Out of Memory になった。
    - 原因: Impeller のバグ（`DecorationImage` で `AssetImage` を使用）。
    - 効果がなかった方法: `imageCache.clear()`、`AssetImage.evict()`、手動のガベージコレクション、`MemoryImage` への変更。
    - 最終的な解決策（どちらか）:
        - `AndroidManifest.xml` で `io.flutter.embedding.android.EnableImpeller` を `false` にする。
        - 実行時に `flutter run --no-impeller` を使う。

## 測定値とベンチマーク

| 対象 | 変化 | 効果 |
|---|---|---|
| `const` ウィジェット | スクロールあたり 847 → 228 再ビルド | 73% 削減 |
| `ListView.builder` | 10,000 件のロード 10 秒 → 1 秒未満 | 10 倍高速化 |
| `itemExtent` | 末尾へのジャンプ 10 秒 → 瞬時 | 100 倍高速化 |
| `cached_network_image` | 500ms のリロード → 0ms（キャッシュ済み） | 瞬時化 |
| `FadeTransition` vs `Opacity` | 32ms → 12ms/フレーム | 2.7 倍高速化 |
| SkSL ウォームアップ（Moto G4） | 最悪フレーム 90ms → 40ms | 56% 高速化 |
| SkSL ウォームアップ（iPhone 4s） | 最悪フレーム 300ms → 80ms | 73% 高速化 |

## 実装チェックリスト

### 避けること

- 同期的な重い処理で、UI スレッドをブロックしない。
- 不必要に `operator ==` をオーバーライドしない（ウィジェット比較のコストが増える）。
- 深くネストしたウィジェットツリーを作らない。ウィジェットは、メソッドではなくクラスに分割する。
- DevTools プロファイラーの警告を無視しない。

### プロファイリングの流れ

- [ ] プロファイルモードで、最低スペックの実機を使い、他のアプリを閉じてビルドする。
- [ ] パフォーマンスのベースラインを取る。
- [ ] 特定のユーザーフローを記録し、前後のスナップショットと再現手順をメモする。
- [ ] Timeline のジャンク、CPU のホットスポット、メモリのトレンド、ネットワーク呼び出しを確認する。

### 最適化の優先順位

1. UI スレッドの問題を最初に直す（過度な再ビルド → メモリリーク → レンダリング問題の順）。
2. 高価なメソッドを最適化する。
3. ウィジェットの再ビルドを減らす。
4. 画像を最適化する。
5. 測定して、改善を検証する。

### 継続的監視

- [ ] Firebase Performance Monitoring を統合し、重要な処理にカスタムトレースを足す。
- [ ] パフォーマンスアラートを設定する。
- [ ] 自動化されたパフォーマンステストを CI/CD に統合し、リグレッションを追跡する。
