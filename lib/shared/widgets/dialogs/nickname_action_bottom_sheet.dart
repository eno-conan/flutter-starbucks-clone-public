import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/my_colors.dart';
import '../../../constants/supabase_tables.dart';
import '../texts/my_custom_text.dart';
import 'nickname_dialog.dart';

/// ニックネーム操作選択BottomSheetを表示
void showNicknameActionSheet(BuildContext context, {VoidCallback? onNicknameUpdated}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return _NicknameActionSheet(onNicknameUpdated: onNicknameUpdated);
    },
  );
}

class _NicknameActionSheet extends StatefulWidget {
  const _NicknameActionSheet({this.onNicknameUpdated});

  final VoidCallback? onNicknameUpdated;

  @override
  State<_NicknameActionSheet> createState() => _NicknameActionSheetState();
}

class _NicknameActionSheetState extends State<_NicknameActionSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // ニックネームを削除
  Future<void> _deleteNickname() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // user_nicknameテーブルから該当ユーザーのニックネームを削除
      await _supabase.from(Tables.userNickname).delete().eq('user_id', userId);

      if (mounted) {
        Navigator.of(context).pop(); // BottomSheetを閉じる
        // ニックネーム削除完了を通知
        widget.onNicknameUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ニックネームの削除に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ハンドルバーと×ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // ×ボタン（右上）
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // タイトル
          const Center(
            child: MyCustomText(text: 'ニックネームの設定', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          // 変更ボタン
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop(); // BottomSheetを閉じる
                      showNickNameModal(context, onNicknameUpdated: widget.onNicknameUpdated);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.greenButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const MyCustomText(
                text: '変更する',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 使用しないボタン
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _deleteNickname,
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.greenButton,
                side: const BorderSide(color: MyColors.greenButton),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(MyColors.greenButton),
                      ),
                    )
                  : const MyCustomText(
                      text: '使用しない',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: MyColors.greenText,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
