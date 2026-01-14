/// eチケットのデータモデル
///
/// Supabase RPC関数から返される利用可能チケットと利用済みチケットのモデル

/// 利用可能なeチケット
///
/// 未使用で有効期限内のチケット情報を保持します。
/// RPC関数 `get_user_available_tickets` から取得されます。
class AvailableTicket {
  const AvailableTicket({
    required this.userTicketId,
    required this.userId,
    required this.ticketType,
    required this.expiredAt,
    required this.ticketName,
    this.imageUrl,
    this.discountType,
    this.discountValue,
  });

  /// ユーザーチケットID（user_ticketsテーブルのPK）
  final int userTicketId;

  /// ユーザーID（auth.usersテーブルへの参照）
  final String userId;

  /// チケットタイプ
  /// - 'STAR_REWARD': スターポイント交換チケット
  /// - 'PROMOTION': プロモーション割引チケット
  /// - 'SPECIAL_OFFER': 特別価格チケット
  final String ticketType;

  /// 有効期限
  final DateTime expiredAt;

  /// チケット名（表示用）
  final String ticketName;

  /// チケット画像URL（オプション）
  final String? imageUrl;

  /// 割引タイプ（PROMOTIONの場合のみ）
  /// 例: 'PERCENTAGE' (率引), 'FIXED_AMOUNT' (額引)
  final String? discountType;

  /// 割引値（PROMOTIONまたはSPECIAL_OFFERの場合）
  /// - PROMOTION: 割引率(%) または 割引額(円)
  /// - SPECIAL_OFFER: 特別価格(円)
  final num? discountValue;

  /// JSONからAvailableTicketを生成
  factory AvailableTicket.fromJson(Map<String, dynamic> json) {
    return AvailableTicket(
      userTicketId: json['user_ticket_id'] as int,
      userId: json['user_id'] as String,
      ticketType: json['ticket_type'] as String,
      expiredAt: DateTime.parse(json['expired_at'] as String),
      ticketName: json['ticket_name'] as String,
      imageUrl: json['image_url'] as String?,
      discountType: json['discount_type'] as String?,
      discountValue: json['discount_value'] as num?,
    );
  }

  /// AvailableTicketをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'user_ticket_id': userTicketId,
      'user_id': userId,
      'ticket_type': ticketType,
      'expired_at': expiredAt.toIso8601String(),
      'ticket_name': ticketName,
      if (imageUrl != null) 'image_url': imageUrl,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
    };
  }

  /// AvailableTicketのコピーを作成（一部のフィールドを上書き可能）
  AvailableTicket copyWith({
    int? userTicketId,
    String? userId,
    String? ticketType,
    DateTime? expiredAt,
    String? ticketName,
    String? imageUrl,
    String? discountType,
    num? discountValue,
  }) {
    return AvailableTicket(
      userTicketId: userTicketId ?? this.userTicketId,
      userId: userId ?? this.userId,
      ticketType: ticketType ?? this.ticketType,
      expiredAt: expiredAt ?? this.expiredAt,
      ticketName: ticketName ?? this.ticketName,
      imageUrl: imageUrl ?? this.imageUrl,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}

/// 利用済みeチケット
///
/// 使用済みで更新日が14日以内のチケット情報を保持します。
/// RPC関数 `get_user_used_tickets` から取得されます。
class UsedTicket {
  const UsedTicket({
    required this.userTicketId,
    required this.userId,
    required this.ticketType,
    required this.expiredAt,
    required this.usedAt,
    required this.ticketName,
    this.imageUrl,
    this.discountType,
    this.discountValue,
  });

  /// ユーザーチケットID（user_ticketsテーブルのPK）
  final int userTicketId;

  /// ユーザーID（auth.usersテーブルへの参照）
  final String userId;

  /// チケットタイプ
  /// - 'STAR_REWARD': スターポイント交換チケット
  /// - 'PROMOTION': プロモーション割引チケット
  /// - 'SPECIAL_OFFER': 特別価格チケット
  final String ticketType;

  /// 有効期限
  final DateTime expiredAt;

  /// 使用日時
  final DateTime usedAt;

  /// チケット名（表示用）
  final String ticketName;

  /// チケット画像URL（オプション）
  final String? imageUrl;

  /// 割引タイプ（PROMOTIONの場合のみ）
  /// 例: 'PERCENTAGE' (率引), 'FIXED_AMOUNT' (額引)
  final String? discountType;

  /// 割引値（PROMOTIONまたはSPECIAL_OFFERの場合）
  /// - PROMOTION: 割引率(%) または 割引額(円)
  /// - SPECIAL_OFFER: 特別価格(円)
  final num? discountValue;

  /// JSONからUsedTicketを生成
  factory UsedTicket.fromJson(Map<String, dynamic> json) {
    return UsedTicket(
      userTicketId: json['user_ticket_id'] as int,
      userId: json['user_id'] as String,
      ticketType: json['ticket_type'] as String,
      expiredAt: DateTime.parse(json['expired_at'] as String),
      usedAt: DateTime.parse(json['used_at'] as String),
      ticketName: json['ticket_name'] as String,
      imageUrl: json['image_url'] as String?,
      discountType: json['discount_type'] as String?,
      discountValue: json['discount_value'] as num?,
    );
  }

  /// UsedTicketをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'user_ticket_id': userTicketId,
      'user_id': userId,
      'ticket_type': ticketType,
      'expired_at': expiredAt.toIso8601String(),
      'used_at': usedAt.toIso8601String(),
      'ticket_name': ticketName,
      if (imageUrl != null) 'image_url': imageUrl,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
    };
  }

  /// UsedTicketのコピーを作成（一部のフィールドを上書き可能）
  UsedTicket copyWith({
    int? userTicketId,
    String? userId,
    String? ticketType,
    DateTime? expiredAt,
    DateTime? usedAt,
    String? ticketName,
    String? imageUrl,
    String? discountType,
    num? discountValue,
  }) {
    return UsedTicket(
      userTicketId: userTicketId ?? this.userTicketId,
      userId: userId ?? this.userId,
      ticketType: ticketType ?? this.ticketType,
      expiredAt: expiredAt ?? this.expiredAt,
      usedAt: usedAt ?? this.usedAt,
      ticketName: ticketName ?? this.ticketName,
      imageUrl: imageUrl ?? this.imageUrl,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}
