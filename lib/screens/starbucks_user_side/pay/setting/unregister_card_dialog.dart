import 'package:flutter/material.dart';
import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

/// カード登録解除
class PaySettingPageDialogUnregisterCard extends StatelessWidget {
  const PaySettingPageDialogUnregisterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // タップした瞬間を記録
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);

          // InkWellのデフォルトsplashアニメーションは約300ms
          await Future<void>.delayed(const Duration(milliseconds: 300));

          // コンテキストの有効性チェック
          if (navigator.mounted && scaffoldMessenger.mounted) {
            _showStarExpirationModal(navigator.context);
          }
        },
        // InkWellを最大限に広げる
        child: Container(
          // alignment: Alignment.center,
          height: MediaQuery.sizeOf(context).height * 0.08,
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: MyColors.settingDivider, // 枠線の色
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              spacing: 25,
              children: const [
                Icon(Icons.do_not_disturb_on_outlined),
                MyCustomText(text: 'カード登録解除'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// カード登録解除ダイアログ内容
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
              const MyCustomText(text: 'このカードは登録解除できません', fontSize: 24, softwrap: true),
              const SizedBox(height: 5),
              const MyCustomText(
                text: '利用を停止・終了されたい場合は、紛失届・利用停止からお手続きください。',
                fontSize: 14,
                softwrap: true,
              ),
              const SizedBox(height: 5),
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
