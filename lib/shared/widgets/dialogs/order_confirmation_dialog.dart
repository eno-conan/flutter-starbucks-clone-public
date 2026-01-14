import 'package:flutter/material.dart';

import '../../../constants/my_colors.dart';
import '../../../core/models/cart.dart';
import '../texts/my_custom_text.dart';

/// 注文確定確認ダイアログを表示するメソッド
///
/// このダイアログは注文内容の最終確認のみを行います。
/// 店舗営業状況の検証、エラーハンドリング、CircularProgressIndicator表示は
/// 呼び出し元で実施済みであることを前提としています。
void showOrderConfirmationDialog(
  BuildContext context,
  Future<void> Function() processSettlement,
  Cart? cart,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isProcessing = false;

          Future<void> handleSettlement() async {
            setState(() {
              isProcessing = true;
            });

            // 確認ダイアログを閉じる
            Navigator.of(context).pop();

            // 決済処理を実行（検証・エラーハンドリングは呼び出し元で実施）
            await processSettlement();
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: .start,
                children: [
                  const SizedBox(height: 5),
                  const MyCustomText(text: '注文を確定します', fontSize: 20, fontWeight: FontWeight.bold),
                  const SizedBox(height: 15),
                  const MyCustomText(text: '利用店舗', fontSize: 14),
                  if (cart != null)
                    MyCustomText(
                      text: cart.storeName ?? '',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  const SizedBox(height: 15),
                  const MyCustomText(text: '注文確定とともに・・・', fontSize: 14, softwrap: true),
                  const MyCustomText(
                    text: '受取時間は多少前後するかもしれません。',
                    fontSize: 10,
                    textColor: MyColors.greyText,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    spacing: 15,
                    mainAxisAlignment: .end,
                    children: [
                      OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MyColors.greenButton,
                          side: BorderSide(color: MyColors.greenButton, width: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          minimumSize: const Size(0, 32),
                          splashFactory: InkSplash.splashFactory,
                        ),
                        child: const MyCustomText(text: 'キャンセル', textColor: MyColors.greenButton),
                      ),
                      FilledButton(
                        onPressed: isProcessing
                            ? null
                            : () {
                                handleSettlement();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: MyColors.greenButton,
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          minimumSize: const Size(0, 35),
                        ),
                        child: const MyCustomText(text: 'OK', textColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
