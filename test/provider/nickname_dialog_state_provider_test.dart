import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/provider/nickname_dialog_state_provider.dart';

void main() {
  group('NicknameDialogNotifier', () {
    test('初期値はhasShownInitDialog・dontShowAgainともにfalseであること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final result = container.read(nicknameDialogProvider);

      // Assert
      expect(result.hasShownInitDialog, isFalse);
      expect(result.dontShowAgain, isFalse);
    });

    test('markInitDialogShownでhasShownInitDialogのみtrueになること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(nicknameDialogProvider.notifier).markInitDialogShown();

      // Assert
      final result = container.read(nicknameDialogProvider);
      expect(result.hasShownInitDialog, isTrue);
      expect(result.dontShowAgain, isFalse);
    });

    test('setDontShowAgainでdontShowAgainが更新されること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(nicknameDialogProvider.notifier).setDontShowAgain(true);

      // Assert
      expect(container.read(nicknameDialogProvider).dontShowAgain, isTrue);
    });

    test('resetで状態が初期値に戻ること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(nicknameDialogProvider.notifier).markInitDialogShown();
      container.read(nicknameDialogProvider.notifier).setDontShowAgain(true);

      // Act
      container.read(nicknameDialogProvider.notifier).reset();

      // Assert
      final result = container.read(nicknameDialogProvider);
      expect(result.hasShownInitDialog, isFalse);
      expect(result.dontShowAgain, isFalse);
    });
  });

  group('NicknameDialogState.copyWith', () {
    test('引数を指定しない場合は同じ値のインスタンスを返すこと', () {
      // Arrange
      const original = NicknameDialogState(hasShownInitDialog: true, dontShowAgain: true);

      // Act
      final result = original.copyWith();

      // Assert
      expect(result.hasShownInitDialog, original.hasShownInitDialog);
      expect(result.dontShowAgain, original.dontShowAgain);
    });

    test('指定したフィールドのみが更新されること', () {
      // Arrange
      const original = NicknameDialogState();

      // Act
      final result = original.copyWith(dontShowAgain: true);

      // Assert
      expect(result.hasShownInitDialog, isFalse);
      expect(result.dontShowAgain, isTrue);
    });
  });
}
