// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/menu.dart';
import 'widgets/realtime_widget.dart' as widgets;

// BottomNavigationBarを含むメインのScaffold
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // アプリのHome画面に戻る
        context.go(MenuPage.routeName);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '検索'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
          ],
          currentIndex: navigationShell.currentIndex,
          onTap: (int index) => _onTap(context, index),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }
}

// タブ1の内容
// タブ1, 2の内容
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: const widgets.RealtimeWidget(),
    );
  }
}

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('検索')),
      body: Center(child: Text('検索タブの内容', style: TextStyle(fontSize: 18))),
    );
  }
}

// プロフィールタブのTabBarViewコンテナ
class ProfileTabContainer extends StatefulWidget {
  const ProfileTabContainer({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  State<ProfileTabContainer> createState() => _ProfileTabContainerState();
}

class _ProfileTabContainerState extends State<ProfileTabContainer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 認証状態を疑似的に表現する変数
  // 0: 未認証（SimpleWidgetを表示）
  // 1: 認証済み（TabBarViewを表示）
  int _authState = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 認証状態を切り替えるメソッド
  void _toggleAuthState() {
    setState(() {
      _authState = _authState == 0 ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール'),
        automaticallyImplyLeading: false,
        actions: [
          // 認証状態切り替えボタン（テスト用）
          IconButton(
            icon: Icon(_authState == 0 ? Icons.login : Icons.logout),
            onPressed: _toggleAuthState,
            tooltip: _authState == 0 ? 'ログイン' : 'ログアウト',
          ),
        ],
        bottom: _authState == 1
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'フロー1 (A→B→C)'),
                  Tab(text: 'フロー2 (D→E→F→G→H)'),
                ],
              )
            : null,
      ),
      body: _authState == 0
          ? const SimpleWidget() // 未認証時は単一のWidget表示
          : TabBarView(
              // 認証済み時はTabBarView表示
              controller: _tabController,
              children: const [
                // タブ1: A→B→Cフロー
                WidgetA(),
                // タブ2: D→E→F→G→Hフロー
                WidgetD(),
              ],
            ),
    );
  }
}

// 未認証時に表示する単一のWidget
class SimpleWidget extends StatelessWidget {
  const SimpleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const .all(20.0),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(Icons.account_circle, size: 120, color: Colors.grey[400]),
            SizedBox(height: 30),
            Text(
              'プロフィールを表示するには\nログインが必要です',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // 実際のアプリではログイン画面に遷移
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('右上のログインボタンでテスト用のログイン切り替えができます'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.login),
              label: Text('ログイン'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === タブ1のWidget群 (Realtime機能) ===

class WidgetA extends StatelessWidget {
  const WidgetA({super.key});

  @override
  Widget build(BuildContext context) {
    return const widgets.RealtimeWidget();
  }
}

class WidgetB extends StatefulWidget {
  const WidgetB({super.key});

  @override
  _WidgetBState createState() => _WidgetBState();
}

class _WidgetBState extends State<WidgetB> {
  String _dataFromB = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future<void>.delayed(Duration(seconds: 1));
    setState(() {
      _dataFromB = 'タブ1データ: ${DateTime.now().millisecondsSinceEpoch}';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget B'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile?tab=0'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text('Widget B', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Container(
                padding: .all(16),
                margin: .all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_dataFromB),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => context.go(
                      '/profile/tab1/widget-b/widget-c?data=${Uri.encodeComponent(_dataFromB)}&tab=0',
                    ),
              child: Text('Widget Cに遷移'),
            ),
          ],
        ),
      ),
    );
  }
}

class WidgetC extends StatelessWidget {
  const WidgetC({super.key, required this.dataFromB});
  final String dataFromB;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget C'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile/tab1/widget-b?tab=0'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text('Widget C', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              padding: .all(16),
              margin: .all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text('受け取ったデータ: $dataFromB'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/profile?tab=0'),
              child: Text('Widget Aに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}

// === タブ2のWidget群 (D→E→F→G→H) ===

class WidgetD extends StatelessWidget {
  const WidgetD({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .all(20),
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Text('Widget D', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Text('タブ2のスタート画面'),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.go('/profile/tab2/widget-e?tab=1'),
            child: Text('Widget Eに遷移'),
          ),
        ],
      ),
    );
  }
}

class WidgetE extends StatelessWidget {
  const WidgetE({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget E'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile?tab=1'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text('Widget E', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/profile/tab2/widget-e/widget-f?tab=1'),
              child: Text('Widget Fに遷移'),
            ),
          ],
        ),
      ),
    );
  }
}

class WidgetF extends StatelessWidget {
  const WidgetF({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget F'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile/tab2/widget-e?tab=1'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text('Widget F', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: .spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/profile/tab2/widget-e/widget-g?tab=1'),
                  child: Text('Widget Gに遷移'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/profile?tab=1'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Widget Dに戻る'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WidgetG extends StatefulWidget {
  const WidgetG({super.key});

  @override
  _WidgetGState createState() => _WidgetGState();
}

class _WidgetGState extends State<WidgetG> {
  String _dataFromG = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future<void>.delayed(Duration(seconds: 1));
    setState(() {
      _dataFromG = 'タブ2データ: ${DateTime.now().millisecondsSinceEpoch}';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget G'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile/tab2/widget-e/widget-f?tab=1'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text('Widget G', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Container(
                padding: .all(16),
                margin: .all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_dataFromG),
              ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: .spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(
                          '/profile/tab2/widget-e/widget-g/widget-h?data=${Uri.encodeComponent(_dataFromG)}&tab=1',
                        ),
                  child: Text('Widget Hに遷移'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/profile?tab=1'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Widget Dに戻る'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WidgetH extends StatelessWidget {
  const WidgetH({super.key, required this.dataFromG});
  final String dataFromG;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget H'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile/tab2/widget-e/widget-g?tab=1'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text('Widget H', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              padding: .all(16),
              margin: .all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text('Gから受け取ったデータ: $dataFromG'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/profile/tab2/widget-e/widget-g?tab=1'),
              child: Text('Widget Gに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
