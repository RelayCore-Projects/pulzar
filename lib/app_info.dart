/// Az alkalmazás állandó adatai.
class AppInfo {
  AppInfo._();

  static const name = 'Pulzar';

  /// A kiadott APK-ban a CI adja meg: --dart-define=APP_VERSION=0.2.0
  static const version =
      String.fromEnvironment('APP_VERSION', defaultValue: 'development build');

  static const repoUrl = 'https://github.com/RelayCore-Projects/pulzar';

  static const legalese = '© 2026 RelayCore-Projects · MIT License';

  static const disclaimer =
      'Pulzar is not a medical device and does not provide a diagnosis. '
      'Interpreting the values is up to your doctor.';

  /// FR-10: referenciavonal alapértékei (Hgmm / mmHg)
  static const defaultRefSystolic = 135;
  static const defaultRefDiastolic = 85;
}
