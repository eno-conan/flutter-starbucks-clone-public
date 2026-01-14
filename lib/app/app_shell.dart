// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/bottom_navbar_icons.dart';
import '../core/services/navigation_performance_mixin.dart';
import '../provider/connectivity_check_provider.dart';
import '../provider/location_state_provider.dart';
import '../provider/stores_provider.dart';
import '../shared/widgets/dialogs/offline_dialog.dart';
import '../shared/widgets/texts/my_custom_text.dart';
import 'menu.dart';

// BottomNavigationBarを含むメインのScaffold
class ScaffoldWithCustomNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithCustomNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithCustomNavBar> createState() => _ScaffoldWithCustomNavBarState();
}

class _ScaffoldWithCustomNavBarState extends ConsumerState<ScaffoldWithCustomNavBar>
    with NavigationPerformanceMixin {
  Trace? _buildTrace;
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // UI描画のパフォーマンス測定を開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildTrace = FirebasePerformance.instance.newTrace('app_shell_build');
      _buildTrace?.start();
    });
  }

  @override
  void dispose() {
    _buildTrace?.stop();
    _selectedIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ValueNotifierを同期
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndexNotifier.value != widget.navigationShell.currentIndex) {
        _selectedIndexNotifier.value = widget.navigationShell.currentIndex;
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go(MenuPage.routeName);
        }
      },
      child: Scaffold(
        body: RepaintBoundary(child: widget.navigationShell),
        bottomNavigationBar: RepaintBoundary(
          child: ValueListenableBuilder<int>(
            valueListenable: _selectedIndexNotifier,
            builder: (context, selectedIndex, _) {
              return AnimatedBottomNavigationBar.builder(
                itemCount: BottomNavbarIcons.iconList.length,
                activeIndex: selectedIndex,
                scaleFactor: -0.9,
                gapLocation: GapLocation.none,
                onTap: _handleTabTap,
                tabBuilder: _buildNavigationTab,
              );
            },
          ),
        ),
      ),
    );
  }

  /// タブタップ時の処理（同期処理でUIブロックを回避）
  void _handleTabTap(int index) {
    // 即座にナビゲーションを実行（UIスレッドブロック回避）
    _selectedIndexNotifier.value = index;
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // 重い処理をバックグラウンドで実行
    _performBackgroundTasks(index);
  }

  /// バックグラウンドタスクの実行
  Future<void> _performBackgroundTasks(int index) async {
    // バックグラウンドで非同期実行
    unawaited(_startNavigationTrace(index));

    // ネットワークチェック
    if (index == 0 || index == 2) {
      _checkAndShowOfflineDialog();
    }

    // 位置情報と店舗情報の更新
    _refreshLocationAndStores();
  }

  /// 🔥 新しいパフォーマンス計測サービスを使用
  Future<void> _startNavigationTrace(int index) async {
    // NavigationPerformanceMixinのメソッドを使用
    measureTabNavigation(index);
  }

  /// 位置情報と店舗情報の更新
  void _refreshLocationAndStores() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).refreshLocation();
      ref.read(storeProvider.notifier).fetchStores();
    });
  }

  /// オフラインダイアログの表示チェック
  void _checkAndShowOfflineDialog() {
    final connectivity = ref.read(connectivityCheckProvider);

    connectivity.whenData((results) {
      if (results.first == ConnectivityResult.none) {
        showOfflineDialog(context);
      }
    });
  }

  /// ナビゲーションタブの構築
  Widget _buildNavigationTab(int index, bool isActive) {
    return RepaintBoundary(
      child: _BottomNavigationBarTabBuilder(
        icon: isActive
            ? BottomNavbarIcons.iconActiveList[index]
            : BottomNavbarIcons.iconList[index],
        label: BottomNavbarIcons.labelList[index],
        isActive: isActive,
      ),
    );
  }
}

class _BottomNavigationBarTabBuilder extends StatelessWidget {
  const _BottomNavigationBarTabBuilder({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green[500] : Colors.grey[500];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: .center,
      spacing: 2,
      children: [
        const SizedBox(height: 3),
        Icon(icon, size: 28, color: color),
        MyCustomText(text: label, fontWeight: FontWeight.w400, textColor: color),
      ],
    );
  }
}
