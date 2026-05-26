# Starbucks Clone (Flutter) - Project Memory

## 技術スタック
- 状態管理: Riverpod 3.0 (Notifier API) ※ StateNotifierProvider 禁止
- ルーティング: go_router
- バックエンド: Supabase (認証・DB・ストレージ)
- 地図: Google Maps Flutter
- ログ: LoggerService (`lib/core/services/logger_service.dart`) info/warn 中心
- DI: get_it (`lib/config/service_locator.dart`)
- 環境変数: envied (`lib/app/env/`)
- Firebase: Crashlytics・Push通知

## ファイル配置規則
- 画面: `lib/screens/starbucks_user_side/` または `starbucks_store_side/`
- Provider: `lib/provider/*_provider.dart`
- Service: `lib/services/` または `lib/core/services/`
- Model: `lib/core/models/`
- Repository: `lib/data/repository/`
- 定数: `lib/constants/`
- 共通Widget: `lib/shared/widgets/`
- Config/初期化: `lib/config/`

## 重要ファイルパス
- エントリーポイント: `lib/app/app.dart`
- ルーター: `lib/config/app_router.dart`
- 初期化: `lib/config/app_initializer.dart`
- DI設定: `lib/config/service_locator.dart`
- RPC定数: `lib/constants/supabase_rpcs.dart`
- テーブル定数: `lib/constants/supabase_tables.dart`
- 色定義: `lib/constants/my_colors.dart`
- レスポンシブ: `lib/provider/responsive_dimensions_provider.dart`
- ログサービス: `lib/core/services/logger_service.dart`

## Provider 一覧（13個）
| Provider | 型 | 用途 |
|---|---|---|
| `authStateProvider` | StreamProvider<User?> | Supabase認証状態監視 |
| `initialAuthStateProvider` | FutureProvider<User?> | 初回認証状態取得 |
| `storeProvider` | NotifierProvider | 店舗一覧管理 |
| `storesProvider` | — | 近隣店舗 |
| `locationStateProvider` | — | 現在地管理 |
| `responsiveDimensionsProvider` | — | デバイスサイズ/レスポンシブ値 |
| `connectivityCheckProvider` | — | ネットワーク接続確認 |
| `selectedTabProvider` | — | BottomNavバータブ選択状態 |
| `mobileOrderSelectedStoreProvider` | — | モバイルオーダー選択店舗 |
| `mobileOrderSelectedProductIdProvider` | — | 選択商品ID |
| `nicknameDialogStateProvider` | — | ニックネームダイアログ状態 |
| `lastOrderCompletionProvider` | — | 最終注文完了情報 |
| `orderSettlementProvider` | NotifierProvider<OrderSettlementNotifier, OrderSettlementState> | 注文決済処理 |
| `eTicketProvider` | — | Eチケット管理 |
| `storeWaitTimeProvider` | — | 店舗待ち時間 |

## RPC 一覧（lib/constants/supabase_rpcs.dart）
`getTotalPointsWithExpirationFlagZero` / `getSelectStoreDriveThruStatus` /
`getUserOrders` / `getStoreWaitTimes` / `getNearbyStores` /
`getProductsWithSizesAndCategories` / `getProductById` / `getCartDetails` /
`getCartWithStore` / `getUsersOrdersWithFullDetails` / `createOrderWithDetails` /
`handleStarAcquisition` / `useStarPoints` / `getUserAvailableTickets` /
`getUserUsedTickets` / `getStoreOrders`

## テーブル一覧（lib/constants/supabase_tables.dart）
`stores` / `userFcmTokens` / `preSignupUsers` / `userMailSettings` /
`userProfileDetails` / `userNickname` / `cards` / `carts` / `cartsDetail` /
`products` / `orders` / `starAcquisitions` / `starAggregations` /
`campaignSettings` / `pocRealtime`

## 詳細ファイル
- [アーキテクチャ詳細](architecture.md)
- [実装パターン](patterns.md)
