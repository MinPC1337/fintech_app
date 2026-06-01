/// Cloudflare Worker URL for push delivery.
///
/// `flutter run --dart-define=PUSH_WORKER_URL=https://fintech-push.<account>.workers.dev`
class PushConfig {
  static const String workerUrl = String.fromEnvironment(
    'PUSH_WORKER_URL',
    defaultValue: '',
  );

  static bool get isConfigured =>
      workerUrl.isNotEmpty && workerUrl.startsWith('http');
}
