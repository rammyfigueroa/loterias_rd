class FirstPrizeStatisticsConfig {
  static const enabled = bool.fromEnvironment(
    'FIRST_PRIZE_STATS_ENABLED',
    defaultValue: false,
  );

  static const apiBaseUrl = String.fromEnvironment(
    'FIRST_PRIZE_STATS_API_URL',
    defaultValue: '',
  );

  static bool get available => enabled && apiBaseUrl.trim().isNotEmpty;
}
