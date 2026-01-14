import 'package:flutter/material.dart';
import '../../../../shared/helpers/launch_url.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

///Section:新商品
class HomeNewProductSection extends StatelessWidget {
  const HomeNewProductSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(
              AssetImage('assets/starbucks/png/new_product.png'),
              width: 1080, // 表示する幅に合わせたサイズ
              height: 562, // 表示する高さに合わせたサイズ
            ),
            fit: BoxFit.cover, // SizedBox全体を埋める
          ),
        ),
        child: InkWell(
          splashColor: Color(0x30f010f0),
          // 外部リンクを開く
          onTap: () => {launchURL(Uri.parse('https://www.starbucks.co.jp/cafe/royal-earlgrey/'))},
          child: const Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  crossAxisAlignment: .start,
                  children: <Widget>[SizedBox(height: 120), CheckDetailElevatedButton()],
                ),
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15), child: Column()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 詳細確認Button
class CheckDetailElevatedButton extends StatelessWidget {
  const CheckDetailElevatedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => {launchURL(Uri.parse('https://www.starbucks.co.jp/cafe/royal-earlgrey/'))},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
      child: MyCustomText(text: 'もっと見る', fontSize: 14.0, fontWeight: FontWeight.w500),
    );
  }
}
