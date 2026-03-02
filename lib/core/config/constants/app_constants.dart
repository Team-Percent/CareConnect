class AppConstants {
  static const String appName = 'HealthWallet';

  // ─── API Server (placeholder for future OHC Network API) ──────────────
  // 10.211.171.115 is the host computer's local IP (accessible from Android device / emulator)
  static const String hostIp = '10.211.171.115';

  // Legacy base URL (keep for any internal REST calls)
  static const String baseUrl = 'http://$hostIp:8000/api/v1';

  // Timeouts
  static const connectTimeout = Duration(minutes: 3);
  static const receiveTimeout = Duration(minutes: 3);
  static const sendTimeout = Duration(minutes: 3);

  // Pagination
  static const int pageSize = 10;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 1);

  static const String modelUrl =
      'https://huggingface.co/google/gemma-2b-it-tflite/resolve/main/gemma-2b-it-gpu-int4.bin';
  static const String modelId = 'gemma-2b-it-gpu-int4.bin';
}
