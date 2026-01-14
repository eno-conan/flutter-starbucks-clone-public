import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod の状態管理をモニタリング
final class Observers extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderObserverContext context, Object? previousValue, Object? newValue) {
    log('''
{
  "provider": "${context.provider.name ?? context.provider.runtimeType}",
  "newValue": "$newValue"
}''');
    super.didUpdateProvider(context, previousValue, newValue);
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    log('''
{
  "provider": "${context.provider.name ?? context.provider.runtimeType}",
  "newValue": "$value"
}''');
    super.didAddProvider(context, value);
  }
}
