import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../../shared/widgets/texts/my_custom_text.dart';

//未ログイン時の表示
const String notLoginedCardSvgPath = 'assets/starbucks/svg/pay_not_logined.svg';

///未ログイン時の表示コンテンツ
class PayNotLoginedContents extends StatelessWidget {
  const PayNotLoginedContents({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        spacing: 30,
        children: [
          const SizedBox(height: 5),
          VectorGraphic(
            loader: AssetBytesLoader(notLoginedCardSvgPath),
            // fit: BoxFit.cover,
            width: MediaQuery.sizeOf(context).width * 0.30,
            // width: 150,
          ),
          const Column(
            crossAxisAlignment: .start,
            spacing: 20,
            children: [
              MyCustomText(text: 'ご利用にはログインが必要です', fontSize: 18),
              MyCustomText(
                text: 'スターバックス カードを登録すると、レジでの支払い⼊⾦、その他便利な機能がご利用いただけます',
                textColor: Color(0xFFA4A4A4),
                fontSize: 16,
                softwrap: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
