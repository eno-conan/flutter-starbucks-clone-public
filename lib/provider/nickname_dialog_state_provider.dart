import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ニックネームダイアログの状態を管理するクラス
class NicknameDialogState {
  const NicknameDialogState({this.hasShownInitDialog = false, this.dontShowAgain = false});

  final bool hasShownInitDialog;
  final bool dontShowAgain;

  NicknameDialogState copyWith({bool? hasShownInitDialog, bool? dontShowAgain}) {
    return NicknameDialogState(
      hasShownInitDialog: hasShownInitDialog ?? this.hasShownInitDialog,
      dontShowAgain: dontShowAgain ?? this.dontShowAgain,
    );
  }
}

/// ニックネームダイアログの状態を管理するNotifier
class NicknameDialogNotifier extends Notifier<NicknameDialogState> {
  @override
  NicknameDialogState build() {
    return const NicknameDialogState();
  }

  /// 初回ダイアログを表示したことをマーク
  void markInitDialogShown() {
    state = state.copyWith(hasShownInitDialog: true);
  }

  /// 「次回から表示しない」フラグを設定
  void setDontShowAgain(bool value) {
    state = state.copyWith(dontShowAgain: value);
  }

  /// 状態をリセット（新しいセッションの開始時など）
  void reset() {
    state = const NicknameDialogState();
  }
}

final nicknameDialogProvider = NotifierProvider<NicknameDialogNotifier, NicknameDialogState>(
  NicknameDialogNotifier.new,
);
