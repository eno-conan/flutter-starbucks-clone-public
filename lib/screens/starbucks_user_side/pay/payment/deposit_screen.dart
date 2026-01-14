import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../../constants/my_colors.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../provider/auth_state_provider.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

/// 実際に支払を行う画面(QR)
class PayPayment extends ConsumerStatefulWidget {
  const PayPayment({super.key});
  static String routeName = '/pay_payment_page';

  @override
  ConsumerState<PayPayment> createState() => _PayPaymentState();
}

class _PayPaymentState extends ConsumerState<PayPayment> {
  double _originalBrightness = 0.0;
  final double _targetBrightness = 0.9; // 最大明るさ
  final _noScreenshot = NoScreenshot.instance;
  ScreenshotSnapshot _latestValue = ScreenshotSnapshot(
    isScreenshotProtectionOn: false,
    wasScreenshotTaken: false,
    screenshotPath: '',
  );
  late String _currentTime; // 現在時刻を保持
  StreamSubscription<ScreenshotSnapshot>? _screenshotSubscription; // 追加
  String? _qrData; // QRデータを保持する変数を追加

  @override
  void initState() {
    super.initState();
    _setCurrentTime(); // 現在時刻を設定
    _setBrightness();
    _enableScreenshotProtection();
    // StreamSubscriptionを保存
    _screenshotSubscription = _noScreenshot.screenshotStream.listen((value) {
      // mountedチェックを追加
      if (!mounted) {
        return;
      }

      setState(() {
        _latestValue = value;
      });
      // スクリーンショットが撮られたことを検知した場合の処理
      if (value.wasScreenshotTaken) {
        _showScreenshotWarning();
      }
    });
  }

  @override
  void dispose() {
    _screenshotSubscription?.cancel(); // リスナーをキャンセル
    _restoreBrightness();
    _disableScreenshotProtection();
    super.dispose();
  }

  // 現在時刻を取得して設定
  void _setCurrentTime() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy/M/d H:mm');
    _currentTime = formatter.format(now);
  }

  // スクリーンショット防止を有効化
  Future<void> _enableScreenshotProtection() async {
    try {
      await _noScreenshot.screenshotOff();
    } catch (e) {
      LoggerService.warn('Failed to enable screenshot protection: $e');
    }
  }

  // スクリーンショット防止を無効化
  Future<void> _disableScreenshotProtection() async {
    try {
      await _noScreenshot.screenshotOn();
    } catch (e) {
      LoggerService.warn('Failed to disable screenshot protection: $e');
    }
  }

  // スクリーンショットが撮られた際の警告表示
  void _showScreenshotWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('セキュリティのため、この画面ではスクリーンショットを撮ることはできません。'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 画面の明るさを変更する
  Future<void> _setBrightness() async {
    try {
      // 現在の明るさを保存
      _originalBrightness = await ScreenBrightness().current;
      // 明るさを最大に設定
      await ScreenBrightness().setScreenBrightness(_targetBrightness);
    } catch (e) {
      LoggerService.warn('Failed to set brightness: $e');
    }
  }

  // 画面の明るさを元に戻す
  Future<void> _restoreBrightness() async {
    try {
      await ScreenBrightness().setScreenBrightness(_originalBrightness);
    } catch (e) {
      LoggerService.warn('Failed to restore brightness: $e');
    }
  }

  // ダイアログ表示メソッドを追加
  void _showQRCodeDialog() {
    if (_qrData == null) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('コード番号'),
          content: SelectableText(
            _qrData!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0, //背景色が灰色になるのを防ぐ
        automaticallyImplyLeading: false,
        backgroundColor: MyColors.backgroundGold,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: Colors.white,
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          const _Header(
            text: '支払い',
            textColor: Colors.white,
            backgroundColor: MyColors.backgroundGold,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                SizedBox(
                  width: 300,
                  height: 100,
                  child: ColoredBox(
                    color: Colors.black12,
                    child: const Center(child: MyCustomText(text: 'カードの表示', fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      spacing: 12,
                      children: [
                        const MyCustomText(
                          text: 'Starbucks Card',
                          textColor: MyColors.greyText,
                          fontSize: 14,
                          useEnglishFont: true,
                        ),
                        const MyCustomText(text: 'プルダウン', fontSize: 18),
                        MyCustomText(
                          text: '$_currentTime 時点',
                          fontSize: 16,
                          textColor: MyColors.greyText,
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MyColors.greenButton,
                            side: BorderSide(color: MyColors.greenButton, width: 0.8),
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            minimumSize: Size(0, 28),
                            splashFactory: InkSplash.splashFactory,
                          ),
                          child: const MyCustomText(text: '入金', textColor: MyColors.greenButton),
                        ),
                      ],
                    ),
                    Column(
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: 144,
                          height: 144,
                          child: QRCodeWidget(
                            onQRDataGenerated: (data) {
                              _qrData = data;
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: _showQRCodeDialog,
                          child: const MyCustomText(
                            text: 'コード番号を表示',
                            textColor: MyColors.greenText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // スクリーンショット保護状態の表示(デバッグ用、本番では削除可能)
                if (_latestValue.isScreenshotProtectionOn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text('スクリーンショット保護有効', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ヘッダーコンポーネント
class _Header extends StatelessWidget {
  const _Header({required this.text, required this.textColor, required this.backgroundColor});
  final String text;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: double.infinity,
        color: backgroundColor,
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: MyCustomText(
          text: text,
          fontSize: 28,
          textColor: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// QRコードWidgetを生成
class QRCodeWidget extends ConsumerWidget {
  const QRCodeWidget({super.key, this.onQRDataGenerated});

  final void Function(String)? onQRDataGenerated;

  // QRコードに表示する文字列を生成
  String _generateQRData(String userId) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd-HHmmss');
    final timestamp = formatter.format(now);
    return '${userId}_$timestamp';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const SizedBox(
        width: 100,
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
        ),
      ),
      error: (error, _) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Icon(Icons.error, color: Colors.red)),
      ),
      data: (user) {
        if (user == null) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: MyCustomText(text: 'ログインが\n必要です', fontSize: 12)),
          );
        }

        final qrData = _generateQRData(user.id);

        // QRデータが生成されたことを通知
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onQRDataGenerated?.call(qrData);
        });

        return QrImageView(
          data: qrData,
          size: 100.0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          errorStateBuilder: (context, err) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.error, color: Colors.red)),
            );
          },
        );
      },
    );
  }
}
