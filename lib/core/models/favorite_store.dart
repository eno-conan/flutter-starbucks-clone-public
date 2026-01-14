///モバイルオーダーお気に入り店舗のModel
class FavoriteStore {
  FavoriteStore({
    required this.id,
    required this.name,
    required this.address,
    required this.waitTime,
    required this.lastOrderTime,
    required this.distance,
    this.isFavorite = true,
  });
  final String id; // 店舗の一意識別子を追加
  final String name;
  final String address;
  final String waitTime;
  final String lastOrderTime;
  final String distance;
  final bool isFavorite;
}
