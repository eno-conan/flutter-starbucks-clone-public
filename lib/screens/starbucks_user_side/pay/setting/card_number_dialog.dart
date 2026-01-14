import 'package:flutter/material.dart';
import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

class PaySettingPageDialogCardNumber extends StatelessWidget {
  const PaySettingPageDialogCardNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showStarExpirationModal(context);
      },
      child: Padding(
        padding: EdgeInsets.only(right: 15),
        child: MyCustomText(text: 'カード番号', textColor: MyColors.greenText, fontSize: 16),
      ),
    );
  }
}

/// カード番号のダイアログ
void _showStarExpirationModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルトの40から縮小
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 5),
              const MyCustomText(text: '1234 5678 9012 3456', fontSize: 20),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: .end,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: MyColors.greenButton,
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      minimumSize: const Size(0, 35), //これで垂直方向の余白を狭くできた
                    ),
                    child: const MyCustomText(
                      text: '閉じる',
                      textColor: Colors.white,
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
