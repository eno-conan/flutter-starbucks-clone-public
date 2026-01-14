import 'package:flutter/material.dart';
import '../../../constants/my_colors.dart';
import '../texts/my_custom_text.dart';

///オフライン時のダイアログ
void showOfflineDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24), // デフォルトの40から縮小
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 10),
              const MyCustomText(text: 'エラーが発生しました', fontSize: 20, fontWeight: FontWeight.bold),
              const SizedBox(height: 30),
              const MyCustomText(
                text: 'インターネット接続がありません。端末の設定を確認してください。',
                fontSize: 14,
                softwrap: true,
              ),
              const SizedBox(height: 30),
              Row(
                spacing: 10,
                mainAxisAlignment: .end,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: MyColors.greenButton,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      minimumSize: const Size(0, 35), //垂直方向の余白調整
                    ),
                    child: const MyCustomText(
                      text: 'OK',
                      textColor: Colors.white,
                      // fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}
