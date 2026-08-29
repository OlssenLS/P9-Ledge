import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../providers/shared_prefs_provider.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (!hasSeenOnboarding && state.uri.path != '/onboarding') {
        return '/onboarding';
      }
      if (hasSeenOnboarding && state.uri.path == '/onboarding') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
