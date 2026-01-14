import 'package:flutter/material.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

class TileContent {
  TileContent(this.imagePath, this.mainLabel, this.subLabel, this.url);
  final String imagePath;
  final String mainLabel;
  final String subLabel;
  final String url;
}

final tileContentList = <TileContent>[
  TileContent('assets/starbucks/png/egift_drink.png', '気軽にドリンクを贈りたい', '¥500 ~ ¥800', ''),
  TileContent('assets/starbucks/png/egift_drink_and_food.png', 'ドリンク&フードを贈りたい', '¥1,000 ~ ', ''),
  TileContent('assets/starbucks/png/egift_drink.png', '毎日使えるチケットセット', '¥1,500 ~ ¥21,000', ''),
  TileContent('assets/starbucks/png/egift_drink.png', 'みんなでつくる寄せ書き', '¥500 ~ ', ''),
];

/// タブ：eGiftを作る
class GiftEgiftTabCreateEgift extends StatelessWidget {
  const GiftEgiftTabCreateEgift({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0xFFF0F0F0),
      child: Column(
        children: [
          const SizedBox(height: 100, width: double.infinity),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: 4,
              physics: const ClampingScrollPhysics(), // 余計な伸びを防ぐ
              itemBuilder: (BuildContext context, int index) {
                return EachMenuTile(
                  imgPath: tileContentList[index].imagePath,
                  text: tileContentList[index].mainLabel,
                  subText: tileContentList[index].subLabel,
                );
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

///各メニュー
class EachMenuTile extends StatelessWidget {
  const EachMenuTile({super.key, required this.imgPath, required this.text, required this.subText});
  final String imgPath;
  final String text;
  final String subText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      children: [
        InkWell(
          onTap: () {},
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Color(0xFFD8D8D8), // 枠線の色
                  width: 0.25,
                ),
              ),
            ),
            child: Row(
              spacing: 15,
              mainAxisAlignment: .center,
              children: [
                ClipOval(
                  child: Image(
                    width: 70,
                    height: 70,
                    fit: BoxFit.fill,
                    // TODO:ネットワークからの取得に変更
                    image: AssetImage(imgPath),
                  ),
                ),
                Column(
                  crossAxisAlignment: .start,
                  mainAxisAlignment: .center,
                  children: [
                    MyCustomText(text: subText, textColor: Color(0xFF939191), fontSize: 14),
                    MyCustomText(
                      text: text,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                      fontSize: 16,
                    ),
                  ],
                ),
                const Spacer(),
                const Column(
                  mainAxisAlignment: .center,
                  children: [Icon(Icons.arrow_forward_ios_rounded, size: 16)],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
