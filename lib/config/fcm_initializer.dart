import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/services/logger_service.dart';

class FCMInitializer {
  // ローカル通知プラグインのインスタンス
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// フォアグラウンド通知を処理する初期化
  static void initialize() {
    // ローカル通知の初期化
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Android用の通知チャンネル設定
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // フォアグラウンドメッセージのリスナー
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LoggerService.info('Foreground message received: ${message.notification?.title}');

      // フォアグラウンドで通知を表示
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
              visibility: NotificationVisibility.public, // private:ロック画面で内容非表示
            ),
          ),
        );
      }
    });
  }
}
