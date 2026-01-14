///データベースのテーブル名管理の定数クラス
class Tables {
  // 店舗情報
  static const String stores = 'stores';
  // ユーザトークン情報
  static const String userFcmTokens = 'user_fcm_tokens';
  //仮登録の会員情報
  static const String preSignupUsers = 'pre_signup_users';
  // ユーザメール設定情報
  static const String userMailSettings = 'user_mail_settings';
  // ユーザ詳細情報
  static const String userProfileDetails = 'user_profile_details';
  // ユーザニックネーム
  static const String userNickname = 'user_nickname';
  // カード情報
  static const String cards = 'cards';
  // カート情報
  static const String carts = 'carts';
  // カート詳細
  static const String cartsDetail = 'carts_detail';
  // 商品情報
  static const String products = 'products';
  // オーダー情報
  static const String orders = 'orders';
  // スター獲得情報
  static const String starAcquisitions = 'star_acquisitions';
  // スター集計テーブル
  static const String starAggregations = 'star_aggregations';
  // キャンペーン設定テーブル
  static const String campaignSettings = 'campaign_settings';
  // POC Realtime テーブル
  static const String pocRealtime = 'poc_realtime';
}
