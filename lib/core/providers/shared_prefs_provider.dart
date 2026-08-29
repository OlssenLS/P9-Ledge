import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_prefs_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferences must be overridden in main');
}

@riverpod
bool hasSeenOnboarding(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('hasSeenOnboarding') ?? false;
}
