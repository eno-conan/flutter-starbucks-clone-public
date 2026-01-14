import 'package:flutter_riverpod/flutter_riverpod.dart';

// 選択されたタブを管理するNotifier
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  // タブを設定するメソッド
  void setTab(int index) {
    state = index;
  }
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(SelectedTabNotifier.new);
