class VersionInfo {
  final String app;
  final String environment;
  final String flag;
  final String build;

  const VersionInfo({
    required this.app,
    required this.environment,
    required this.flag,
    required this.build,
  });

  @override
  String toString() {
    return 'VersionInfo(app: $app\n environment: $environment\n flag: $flag\n build: $build)';
  }
}
