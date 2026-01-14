import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class CarouselSection extends StatefulWidget {
  const CarouselSection({super.key});

  @override
  State<CarouselSection> createState() => CarouselSectionState();
}

class CarouselSectionState extends State<CarouselSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        CarouselSlider(
          items: [
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: const Image(
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 100,
                  image: AssetImage('assets/starbucks/png/gift_carousel_1.png'),
                ),
              ),
            ),
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: const Image(
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 100,
                  image: AssetImage('assets/starbucks/png/gift_carousel_2.png'),
                ),
              ),
            ),
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image(
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 100,
                  image: AssetImage('assets/starbucks/png/gift_carousel_3.png'),
                ),
              ),
            ),
          ],
          options: CarouselOptions(
            height: 125, //高さ
            // initialPage: 0, //最初に表示されるページ
            // autoPlay: true, //自動でスライドしてくれるか
            viewportFraction: 1.2, //各カードの表示される範囲の割合
            enableInfiniteScroll: false, //最後のカードから最初のカードへの遷移
            autoPlayInterval: Duration(seconds: 5), //カードのインターバル
            autoPlayAnimationDuration: Duration(seconds: 1),
            //スライドが始まって終わるまでの時間
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: .center,
          children: [0, 1, 2].map((index) {
            return Container(
              width: 10.0,
              height: 10.0,
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? Color(0xFF047549) : Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
