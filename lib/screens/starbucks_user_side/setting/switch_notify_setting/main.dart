import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../constants/my_colors.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../data/repository/user_fcm_tokens.dart';
import '../../../../shared/widgets/headers/fixed_header.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

///通知設定画面
class SwitchNotifySetting extends StatelessWidget {
  const SwitchNotifySetting({super.key});
  static String routeName = 'setting_page_switch_notify_setting';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        context.pop();
      },
      child: FixedHeaderCommonComponent(
        isLeadingIcon: true,
        onIconPressed: () {
          context.pop(context);
        },
        headerText: '通知設定',
        body: _Content(),
        isFab: false,
      ),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  // 通知の状態を管理するための変数
  bool _isNotificationEnabled = false;
  // リポジトリのインスタンス
  late final UserFcmTokenRepository _repository;
  // ユーザーID（認証情報から取得する）
  late final String _userId;
  // データのロード状態
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // データの初期化処理
  Future<void> _initializeData() async {
    // Supabaseのインスタンスとユーザー情報の取得
    final SupabaseClient supabase = Supabase.instance.client;
    _repository = UserFcmTokenRepository(supabase);
    _userId = supabase.auth.currentUser?.id ?? '';

    if (_userId.isNotEmpty) {
      try {
        // ユーザーの通知設定を取得
        final userFcmToken = await _repository.getNotificationStatus(_userId);
        setState(() {
          // isNotifyが1ならtrue、それ以外ならfalse
          _isNotificationEnabled = userFcmToken.isNotify == 1;
          _isLoading = false;
        });
      } catch (e) {
        LoggerService.warn('通知設定の取得に失敗しました: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 通知設定の切り替え処理
  void _toggleNotification(bool value) {
    setState(() {
      _isNotificationEnabled = value;
    });
  }

  @override
  void dispose() {
    // ウィジェットが破棄される際にデータベースを更新
    _updateNotificationSetting();
    super.dispose();
  }

  // データベースの通知設定を更新
  Future<void> _updateNotificationSetting() async {
    if (_userId.isNotEmpty) {
      try {
        // true -> 1, false -> 0に変換
        final status = _isNotificationEnabled ? 1 : 0;
        await _repository.updateNotificationStatus(_userId, status);
      } catch (e) {
        LoggerService.warn('通知設定の更新に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ロード中の表示
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: MyCustomText(
            text: '通知設定',
            fontSize: 14,
            textColor: MyColors.greyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(color: MyColors.horizontalDivider, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              const MyCustomText(text: '通知する', fontSize: 16, fontWeight: FontWeight.bold),
              const Spacer(),
              Transform.scale(
                scale: 1.0,
                child: CupertinoSwitch(
                  value: _isNotificationEnabled,
                  onChanged: _toggleNotification,
                  activeColor: MyColors.greenButton,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
