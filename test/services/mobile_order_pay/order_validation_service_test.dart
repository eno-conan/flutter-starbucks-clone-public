import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:testingapp/core/models/order_validation_result.dart';
import 'package:testingapp/data/repository/store.dart';
import 'package:testingapp/services/mobile_order_pay/order_validation_service.dart';
import 'package:testingapp/shared/helpers/time_of_day_extension.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

void main() {
  group('OrderValidationService', () {
    setUpAll(() {
      // any<TimeOfDay>() を使用するためのフォールバック値を登録
      registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
    });

    late MockStoreRepository storeRepository;
    late OrderValidationService service;

    setUp(() {
      storeRepository = MockStoreRepository();
      service = OrderValidationService(storeRepository);
    });

    group('validateStoreStatus', () {
      const storeNumber = '12345';

      test('閉店15分前より前の場合はValidationSuccessを返すこと', () async {
        // Arrange
        const closingTime = TimeOfDay(hour: 21, minute: 0);
        when(
          () => storeRepository.getStoreClosingTime(storeNumber),
        ).thenAnswer((_) async => closingTime);
        when(() => storeRepository.isWithin15MinutesBeforeClosing(closingTime)).thenReturn(false);

        // Act
        final result = await service.validateStoreStatus(storeNumber);

        // Assert
        expect(result, isA<ValidationSuccess>());
      });

      test('閉店15分前以降の場合はStoreClosingSoonを返すこと', () async {
        // Arrange
        const closingTime = TimeOfDay(hour: 21, minute: 30);
        when(
          () => storeRepository.getStoreClosingTime(storeNumber),
        ).thenAnswer((_) async => closingTime);
        when(() => storeRepository.isWithin15MinutesBeforeClosing(closingTime)).thenReturn(true);

        // Act
        final result = await service.validateStoreStatus(storeNumber);

        // Assert
        expect(result, isA<StoreClosingSoon>());
        expect((result as StoreClosingSoon).closingTime, closingTime.toHHmm());
      });

      test('店舗情報が取得できない場合はValidationError(storeNotFound)を返すこと', () async {
        // Arrange
        when(
          () => storeRepository.getStoreClosingTime(storeNumber),
        ).thenAnswer((_) async => null);

        // Act
        final result = await service.validateStoreStatus(storeNumber);

        // Assert
        expect(result, isA<ValidationError>());
        expect((result as ValidationError).errorType, ValidationErrorType.storeNotFound);
        // 閉店時刻が取得できないため、営業中かどうかの判定は呼ばれない
        verifyNever(() => storeRepository.isWithin15MinutesBeforeClosing(any()));
      });

      test('リポジトリが例外をthrowした場合はValidationError(networkError)を返すこと', () async {
        // Arrange
        when(
          () => storeRepository.getStoreClosingTime(storeNumber),
        ).thenThrow(Exception('network error'));

        // Act
        final result = await service.validateStoreStatus(storeNumber);

        // Assert
        expect(result, isA<ValidationError>());
        expect((result as ValidationError).errorType, ValidationErrorType.networkError);
      });
    });
  });
}
