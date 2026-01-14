class UserMailSettings {
  UserMailSettings({
    required this.userId,
    required this.isSendRelatedRewards,
    required this.isSendAdvanceProductAnnounce,
    required this.isHtmlMail,
  });

  final String userId;
  final bool isSendRelatedRewards;
  final bool isSendAdvanceProductAnnounce;
  final bool isHtmlMail;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'is_send_related_rewards': isSendRelatedRewards ? 1 : 0,
      'is_send_advance_product_announce': isSendAdvanceProductAnnounce ? 1 : 0,
      'is_html_mail': isHtmlMail ? 1 : 0,
    };
    return data;
  }
}
