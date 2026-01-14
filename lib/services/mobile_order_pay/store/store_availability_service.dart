import '../../../core/services/logger_service.dart';
import '../../../data/repository/store.dart';

/// 店舗の営業状況をチェックするサービス
class StoreAvailabilityService {
  StoreAvailabilityService(this._storeRepository);

  final StoreRepository _storeRepository;

  /// 店舗が注文可能かどうかをチェック
  ///
  /// 閉店時間の15分前から開店時間まで注文不可
  ///
  /// パラメータ:
  /// - [storeNumber]: 店舗番号
  ///
  /// 戻り値:
  /// - true: 注文可能
  /// - false: 注文不可（閉店時間15分前以降）
  Future<bool> isStoreAvailable(String storeNumber) async {
    try {
      LoggerService.info('店舗営業状況チェック開始: storeNumber=$storeNumber');

      final closingTime = await _storeRepository.getStoreClosingTime(storeNumber);

      if (closingTime == null) {
        LoggerService.warn('店舗の閉店時刻取得に失敗: storeNumber=$storeNumber');
        // 閉店時刻が取得できない場合は安全のため注文不可とする
        return false;
      }

      final isWithin15Minutes = _storeRepository.isWithin15MinutesBeforeClosing(closingTime);

      if (isWithin15Minutes) {
        LoggerService.info('店舗は注文受付停止中: storeNumber=$storeNumber');
        return false;
      }

      LoggerService.info('店舗は注文受付中: storeNumber=$storeNumber');
      return true;
    } catch (e) {
      LoggerService.warn('店舗営業状況チェックエラー: storeNumber=$storeNumber', e);
      // エラーが発生した場合は安全のため注文不可とする
      return false;
    }
  }

  /// 複数店舗の営業状況を一括チェック
  ///
  /// パフォーマンスを向上させるため、並列処理で実行
  ///
  /// パラメータ:
  /// - [storeNumbers]: 店舗番号のリスト
  ///
  /// 戻り値:
  /// - 店舗番号をキーとした営業状況のマップ
  Future<Map<String, bool>> checkMultipleStores(List<String> storeNumbers) async {
    try {
      LoggerService.info('複数店舗営業状況チェック開始: ${storeNumbers.length}件');

      final futures = storeNumbers.map((storeNumber) async {
        final isAvailable = await isStoreAvailable(storeNumber);
        return MapEntry(storeNumber, isAvailable);
      }).toList();

      final results = await Future.wait(futures);
      final resultMap = <String, bool>{};

      for (final entry in results) {
        resultMap[entry.key] = entry.value;
      }

      LoggerService.info('複数店舗営業状況チェック完了');
      return resultMap;
    } catch (e) {
      LoggerService.warn('複数店舗営業状況チェックエラー', e);

      // エラーが発生した場合は全店舗を注文不可とする
      final resultMap = <String, bool>{};
      for (final storeNumber in storeNumbers) {
        resultMap[storeNumber] = false;
      }
      return resultMap;
    }
  }
}
