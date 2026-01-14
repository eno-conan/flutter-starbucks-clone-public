import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../../shared/widgets/texts/my_custom_text.dart';
import 'gift_starbucks_egift_tab_create_egift.dart';

//未ログイン時の表示
const String notLoginedCardSvgPath = 'assets/starbucks/svg/pay_not_logined.svg';

class GiftEgift extends StatelessWidget {
  const GiftEgift({super.key});
  static String routeName = 'starbucks_gift_egift_top';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.pop(context);
          },
        ),
      ),
      body: const SafeArea(
        child: Column(
          spacing: 5,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      MyCustomText(
                        text: 'Starbucks eGift',
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        useEnglishFont: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _TabControllerWidget(),
          ],
        ),
      ),
    );
  }
}

///タブ管理
class _TabControllerWidget extends StatefulWidget {
  const _TabControllerWidget();

  @override
  State<_TabControllerWidget> createState() => _TabControllerWidgetState();
}

class _TabControllerWidgetState extends State<_TabControllerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Material(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              customBorder: CircleBorder(),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorWeight: 3.0,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 3),
                indicatorAnimation: TabIndicatorAnimation.linear,
                indicatorSize: TabBarIndicatorSize.tab, //これだ！（端っこまでIndicator表示）
                indicatorColor: Colors.green,
                labelColor: Colors.black,
                unselectedLabelColor: Color(0xFF848484),
                tabAlignment: TabAlignment.start,
                tabs: const [
                  SizedBox(
                    // width: 50, // タブの幅を固定
                    child: Tab(text: 'eGiftを作る'),
                  ),
                  SizedBox(
                    // width: 50, // タブの幅を固定
                    child: Tab(text: '保存ギフト'),
                  ),
                  SizedBox(
                    // width: 50, // タブの幅を固定
                    child: Tab(text: '購入履歴'),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SizedBox(width: double.infinity, child: GiftEgiftTabCreateEgift()),
                //履歴のコンテンツ
                SizedBox(width: double.infinity, child: TabSavedEGift()),
                Center(child: Text('タブ3のコンテンツ')), //オーダーのコンテンツ
              ],
            ),
          ),
        ],
      ),
    );
  }
}

///保存ギフト
class TabSavedEGift extends StatelessWidget {
  const TabSavedEGift({super.key});

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
              MyCustomText(text: '保存されたギフトはありません', fontSize: 20),
              MyCustomText(
                text: 'Starbucks eGiftはメッセージカードにスターバックスのドリンクを添えて友達に贈ることのできるギフトサービスです',
                textColor: Color(0xFF8A8A8A),
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
