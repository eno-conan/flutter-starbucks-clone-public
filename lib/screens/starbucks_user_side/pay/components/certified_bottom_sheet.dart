import 'package:flutter/material.dart';

import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import 'loading_overlay.dart';

/// Certified bottom sheet for deposit confirmation
class CertifiedBottomSheet extends StatelessWidget {
  const CertifiedBottomSheet({
    super.key,
    required this.selectedCard,
    required this.selectedDepositAmount,
    required this.selectedPayWay,
    required this.successDialog,
  });

  final String selectedCard;
  final String selectedDepositAmount;
  final String selectedPayWay;
  final VoidCallback successDialog;

  /// Perform deposit process
  Future<void> _performDeposit(BuildContext context) async {
    try {
      // Show loading overlay
      LoadingOverlay.show(context);

      // Simulate async deposit process
      await Future<void>.delayed(const Duration(seconds: 2));

      // Show success dialog
      successDialog();

      // Close bottom sheet
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        // Error handling
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('入金処理中にエラーが発生しました: $e')));
      }
    } finally {
      if (context.mounted) {
        // Always hide loading overlay
        LoadingOverlay.hide(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: .start,
      children: [
        const _BottomSheetTitle(),
        const SizedBox(height: 15),
        _DepositDetailsSection(
          selectedCard: selectedCard,
          selectedDepositAmount: selectedDepositAmount,
          selectedPayWay: selectedPayWay,
        ),
        const SizedBox(height: 10),
        _DepositActionButtons(
          onCancel: () => Navigator.of(context).pop(),
          onDeposit: () => _performDeposit(context),
          selectedDepositAmount: selectedDepositAmount,
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

/// Bottom sheet title with close button
class _BottomSheetTitle extends StatelessWidget {
  const _BottomSheetTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: MyColors.headerLeadingIcon),
        ),
        const SizedBox(width: 25),
        const MyCustomText(text: '入金', fontSize: 16, textColor: MyColors.greyText),
      ],
    );
  }
}

/// Deposit details section
class _DepositDetailsSection extends StatelessWidget {
  const _DepositDetailsSection({
    required this.selectedCard,
    required this.selectedDepositAmount,
    required this.selectedPayWay,
  });

  final String selectedCard;
  final String selectedDepositAmount;
  final String selectedPayWay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _DepositDetailRow(label: 'アカウント名', value: selectedCard),
          const SizedBox(height: 20),
          _DepositDetailRow(label: '入金額', value: selectedDepositAmount),
          const SizedBox(height: 20),
          _DepositDetailRow(label: '支払い方法', value: selectedPayWay),
        ],
      ),
    );
  }
}

/// Individual deposit detail row
class _DepositDetailRow extends StatelessWidget {
  const _DepositDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        MyCustomText(text: label, fontSize: 12, textColor: MyColors.greyText),
        MyCustomText(text: value),
      ],
    );
  }
}

/// Deposit action buttons
class _DepositActionButtons extends StatelessWidget {
  const _DepositActionButtons({
    required this.onCancel,
    required this.onDeposit,
    required this.selectedDepositAmount,
  });

  final VoidCallback onCancel;
  final VoidCallback onDeposit;
  final String selectedDepositAmount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .end,
      children: [
        _CancelButton(onPressed: onCancel),
        const SizedBox(width: 10),
        _DepositButton(onPressed: onDeposit, depositAmount: selectedDepositAmount),
      ],
    );
  }
}

/// Cancel button
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 1,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: const MyCustomText(text: 'キャンセル', textColor: Colors.black, fontSize: 18),
      ),
    );
  }
}

/// Deposit button
class _DepositButton extends StatelessWidget {
  const _DepositButton({required this.onPressed, required this.depositAmount});

  final VoidCallback onPressed;
  final String depositAmount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 1,
          backgroundColor: MyColors.greenButton,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: MyCustomText(text: '$depositAmount 入金', textColor: Colors.white, fontSize: 18),
      ),
    );
  }
}
