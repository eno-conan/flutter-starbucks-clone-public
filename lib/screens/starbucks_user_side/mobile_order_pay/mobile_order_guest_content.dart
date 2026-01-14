// 未ログイン時の表示コンテンツ
import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../constants/my_colors.dart';
import '../../../shared/helpers/launch_url.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

//未ログイン時の表示
const String notLoginedCardSvgPath = 'assets/starbucks/svg/pay_not_logined.svg';

class MobileOrderGuestContent extends StatelessWidget {
  const MobileOrderGuestContent({super.key});

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
          Column(
            crossAxisAlignment: .start,
            spacing: 20,
            children: [
              const MyCustomText(text: 'ご利用にはログインが必要です', fontSize: 18),
              const MyCustomText(
                text:
                    'Mobile Order & Payは事前に注文と決済を行い、店舗で商品を受け取れるサービスです\n登録済みスターバックス カードでのお支払いで、Starがたまります',
                textColor: Color(0xFFA4A4A4),
                fontSize: 16,
                softwrap: true,
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.30,
                height: MediaQuery.sizeOf(context).height * 0.04,
                child: OutlinedButton(
                  onPressed: () {
                    launchURL(Uri.parse('https://www.starbucks.co.jp/mobileorder/guide/'));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MyColors.greenButton,
                    // backgroundColor: Colors.white,
                    side: const BorderSide(color: MyColors.greenButton),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: const MyCustomText(
                    text: 'ご利用ガイド',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    textColor: MyColors.greenButton,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
