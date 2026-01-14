///データべース関数（rpc）の定義
class Rpcs {
  // 新規会員登録でメールアドレスの重複判定する関数
  static const String checkSignupEmailExists = 'check_signup_email_exists';
  // 有効期限切れしていないポイントを取得する関数
  static const String getTotalPointsWithExpirationFlagZero =
      'get_total_points_with_expiration_flag_zero';
  // ドライブスルー対象店舗かどうかを取得する関数
  static const String getSelectStoreDriveThruStatus = 'get_select_store_drive_thru_status';
  // モバイルオーダーのユーザー情報取得
  static const String getUserOrders = 'get_user_orders';
  // 現在地に近い店舗を取得する関数
  static const String getNearbyStores = 'get_nearby_stores';
  // 商品情報を取得
  static const String getProductsWithSizesAndCategories = 'get_products_with_sizes_and_categories';
  // 選択商品の情報を取得
  static const String getProductById = 'get_product_by_id';
  // カート詳細情報を取得
  static const String getCartDetails = 'get_cart_details';
  // カート概要と店舗情報を取得
  static const String getCartWithStore = 'get_cart_with_store';
  // 注文情報を取得（概要と詳細）
  static const String getUsersOrdersWithFullDetails = 'get_users_orders_with_full_details';
  // 注文情報を一括登録（概要と詳細）
  static const String createOrderWithDetails = 'create_order_with_details';
  // 獲得スター数の計算を行う関数
  static const String handleStarAcquisition = 'handle_star_acquisition';
  // 利用した場合のスター数残高を取得する関数
  static const String useStarPoints = 'use_star_points';
  // 未使用チケット（有効期限内）を取得する関数
  static const String getUserAvailableTickets = 'get_user_available_tickets';
  // 使用済チケット（有効期限内）を取得する関数
  static const String getUserUsedTickets = 'get_user_used_tickets';
  // 店舗側
  static const String getStoreOrders = 'get_store_order_list';
}
