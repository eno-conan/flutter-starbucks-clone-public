import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testingapp/data/repository/star_acquisition_repository.dart';
import 'package:testingapp/services/mobile_order_pay/star_acquisition_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockStarAcquisitionRepository extends Mock implements StarAcquisitionRepository {}

void main() {
  group('StarAcquisitionService', () {
    late MockSupabaseClient supabaseClient;
    late MockGoTrueClient goTrueClient;
    late MockStarAcquisitionRepository repository;
    late StarAcquisitionService service;

    setUp(() {
      supabaseClient = MockSupabaseClient();
      goTrueClient = MockGoTrueClient();
      repository = MockStarAcquisitionRepository();
      service = StarAcquisitionService(supabaseClient, repository);

      when(() => supabaseClient.auth).thenReturn(goTrueClient);
    });

    group('insertStarAcquisition', () {
      test('未ログインの場合は例外をthrowすること', () async {
        // Arrange
        when(() => goTrueClient.currentUser).thenReturn(null);

        // Act & Assert
        await expectLater(
          () => service.insertStarAcquisition(orderId: 'order-1', category: 1, priceWithTax: 540),
          throwsA(isA<Exception>()),
        );
      });

      test('税込価格から60円あたり1ptで正しくスター数を計算しリポジトリに渡すこと', () async {
        // Arrange
        final user = MockUser();
        when(() => user.id).thenReturn('user-1');
        when(() => goTrueClient.currentUser).thenReturn(user);
        when(
          () => repository.insertStarAcquisition(
            userId: 'user-1',
            orderId: 'order-1',
            category: 1,
            acquiredPoints: 9.0,
          ),
        ).thenAnswer((_) async {});

        // Act
        await service.insertStarAcquisition(orderId: 'order-1', category: 1, priceWithTax: 540);

        // Assert
        verify(
          () => repository.insertStarAcquisition(
            userId: 'user-1',
            orderId: 'order-1',
            category: 1,
            acquiredPoints: 9.0,
          ),
        ).called(1);
      });

      test('割り切れない金額の場合は小数第3位以下を切り捨てること', () async {
        // Arrange
        final user = MockUser();
        when(() => user.id).thenReturn('user-1');
        when(() => goTrueClient.currentUser).thenReturn(user);
        when(
          () => repository.insertStarAcquisition(
            userId: any(named: 'userId'),
            orderId: any(named: 'orderId'),
            category: any(named: 'category'),
            acquiredPoints: any(named: 'acquiredPoints'),
          ),
        ).thenAnswer((_) async {});

        // Act
        // 100円 / 60円 * 100 = 166.66... → 切り捨てて166 → 1.66pt
        await service.insertStarAcquisition(orderId: 'order-2', category: 2, priceWithTax: 100);

        // Assert
        final captured = verify(
          () => repository.insertStarAcquisition(
            userId: 'user-1',
            orderId: 'order-2',
            category: 2,
            acquiredPoints: captureAny(named: 'acquiredPoints'),
          ),
        ).captured;
        expect(captured.single as double, closeTo(1.66, 0.0001));
      });

      test('リポジトリが例外をthrowした場合は例外をラップしてthrowすること', () async {
        // Arrange
        final user = MockUser();
        when(() => user.id).thenReturn('user-1');
        when(() => goTrueClient.currentUser).thenReturn(user);
        when(
          () => repository.insertStarAcquisition(
            userId: any(named: 'userId'),
            orderId: any(named: 'orderId'),
            category: any(named: 'category'),
            acquiredPoints: any(named: 'acquiredPoints'),
          ),
        ).thenThrow(Exception('db error'));

        // Act & Assert
        await expectLater(
          () => service.insertStarAcquisition(orderId: 'order-1', category: 1, priceWithTax: 540),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getStarAcquisitionsByUserId', () {
      test('リポジトリから取得した履歴をそのまま返すこと', () async {
        // Arrange
        final history = [
          {'id': 1, 'acquired_points': 9.0},
        ];
        when(() => repository.getByUserId('user-1')).thenAnswer((_) async => history);

        // Act
        final result = await service.getStarAcquisitionsByUserId('user-1');

        // Assert
        expect(result, history);
      });

      test('リポジトリが例外をthrowした場合は例外をラップしてthrowすること', () async {
        // Arrange
        when(() => repository.getByUserId('user-1')).thenThrow(Exception('db error'));

        // Act & Assert
        await expectLater(
          () => service.getStarAcquisitionsByUserId('user-1'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
