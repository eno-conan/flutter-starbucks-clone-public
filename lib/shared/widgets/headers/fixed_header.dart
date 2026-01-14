import 'package:flutter/material.dart';

import '../../../constants/my_colors.dart';
import '../signup_signin_floating_acttion_button.dart';
import '../texts/my_custom_text.dart';

/// Shader Compilation Jank軽減のため、
/// BoxShadowのblurRadiusを除去し、RepaintBoundaryで最適化済み

/// 汎用的なカスタム Scaffold
class FixedHeaderCommonComponent extends StatelessWidget {
  const FixedHeaderCommonComponent({
    super.key,
    required this.isLeadingIcon,
    this.icon,
    required this.headerText,
    this.headerTextColor,
    required this.body,
    this.appBarBackgroundColor,
    this.bodyBackgroundColor,
    this.onIconPressed,
    required this.isFab,
    this.fabWidget,
    this.actions,
  });
  final bool isLeadingIcon;
  final Icon? icon;
  final String headerText;
  final Color? headerTextColor;
  final Widget body;
  final Color? appBarBackgroundColor;
  final Color? bodyBackgroundColor;
  final VoidCallback? onIconPressed;
  final bool isFab;
  final Widget? fabWidget;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0, //背景色が灰色になるのを防ぐオプション
        automaticallyImplyLeading: false,
        backgroundColor: appBarBackgroundColor ?? Colors.white,
        leading: isLeadingIcon
            ? IconButton(
                icon: icon ?? Icon(Icons.arrow_back_ios),
                onPressed: onIconPressed,
                color: MyColors.headerLeadingIcon,
              )
            : null,
        actions: actions ?? [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              text: headerText,
              textColor: headerTextColor ?? Colors.black,
              backgroundColor: bodyBackgroundColor ?? Colors.white,
            ),
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: isFab ? fabWidget ?? SignupSignInFloatingActionButton() : null,
    );
  }
}

/// ヘッダーコンポーネント
class _Header extends StatelessWidget {
  const _Header({required this.text, required this.textColor, required this.backgroundColor});
  final String text;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    // RepaintBoundaryで再描画範囲を制限し、Raster負荷を軽減
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          // blurRadiusを削除し、offsetのみでシャドウ効果を軽量化
          border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: MyCustomText(text: text, fontSize: 28, textColor: textColor),
      ),
    );
  }
}
