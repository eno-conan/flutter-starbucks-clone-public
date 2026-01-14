import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../components/add_card_section.dart';
import '../components/fab_actions_section.dart';
import '../components/go_setting_button_section.dart';
import '../pay_screen.dart';

///ログイン時の表示コンテンツ
class PayLoginedContents extends StatelessWidget {
  const PayLoginedContents({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          spacing: 5,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                mainAxisAlignment: .end,
                children: [MyCustomText(text: 'カード追加', textColor: Colors.green, fontSize: 18)],
              ),
            ),
            _CustomScrollView(),
          ],
        ),
      ),
      floatingActionButton: PayFloatingActionButtons(),
    );
  }
}

/// CustomScrollView部分
class _CustomScrollView extends StatelessWidget {
  const _CustomScrollView();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: CustomScrollView(
        slivers: <Widget>[
          _SliverAppBar(),
          _CurrentMoneyBalance(), //残高表示
          _PayCard(), //デジタルカード
          PayButtonGoSettingPage(), //設定ボタン
          _OtherCardTitle(), //その他のカード
          PayAreaAddCard(), //カード追加
        ],
      ),
    );
  }
}

/// AppBar
class _SliverAppBar extends StatelessWidget {
  const _SliverAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      expandedHeight: 70,
      flexibleSpace: Container(
        padding: EdgeInsets.only(bottom: 10),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          // blurRadiusを削除してRaster負荷を軽減
          border: Border(bottom: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.12), width: 1.5)),
        ),
        child: RepaintBoundary(
          child: const Row(
            children: [
              SizedBox(width: 10),
              MyCustomText(text: 'Starbucks Card', fontSize: 28, useEnglishFont: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// 残高関連
class _CurrentMoneyBalance extends StatelessWidget {
  const _CurrentMoneyBalance();

  // 現在の日時を文字列として取得する関数
  String getCurrentDateTime() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            const MyCustomText(text: '￥384', fontSize: 24, fontWeight: FontWeight.w500),
            Column(
              crossAxisAlignment: .end,
              spacing: 1,
              children: [
                const MyCustomText(
                  text: '残高更新',
                  textColor: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                MyCustomText(text: getCurrentDateTime(), textColor: Colors.grey, fontSize: 15),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// デジタルカード
class _PayCard extends StatelessWidget {
  const _PayCard();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () {
            // 支払い画面へ遷移
          },
          child: SizedBox(
            height: 200,
            width: MediaQuery.sizeOf(context).width,
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: VectorGraphic(
                  loader: const AssetBytesLoader(payCardSvgPath),
                  fit: BoxFit.cover,
                  width: MediaQuery.sizeOf(context).width,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// その他のカード
class _OtherCardTitle extends StatelessWidget {
  const _OtherCardTitle();

  @override
  Widget build(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
      sliver: SliverToBoxAdapter(
        child: MyCustomText(
          text: 'その他のカード',
          textColor: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
