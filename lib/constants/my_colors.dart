import 'package:flutter/material.dart';

///カラーパレット
///https://medium.com/@kanellopoulos.leo/a-simple-way-to-organize-your-styles-themes-in-flutter-a0e7eba5b297
class MyColors {
  //テキスト
  static const greenText = Color(0xFF00AA5E);
  static const greyText = Color(0xFF969696);
  static const darkGreenText = Color(0xFF1E3932);
  static const errorMessageText = Color(0xFFD7635B);
  // 背景色
  static const backgroundGrey = Color(0xFFF7F7F7);
  static const backgroundGold = Color(0xFFCFA05A);
  // スターポイント
  static const starGaugeColor = Color(0xFFCCA258);
  static const starMarkerColor = Color(0xFFF0E5CF);
  static const starBackGroundColor = Color(0xFFECEBE9);
  // ボタン
  static const fabGreenButton = Color(0xFF01A868);
  static const greenButton = Color(0xFF00AA5E);
  static const greyButton = Color(0xFFCECDCD);
  static const darkGreenButton = Color(0xFF1E3932);
  // ヘッダー
  static const circularProgressIndicatorColor = Color(0xFF00AA5E); // 読み込み時のLoading表示
  static const relatedRewardsHeaderColor = Color(0xFF1E3932); //スターリワード関連Widgetのヘッダー色
  static const headerLeadingIcon = Color(0xFF6C6C6C); //ヘッダーの戻る・閉じるアイコン色
  //区切り線
  static const horizontalDivider = Color(0xFFC2C2C2); //区切り線（セクション区切り用）
  static const settingDivider = Color(0xFFE1E1E1); //区切り線の色（設定画面）
  static const boxShadow = Color(0xFFEBEBEB);
  // ログインフォーム
  static const loginFormField = Color(0xFF17C079);
  static const textFieldFill = MyColors.boxShadow;
  static const textFieldborderSide = Color(0xFFD5D5D5);
  static const textFieldLabel = Color(0x8F8F9492);
}
