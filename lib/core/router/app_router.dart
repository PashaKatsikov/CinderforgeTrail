import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/boot/splash_screen.dart';
import '../../features/characters/characters_screen.dart';
import '../../features/codex/codex_screen.dart';
import '../../features/collection/bestiary_screen.dart';
import '../../features/collection/relics_screen.dart';
import '../../features/forge/forge_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/levels/level_select_screen.dart';
import '../../features/onboarding/how_to_play_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quests/quests_screen.dart';
import '../../features/records/records_screen.dart';
import '../../features/regions/regions_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/weather/weather_screen.dart';
import '../../features/web/web_page_screen.dart';
import '../../emberlink/pages/notify_invitation.dart';
import '../../emberlink/pages/offline_page.dart';
import '../../emberlink/pages/portal_view.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      _route(Routes.splash, (_, _) => const SplashScreen(), fade: true),
      _route(Routes.home, (_, _) => const HomeScreen(), fade: true),
      _route(Routes.regions, (_, _) => const RegionsScreen()),
      _route(
        '${Routes.levels}/:region',
        (_, state) => LevelSelectScreen(
          region: int.tryParse(state.pathParameters['region'] ?? '1') ?? 1,
        ),
      ),
      _route(
        '${Routes.game}/:levelId',
        (_, state) => GameScreen(
          levelId: int.tryParse(state.pathParameters['levelId'] ?? '0') ?? 0,
        ),
        fade: true,
      ),
      _route(Routes.settings, (_, _) => const SettingsScreen()),
      _route(Routes.achievements, (_, _) => const AchievementsScreen()),
      _route(Routes.statistics, (_, _) => const StatisticsScreen()),
      _route(Routes.relics, (_, _) => const RelicsScreen()),
      _route(Routes.bestiary, (_, _) => const BestiaryScreen()),
      _route(Routes.quests, (_, _) => const QuestsScreen()),
      _route(Routes.forge, (_, _) => const ForgeScreen()),
      _route(Routes.characters, (_, _) => const CharactersScreen()),
      _route(Routes.codex, (_, _) => const CodexScreen()),
      _route(Routes.howToPlay, (_, _) => const HowToPlayScreen()),
      _route(
        Routes.onboarding,
        (_, _) => const HowToPlayScreen(onboarding: true),
        fade: true,
      ),
      _route(Routes.profile, (_, _) => const ProfileScreen()),
      _route(Routes.records, (_, _) => const RecordsScreen()),
      _route(Routes.weather, (_, _) => const WeatherScreen()),
      _route(Routes.about, (_, _) => const AboutScreen()),
      _route(
        Routes.privacy,
        (_, _) => const WebPageScreen(document: WebDocument.privacy),
      ),
      _route(
        Routes.support,
        (_, _) => const WebPageScreen(document: WebDocument.support),
      ),
      _route(
        Routes.portal,
        (_, state) {
          final args = state.extra as PortalArgs?;
          return PortalView(
            url: args?.url ?? '',
            coldStart: args?.coldStart ?? false,
          );
        },
        fade: true,
      ),
      _route(
        Routes.notify,
        (context, state) {
          final url = state.extra as String? ?? '';
          return NotifyInvitation(
            onDone: () =>
                context.go(Routes.portal, extra: PortalArgs(url)),
          );
        },
        fade: true,
      ),
      _route(
        Routes.offline,
        (context, _) => OfflinePage(onRetry: () => context.go(Routes.splash)),
        fade: true,
      ),
    ],
    errorBuilder: (context, state) => _RouteNotFound(location: state.uri.path),
  );
});

/// Builds a route with the app's shared transition: a short slide plus fade.
GoRoute _route(
  String path,
  Widget Function(BuildContext, GoRouterState) builder, {
  bool fade = false,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: builder(context, state),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        if (fade) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_rounded, size: 40),
              const SizedBox(height: 16),
              Text('No trail leads to $location'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Back to camp'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
