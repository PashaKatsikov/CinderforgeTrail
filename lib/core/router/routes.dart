/// Route paths, kept in one place so navigation calls never use raw strings.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const regions = '/regions';
  static const levels = '/levels';
  static const game = '/game';
  static const settings = '/settings';
  static const achievements = '/achievements';
  static const statistics = '/statistics';
  static const relics = '/relics';
  static const bestiary = '/bestiary';
  static const quests = '/quests';
  static const forge = '/forge';
  static const characters = '/characters';
  static const codex = '/codex';
  static const howToPlay = '/how-to-play';
  static const profile = '/profile';
  static const records = '/records';
  static const weather = '/weather';
  static const about = '/about';

  /// Hosted documents rendered in a web view with a bundled offline copy.
  static const privacy = '/document/policy';
  static const support = '/document/support';

  static String levelsOf(int region) => '$levels/$region';
  static String gameOf(int levelId) => '$game/$levelId';
}
