//処理実行中のダイアログ表示
import 'package:flutter/material.dart';
import '../../../constants/my_colors.dart';

/// 処理実行中のダイアログ表示
void showCircularProgressIndicator(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(
            color: MyColors.circularProgressIndicatorColor,
            strokeWidth: 4.0,
          ),
        ),
      );
    },
  );
}
