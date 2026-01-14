import 'package:flutter/material.dart';
import '../../../constants/my_colors.dart';
import '../texts/my_custom_text.dart';

/// 商品削除確認ダイアログを表示するメソッド
void showProductDeleteConfirmationDialog(BuildContext context, VoidCallback deleteAction) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            spacing: 5,
            crossAxisAlignment: .start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MyCustomText(text: '商品を削除します', fontSize: 24, softwrap: true),
              const SizedBox(height: 5),
              const MyCustomText(text: '選択した商品をオーダーから削除します', fontSize: 14, softwrap: true),
              const SizedBox(height: 5),
              const MyCustomText(
                text: '※選択中のeTicketも同時に利用解除されます（ここどうやって実装するんだろう？）',
                fontSize: 10,
                softwrap: true,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: .end,
                spacing: 15,
                children: [
                  OutlinedButton(
                    onPressed: () {
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
                    onPressed: () {
                      deleteAction();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: MyColors.greenButton,
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      minimumSize: const Size(0, 32),
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
}
