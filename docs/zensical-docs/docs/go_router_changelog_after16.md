# go_routerの更新履歴

https://pub.dev/packages/go_router/changelog

## 17.1.0

* `TypedQueryParameter` アノテーションを追加。`TypedGoRoute` コンストラクタでパラメータ名をオーバーライドできるようになりました。

## 17.0.1

* `onEnter` がブロッキングされた際にナビゲーションスタックが消失する（古い状態の復元）問題を修正。
* サポートする最小SDKバージョンを **Flutter 3.32 / Dart 3.8** に更新。

## 17.0.0

> [!CAUTION]
> **BREAKING CHANGE (破壊的変更)**

* `ShellRoute` のナビゲーション変更が、デフォルトで `GoRouter` のオブザーバーに通知されるようになりました。
* `ShellRouteBase`, `ShellRoute`, `StatefulShellRoute`, `ShellRouteData.$route`, `TypedShellRoute`, `TypedStatefulShellRoute` に `notifyRootObserver` を追加。

## 16.3.0

* 現在のルート状態と次のルート状態にアクセス可能なトップレベルの `onEnter` コールバックを追加。

## 16.2.5

* Zoneベースのコンテキストトラッキングにより、`redirect` コールバック内での `GoRouter.of(context)` へのアクセスを修正。
* `redirect` コールバック内でのコンテキスト拡張メソッド（例: `context.namedLocation()`, `context.go()`）の使用をサポート。

## 16.2.4

* Androidのコールドスタート時、空のパスを持つディープリンクでスキームとオーソリティが消失する問題を修正。

## 16.2.3

* iOSの戻るジェスチャーで、アクティブなサブグループではなく `ShellRoute` 全体がポップされてしまう問題を修正。

## 16.2.2

* README内のリンク切れを修正。

## 16.2.1

* ドキュメントに状態復元（State Restoration）のトピックを追加。

## 16.2.0

* `RelativeGoRouteData` と `TypedRelativeGoRoute` を追加。
* サポートする最小SDKバージョンを **Flutter 3.29 / Dart 3.7** に更新。

## 16.1.0

* `go_router_builder` 用に、カスタム文字列エンコーダー/デコーダーを有効にするアノテーションを追加（#110781）。
* ※ `go_router_builder` バージョン 3.1.0 以上が必要です。



## 16.0.0

> [!CAUTION]
> **BREAKING CHANGE (破壊的変更)**

* `GoRouteData` の破壊的変更に伴い、メジャーバージョンをアップ。
* (旧 15.2.4) 大文字小文字が異なるURL（例: `/Home` と `/home`）を個別のルートとして扱うよう修正。
* (旧 15.2.3) 「Type-safe routes」のドキュメントを `go_router_builder 3.0.0` のミックスインを使用するように更新。
* (旧 15.2.2) ブランチルートでの `PopScope.onPopInvokedWithResult` の呼び出しを修正。
* (旧 15.2.1) Webにおいて、状態のポップとスキャフォールドの再レンダリングが同時に発生した際にURLが更新されない問題を修正。
* (旧 15.2.0) 型安全なルーティングのために、`GoRouteData` に `.location`, `.go(context)`, `.push(context)`, `.pushReplacement(context)`, `.replace(context)` を定義。
* ※ `go_router_builder` バージョン 3.0.0 以上が必要です。



---

こちらの内容で、特定の変更点についての詳細な解説や、実装例の作成などお手伝いできることはありますか？