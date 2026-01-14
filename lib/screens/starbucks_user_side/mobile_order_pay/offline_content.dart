// オフライン時の表示画面
import 'package:flutter/material.dart';
import '../../../constants/my_colors.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

class OfflineContents extends StatelessWidget {
  const OfflineContents({super.key, required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: .start,
        spacing: 30,
        children: [
          const SizedBox(height: 100), //オフラインを示すイラスト
          const MyCustomText(text: '通信エラーが発生しました。', fontSize: 20, fontWeight: FontWeight.bold),
          const MyCustomText(
            text: 'インターネット接続をご確認の上、再度お試しください',
            fontSize: 14,
            textColor: MyColors.greyText,
            fontWeight: FontWeight.bold,
          ),
          _ButtonReConnect(onRefresh: onRefresh), //再接続ボタン
        ],
      ),
    );
  }
}

///再接続ボタン
class _ButtonReConnect extends StatelessWidget {
  const _ButtonReConnect({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        onRefresh();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: MyColors.greenButton,
        side: const BorderSide(color: MyColors.greenButton),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        minimumSize: const Size(0, 35), //垂直方向の余白調整
      ),
      child: const MyCustomText(
        text: 'もう一度試す',
        textColor: MyColors.greenText,
        // fontWeight: FontWeight.w700,
      ),
    );
  }
}
