import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../e_ticket_available_tab_no_available_message.dart';
import '../e_ticket_used_tab_tickets.dart';
import 'tab_available_tickets.dart';

/// eチケットログイン時のコンテンツ
class ETicketLoginedContents extends StatelessWidget {
  const ETicketLoginedContents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
                      MyCustomText(text: 'eTicket', fontSize: 20, fontWeight: FontWeight.bold),
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

class _TabControllerWidgetState extends State<_TabControllerWidget> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      animationDuration: const Duration(milliseconds: 150),
    );

    // タブ切り替え時のリスナーを最適化
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // アニメーション完了後のみ処理（頻繁な再構築を防ぐ）
    if (!_tabController.indexIsChanging && mounted) {
      // 必要に応じて処理を追加
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          ColoredBox(
            color: Colors.white,
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
                  child: Tab(text: '利用可能'),
                ),
                SizedBox(
                  // width: 50, // タブの幅を固定
                  child: Tab(text: '利用開始日前'),
                ),
                SizedBox(
                  // width: 50, // タブの幅を固定
                  child: Tab(text: '利用済み'),
                ),
              ],
            ),
          ),
          Flexible(
            child: RepaintBoundary(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // スクロール無効化でパフォーマンス向上
                children: const [
                  // 利用可能
                  RepaintBoundary(
                    child: SizedBox(width: double.infinity, child: ETicketTabAvailableTickets()),
                  ),
                  //利用開始日前
                  RepaintBoundary(
                    child: SizedBox(width: double.infinity, child: BeforeUsableTicketsTab()),
                  ),
                  // 利用済み
                  RepaintBoundary(
                    child: SizedBox(width: double.infinity, child: UsedETicketsTab()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BeforeUsableTicketsTab extends StatelessWidget {
  const BeforeUsableTicketsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: const <Widget>[
        // MessageSection(),
        // ここに画像
        SliverToBoxAdapter(
          child: NoAvaiableETicketMessage(
            widgetKey: 'eticket-beforeusable-tab-no-available-message',
            subMessage: '利用開始日前のチケットはありません。',
          ),
        ),
      ],
    );
  }
}
