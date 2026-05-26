# アーキテクチャ詳細

## Provider 詳細

### 認証系
| ファイル | Provider | 型 | 用途 |
|---|---|---|---|
| `lib/provider/auth_state_provider.dart` | `authStateProvider` | `StreamProvider<User?>` | Supabase onAuthStateChange ストリーム監視 |
| `lib/provider/auth_state_provider.dart` | `initialAuthStateProvider` | `FutureProvider<User?>` | 起動時の現在セッション取得 |

### 店舗系
| ファイル | Provider | 型 | 用途 |
|---|---|---|---|
| `lib/provider/stores_provider.dart` | `storeProvider` | `NotifierProvider<StoreNotifier, List<Map>>` | 全店舗リスト（Supabase stores テーブル） |
| `lib/provider/mobile_order_selected_store_provider.dart` | `mobileOrderSelectedStoreProvider` | — | モバイルオーダー用選択店舗 |
| `lib/provider/store_wait_time_provider.dart` | `storeWaitTimeProvider` | — | 店舗待ち時間（getStoreWaitTimes RPC） |

### 注文系
| ファイル | Provider | 型 | 用途 |
|---|---|---|---|
| `lib/provider/order_settlement_provider.dart` | `orderSettlementProvider` | `NotifierProvider<OrderSettlementNotifier, OrderSettlementState>` | 注文決済ステートマシン |
| `lib/provider/last_order_completion_provider.dart` | `lastOrderCompletionProvider` | — | 最終注文完了情報保持 |
| `lib/provider/mobile_order_selected_product_id_provider.dart` | `mobileOrderSelectedProductIdProvider` | — | 選択商品ID |

### UI状態系
| ファイル | Provider | 型 | 用途 |
|---|---|---|---|
| `lib/provider/selected_tab_provider.dart` | `selectedTabProvider` | — | BottomNavBar タブ選択 |
| `lib/provider/nickname_dialog_state_provider.dart` | `nicknameDialogStateProvider` | — | ニックネームダイアログ表示状態 |
| `lib/provider/responsive_dimensions_provider.dart` | `responsiveDimensionsProvider` | — | デバイスサイズ・レスポンシブ計算値 |

### システム系
| ファイル | Provider | 型 | 用途 |
|---|---|---|---|
| `lib/provider/location_state_provider.dart` | `locationStateProvider` | — | GPS現在地 |
| `lib/provider/connectivity_check_provider.dart` | `connectivityCheckProvider` | — | ネットワーク接続状態 |
| `lib/provider/e_ticket_provider.dart` | `eTicketProvider` | — | Eチケット一覧 |

---

## Service 詳細

### 認証・アカウント
| ファイル | クラス | 用途 |
|---|---|---|
| `lib/services/auth_service.dart` | `AuthService` | Google/Supabase認証・ログアウト |

### ホーム
| ファイル | クラス | 用途 |
|---|---|---|
| `lib/services/home/campaign_service.dart` | `CampaignService` | キャンペーン情報取得 |
| `lib/services/home/star_points_cache_service.dart` | `StarPointsCacheService` | スターポイントキャッシュ |
| `lib/services/home/star_aggregations_cache_service.dart` | `StarAggregationsCacheService` | スター集計キャッシュ |

### モバイルオーダー・注文
| ファイル | クラス | 用途 |
|---|---|---|
| `lib/services/mobile_order_pay/order_settlement_service.dart` | `OrderSettlementService` | 注文決済処理 |
| `lib/services/mobile_order_pay/order_creation_service.dart` | `OrderCreationService` | 注文作成（createOrderWithDetails RPC） |
| `lib/services/mobile_order_pay/order_validation_service.dart` | `OrderValidationService` | 注文前バリデーション |
| `lib/services/mobile_order_pay/star_acquisition_service.dart` | `StarAcquisitionService` | スター獲得処理 |
| `lib/services/mobile_order_pay/cache_service_products.dart` | — | 商品データキャッシュ |

### 店舗
| ファイル | クラス | 用途 |
|---|---|---|
| `lib/services/mobile_order_pay/store/store_cache_service.dart` | `StoreCacheService` | 店舗データキャッシュ |
| `lib/services/mobile_order_pay/store/tab_close_distance_store_service.dart` | — | 距離に基づくタブ管理 |
| `lib/services/mobile_order_pay/store/tab_favorite_stores_service.dart` | — | お気に入り店舗 |
| `lib/services/mobile_order_pay/store/update_cart_service.dart` | — | カート更新 |
| `lib/services/mobile_order_pay/store/store_availability_service.dart` | — | 店舗営業状況確認 |

### リワード
| ファイル | クラス | 用途 |
|---|---|---|
| `lib/services/rewards/star_history_service.dart` | `StarHistoryService` | スター履歴取得 |

### システム
| ファイル | クラス | 用途 |
|---|---|---|
| `lib/services/notification_permission_service.dart` | — | 通知権限リクエスト |
| `lib/core/services/logger_service.dart` | `LoggerService` | ロギング（info/warn/debug/error） |
| `lib/core/services/performance_monitoring_service.dart` | — | パフォーマンス計測 |

---

## Repository 詳細

| ファイル | 用途 |
|---|---|
| `lib/data/repository/cart.dart` | カート操作 (getCartDetails / getCartWithStore RPC) |
| `lib/data/repository/order.dart` | 注文操作 (getUsersOrdersWithFullDetails RPC) |
| `lib/data/repository/product.dart` | 商品情報 (getProductsWithSizesAndCategories RPC) |
| `lib/data/repository/store.dart` | 店舗情報 (getNearbyStores RPC) |
| `lib/data/repository/e_ticket_repository.dart` | Eチケット (getUserAvailableTickets / getUserUsedTickets RPC) |
| `lib/data/repository/user_fcm_tokens.dart` | FCMトークン管理 |

---

## RPC 定数一覧（lib/constants/supabase_rpcs.dart）

| 定数名 | RPC名 | 用途 |
|---|---|---|
| `getTotalPointsWithExpirationFlagZero` | `get_total_points_with_expiration_flag_zero` | 有効ポイント合計取得 |
| `getSelectStoreDriveThruStatus` | `get_select_store_drive_thru_status` | ドライブスルー対応確認 |
| `getUserOrders` | `get_user_orders` | ユーザー注文一覧 |
| `getStoreWaitTimes` | `get_store_wait_times` | 店舗待ち時間情報 |
| `getNearbyStores` | `get_nearby_stores` | 近隣店舗取得 |
| `getProductsWithSizesAndCategories` | `get_products_with_sizes_and_categories` | 商品一覧（サイズ・カテゴリ付き） |
| `getProductById` | `get_product_by_id` | 商品詳細取得 |
| `getCartDetails` | `get_cart_details` | カート詳細取得 |
| `getCartWithStore` | `get_cart_with_store` | カート＋店舗情報 |
| `getUsersOrdersWithFullDetails` | `get_users_orders_with_full_details` | 注文履歴（詳細付き） |
| `createOrderWithDetails` | `create_order_with_details` | 注文作成（概要＋詳細一括） |
| `handleStarAcquisition` | `handle_star_acquisition` | スター獲得計算 |
| `useStarPoints` | `use_star_points` | スター利用残高確認 |
| `getUserAvailableTickets` | `get_user_available_tickets` | 未使用チケット取得 |
| `getUserUsedTickets` | `get_user_used_tickets` | 使用済みチケット取得 |
| `getStoreOrders` | `get_store_order_list` | 店舗側注文一覧 |

---

## テーブル定数一覧（lib/constants/supabase_tables.dart）

| 定数名 | テーブル名 | 用途 |
|---|---|---|
| `stores` | `stores` | 店舗情報 |
| `userFcmTokens` | `user_fcm_tokens` | FCMトークン |
| `preSignupUsers` | `pre_signup_users` | 仮登録会員情報 |
| `userMailSettings` | `user_mail_settings` | メール設定 |
| `userProfileDetails` | `user_profile_details` | ユーザー詳細情報 |
| `userNickname` | `user_nickname` | ニックネーム |
| `cards` | `cards` | スターバックスカード情報 |
| `carts` | `carts` | カート概要 |
| `cartsDetail` | `carts_detail` | カート詳細 |
| `products` | `products` | 商品情報 |
| `orders` | `orders` | 注文概要 |
| `starAcquisitions` | `star_acquisitions` | スター獲得履歴 |
| `starAggregations` | `star_aggregations` | スター集計 |
| `campaignSettings` | `campaign_settings` | キャンペーン設定 |
| `pocRealtime` | `poc_realtime` | リアルタイムPOC |

---

## 画面ディレクトリ構成（主要）

```
lib/screens/
├── starbucks_user_side/
│   ├── home/               ホーム画面
│   ├── mobile_order_pay/   モバイルオーダー・決済
│   │   ├── tab_order/      注文タブ（商品一覧・カート）
│   │   └── tab_store/      店舗選択タブ
│   ├── rewards/            リワード・スター履歴
│   └── account/            アカウント設定
└── starbucks_store_side/   店舗スタッフ側画面
```
