import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/my_colors.dart';
import '../../../constants/supabase_tables.dart';
import '../../../core/models/user_nickname.dart';
import '../texts/my_custom_text.dart';

///ニックネームに関するダイアログ表示
void showNickNameModal(BuildContext context, {VoidCallback? onNicknameUpdated}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return _NickNameDialog(onNicknameUpdated: onNicknameUpdated);
    },
  );
}

class _NickNameDialog extends StatefulWidget {
  const _NickNameDialog({this.onNicknameUpdated});

  final VoidCallback? onNicknameUpdated;

  @override
  State<_NickNameDialog> createState() => _NickNameDialogState();
}

class _NickNameDialogState extends State<_NickNameDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ニックネームのバリデーション
  bool _validateNickname(String nickname) {
    if (nickname.isEmpty) {
      setState(() {
        _errorMessage = 'ニックネームを入力してください';
      });
      return false;
    }

    // カタカナ、英数字のみ許可（濁点含む）
    final validPattern = RegExp(r'^[ァ-ヶーa-zA-Z0-9]+$');
    if (!validPattern.hasMatch(nickname)) {
      setState(() {
        _errorMessage = 'カタカナ、英数字のみ使用できます';
      });
      return false;
    }

    // 最大10文字チェック
    if (nickname.length > 10) {
      setState(() {
        _errorMessage = '最大10文字までです';
      });
      return false;
    }

    setState(() {
      _errorMessage = '';
    });
    return true;
  }

  // ニックネームを登録
  Future<void> _saveNickname() async {
    final nickname = _controller.text.trim();

    if (!_validateNickname(nickname)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final userNickname = UserNickname(userId: userId, nickName: nickname);
      await _supabase.from(Tables.userNickname).upsert(userNickname.toJson()).select().single();
      if (mounted) {
        Navigator.of(context).pop(); // ダイアログを閉じる
        // ニックネーム更新完了を通知
        widget.onNicknameUpdated?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ニックネームの登録に失敗しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// デバウンス処理（setStateの頻度を100msに制限）
  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const MyCustomText(text: 'ニックネーム登録', fontSize: 20, fontWeight: FontWeight.bold),
              const SizedBox(height: 40),
              const MyCustomText(text: 'ニックネームはラベルに印刷され、受取時に利用するよ～', fontSize: 12, softwrap: true),
              const SizedBox(height: 32),
              const MyCustomText(text: 'ニックネームを入力してね', fontSize: 14, fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              // テキストフィールド
              RepaintBoundary(
                child: TextField(
                  controller: _controller,
                  maxLength: 10,
                  onChanged: _onTextChanged,
                  cursorColor: MyColors.greenButton,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _controller.text.isEmpty ? Colors.grey[300]! : MyColors.greenButton,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: MyColors.greenButton, width: 2.0),
                    ),
                    errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Column(
                crossAxisAlignment: .start,
                spacing: 3,
                children: [
                  MyCustomText(
                    text: '※カタカナ、英数字をご利用いただけます',
                    fontSize: 11,
                    textColor: MyColors.greyText,
                    softwrap: true,
                  ),
                  MyCustomText(
                    text: '最大10文字まで登録いただけます(濁点は1文字としてカウント)',
                    fontSize: 11,
                    textColor: MyColors.greyText,
                    softwrap: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                spacing: 10,
                mainAxisAlignment: .end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MyColors.greenButton,
                      side: const BorderSide(color: MyColors.greenButton),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      minimumSize: const Size(0, 35),
                    ),
                    child: const MyCustomText(
                      text: 'キャンセル',
                      textColor: MyColors.greenText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton(
                    onPressed: _isLoading || _controller.text.trim().isEmpty ? null : _saveNickname,
                    style: FilledButton.styleFrom(
                      backgroundColor: _controller.text.trim().isEmpty
                          ? MyColors.greyButton
                          : MyColors.greenButton,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      minimumSize: const Size(0, 35),
                    ),
                    child: const MyCustomText(
                      text: 'OK',
                      textColor: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
