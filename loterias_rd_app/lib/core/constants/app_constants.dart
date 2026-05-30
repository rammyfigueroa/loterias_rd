class AppConstants {
  static const appName = 'Loterias RD';
  static const apiResultsUrl = String.fromEnvironment(
    'LOTTERIES_API_URL',
    defaultValue: '',
  );
  static const sourceUrl = 'https://loteriasdominicanas.com/';
  static const requestTimeout = Duration(seconds: 14);
}
