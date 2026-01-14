import 'package:flutter/material.dart';
import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

/// 受付時間外の場合
void showCurrentlyClosedDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルトの40から縮小
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 5),
              const MyCustomText(
                text: 'Mobile オーダーは停止中です',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 15),
              const MyCustomText(
                text: '現在、この店舗では受付を停止しています。お時間をおいてお試しいただくか、別の店舗でご注文ください',
                fontSize: 14,
                softwrap: true,
              ),
              Row(
                mainAxisAlignment: .end,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: MyColors.greenButton,
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      minimumSize: const Size(0, 35), //これで垂直方向の余白を狭くできた
                    ),
                    child: const MyCustomText(
                      text: 'OK',
                      textColor: Colors.white,
                      useEnglishFont: true,
                      // fontWeight: FontWeight.w700,
                    ),
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
