import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/my_colors.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

/// ログイン時の表示コンテンツ
class InboxTopPage extends StatelessWidget {
  const InboxTopPage({super.key});
  static String routeName = '/starbucks_inbox';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: const SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Column(
                children: [
                  Row(
                    children: [
                      MyCustomText(text: 'Inbox', fontSize: 28, fontWeight: FontWeight.bold),
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return SizedBox(
      height: size.height * 0.7,
      child: Column(
        children: [
          ColoredBox(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorWeight: 2.5,
              indicatorAnimation: TabIndicatorAnimation.linear,
              indicatorSize: TabBarIndicatorSize.tab, //これだ！（端っこまでIndicator表示）
              indicatorColor: Colors.green,
              padding: .all(0),
              tabAlignment: size.width > 600 ? TabAlignment.center : TabAlignment.start,
              tabs: const [
                Tab(
                  child: NotificationBadgeText(
                    text: "What's New",
                    badgeSize: 10.0, // バッジサイズを大きく
                    badgeColor: Color(0xFF00AA65),
                  ),
                ),
                Tab(
                  child: NotificationBadgeText(
                    text: 'Message',
                    badgeSize: 10.0,
                    badgeColor: Color(0xFF00AA65),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: const [
                Center(child: Text('タブ1のコンテンツ')),
                //履歴のコンテンツ
                ColoredBox(color: MyColors.backgroundGrey, child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationBadgeText extends StatelessWidget {
  const NotificationBadgeText({
    super.key,
    required this.text,
    this.showBadge = true,
    this.badgeSize = 8.0,
    this.badgeColor = Colors.green,
  });
  final String text;
  final bool showBadge;
  final double badgeSize;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // メインのテキスト
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.grey)),

        // 通知バッジ
        if (showBadge)
          Positioned(
            top: -5,
            right: -badgeSize / 2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}
