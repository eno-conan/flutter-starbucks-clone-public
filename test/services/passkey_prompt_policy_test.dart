import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testingapp/services/passkey_prompt_policy.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'user-1';
  const countKey = 'passkey_prompt_snooze_count_$userId';
  const snoozedAtKey = 'passkey_prompt_snoozed_at_$userId';

  late MockSupabaseClient supabaseClient;
  late MockGoTrueClient goTrueClient;

  /// 起動ごとの重複提案を防ぐフラグはインスタンスが持つため、
  /// テストごとに新しいインスタンスを作る
  PasskeyPromptPolicy createPolicy() => PasskeyPromptPolicy(supabaseClient);

  int millisAgo(Duration duration) => DateTime.now().subtract(duration).millisecondsSinceEpoch;

  setUp(() {
    supabaseClient = MockSupabaseClient();
    goTrueClient = MockGoTrueClient();
    final user = MockUser();

    when(() => supabaseClient.auth).thenReturn(goTrueClient);
    when(() => goTrueClient.currentUser).thenReturn(user);
    when(() => user.id).thenReturn(userId);

    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('PasskeyPromptPolicy.tryStartPrompt', () {
    test('断った履歴がなければ提案してよい', () async {
      final policy = createPolicy();

      expect(await policy.tryStartPrompt(), isTrue);
    });

    test('同じ起動では2回目以降は提案しない', () async {
      final policy = createPolicy();

      expect(await policy.tryStartPrompt(), isTrue);
      expect(await policy.tryStartPrompt(), isFalse);
    });

    test('未ログインなら提案しない', () async {
      when(() => goTrueClient.currentUser).thenReturn(null);

      expect(await createPolicy().tryStartPrompt(), isFalse);
    });

    test('1回断られてから7日経っていなければ提案しない', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        countKey: 1,
        snoozedAtKey: millisAgo(const Duration(days: 6)),
      });

      expect(await createPolicy().tryStartPrompt(), isFalse);
    });

    test('1回断られてから7日経っていれば提案する', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        countKey: 1,
        snoozedAtKey: millisAgo(const Duration(days: 8)),
      });

      expect(await createPolicy().tryStartPrompt(), isTrue);
    });

    test('2回断られたあとの間隔は30日になる', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        countKey: 2,
        snoozedAtKey: millisAgo(const Duration(days: 10)),
      });
      expect(await createPolicy().tryStartPrompt(), isFalse);

      SharedPreferences.setMockInitialValues(<String, Object>{
        countKey: 2,
        snoozedAtKey: millisAgo(const Duration(days: 31)),
      });
      expect(await createPolicy().tryStartPrompt(), isTrue);
    });

    test('3回断られたら以降は提案しない', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        countKey: 3,
        snoozedAtKey: millisAgo(const Duration(days: 365)),
      });

      expect(await createPolicy().tryStartPrompt(), isFalse);
    });

    test('回数だけが残っていても提案する（記録が途中で失敗した場合）', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{countKey: 1});

      expect(await createPolicy().tryStartPrompt(), isTrue);
    });
  });

  group('PasskeyPromptPolicy.recordDeclined', () {
    test('断った回数を増やし、断った日時を記録する', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{countKey: 1});

      await createPolicy().recordDeclined();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(countKey), 2);
      expect(prefs.getInt(snoozedAtKey), isNotNull);
    });

    test('未ログインなら何も記録しない', () async {
      when(() => goTrueClient.currentUser).thenReturn(null);

      await createPolicy().recordDeclined();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(countKey), isNull);
    });
  });

  group('PasskeyPromptPolicy.clearSnooze', () {
    test('断った履歴を消す', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        countKey: 2,
        snoozedAtKey: millisAgo(const Duration(days: 1)),
      });

      await createPolicy().clearSnooze();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(countKey), isNull);
      expect(prefs.getInt(snoozedAtKey), isNull);
    });
  });
}
