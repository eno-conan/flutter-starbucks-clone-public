import 'package:url_launcher/url_launcher.dart';

///URLを開く関数
Future<void> launchURL(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw Exception('Could not launch $url');
  }
}
