# ナビゲーションフロー図

このドキュメントは、Starbucksアプリクローンのナビゲーション構造を視覚的に示します。

## 概要

アプリは以下の主要なフローで構成されています：

1. **認証フロー**: アカウント作成・ログイン
2. **メインアプリ**: ボトムナビゲーション（5タブ）
3. **サブフロー**: 各機能の詳細画面
4. **POCセクション**: 開発・テスト用

## 詳細フロー図

### 1. 認証・初期フロー

```mermaid
graph TD
    A[App Start] --> B[Menu Page /menu]
    B --> C[Pre SignUp /pre-signup]
    C --> D[Pre SignUp Completion /pre-signup-completion]
    D --> E[SignUp /signup]
    E --> F[SignUp Completion /signup-completion]
    E --> G[SignUp Error /signup-error]
    B --> H[Login /login]
    H --> I[Main App]
    F --> I
```

### 2. メインアプリ（ボトムナビゲーション）

```mermaid
graph TD
    A[Main App] --> B[ScaffoldWithCustomNavBar]
    B --> C[Home Tab /home]
    B --> D[Pay Tab /pay]
    B --> E[Store Tab /store]
    B --> F[Mobile Order Tab /mobile-order]
    B --> G[Gift Tab /gift]
    
    C --> C1[Setting /setting]
    C --> C2[eTicket /e-ticket]
    C --> C3[Inbox /inbox]
    C --> C4[Star Reward Exchange /star-reward-exchange]
    C --> C5[Rewards /rewards]
    
    D --> D1[Pay Payment /pay/payment]
    D --> D2[Pay Setting /pay/setting]
    
    F --> F1[Store Selection /mobile-order/store]
    F --> F2[Pickup Method /mobile-order/pickup-method]
    F --> F3[Products /mobile-order/products]
    F --> F4[Selected Product /mobile-order/product-selected]
    F --> F5[Order History Detail /mobile-order/histories/detail]
    
    G --> G1[E-Gift Creation /gift/egift]
```

### 3. 設定・詳細フロー

```mermaid
graph TD
    A[Setting /setting] --> B[Switch Notify Setting /setting/switch-notify]
    
    C[eTicket /e-ticket] --> D[eTicket Use In Store /e-ticket/use-in-store]
    
    E[Rewards /rewards] --> F[Member Status]
    E --> G[Star History]
    
    H[Pay Payment /pay/payment] --> I[Deposit Screen /pay/payment/deposit]
```

### 4. モバイルオーダーフロー詳細

```mermaid
graph TD
    A[Mobile Order Container /mobile-order] --> B{Tab Selection}
    B --> C[Order Tab]
    B --> D[History Tab]
    B --> E[Favorites Tab]
    
    C --> F[Store Selection /mobile-order/store]
    F --> G[Pickup Method /mobile-order/pickup-method]
    G --> H[Products /mobile-order/products]
    H --> I[Selected Product /mobile-order/product-selected]
    I --> J[Order Success /order-success]
    
    D --> K[History Detail /mobile-order/histories/detail]
```

### 5. POC開発用フロー

```mermaid
graph TD
    A[POC Main] --> B[POC ScaffoldWithNavBar]
    B --> C[POC Home /poc-home]
    B --> D[Search /search]
    B --> E[Profile Container /profile]
    
    E --> F{Profile Tabs}
    F --> G[Tab1: Widget A]
    F --> H[Tab2: Widget D]
    
    G --> I[Widget B /profile/tab1/widget-b]
    I --> J[Widget C /profile/tab1/widget-b/widget-c]
    
    H --> K[Widget E /profile/tab2/widget-e]
    K --> L[Widget F /profile/tab2/widget-e/widget-f]
    K --> M[Widget G /profile/tab2/widget-e/widget-g]
    M --> N[Widget H /profile/tab2/widget-e/widget-g/widget-h]
```

### 6. 店舗側フロー

```mermaid
graph TD
    A[Store Side] --> B[Order List /store-side/orders]
```

## ルート情報

### 主要ルートパス一覧

#### 認証関連
- `/menu` - メニュー画面
- `/pre-signup` - 新規会員仮登録
- `/pre-signup-completion` - 仮登録完了
- `/signup` - 新規会員登録
- `/signup-completion` - 本登録完了
- `/signup-error` - 登録失敗
- `/login` - ログイン

#### メインタブ
- `/home` - ホーム
- `/pay` - 支払い
- `/store` - 店舗
- `/mobile-order` - モバイルオーダー
- `/gift` - ギフト

#### サブフロー
- `/setting` - 設定
- `/setting/switch-notify` - 通知設定
- `/e-ticket` - eチケット
- `/e-ticket/use-in-store` - 店内利用
- `/inbox` - インボックス
- `/star-reward-exchange` - スターリワード交換
- `/rewards` - リワード
- `/pay/payment` - 支払い詳細
- `/pay/payment/deposit` - チャージ
- `/pay/setting` - 支払い設定
- `/order-success` - 注文完了
- `/gift/egift` - eギフト作成

#### モバイルオーダー関連
- `/mobile-order/store` - 店舗選択
- `/mobile-order/pickup-method` - 受取方法
- `/mobile-order/products` - 商品一覧
- `/mobile-order/product-selected` - 商品詳細
- `/mobile-order/histories/detail` - 注文履歴詳細

#### POC/開発用
- `/poc-home` - POCホーム
- `/search` - 検索
- `/profile` - プロフィールコンテナ
- `/profile/tab1/widget-b` - Widget B
- `/profile/tab1/widget-b/widget-c` - Widget C
- `/profile/tab2/widget-e` - Widget E
- `/profile/tab2/widget-e/widget-f` - Widget F
- `/profile/tab2/widget-e/widget-g` - Widget G
- `/profile/tab2/widget-e/widget-g/widget-h` - Widget H

#### 店舗側
- `/store-side/orders` - 注文一覧

## 特徴

### ナビゲーション構造
- **StatefulShellRoute.indexedStack**: メインアプリとPOCセクションで使用
- **ネストルート**: モバイルオーダーとPOCプロフィールで階層構造
- **カスタムトランジション**: 右から左、下から上のスライドアニメーション

### 状態管理
- タブインデックスをクエリパラメータで管理
- `extra`パラメータでデータ受け渡し
- ナビゲーション状態の永続化（StatefulShellRoute）

### パラメータ処理
- クエリパラメータ: `?tab=0`, `?data=value`
- Extraオブジェクト: 複雑なデータの受け渡し
- 型安全なパラメータ解析

## 注意事項

- メインアプリとPOCセクションは独立したナビゲーション構造
- 一部のルートはコメントアウトされており、将来の機能拡張に備えている
- アニメーション付きルートは`pageBuilder`を使用
- 通常のルートは`builder`を使用

このフロー図は`lib/config/app_router.dart`の実装に基づいて作成されています。