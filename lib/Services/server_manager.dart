import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart' as p;

class ServerService {
  static final ServerService _instance = ServerService._internal();
  factory ServerService() => _instance;
  ServerService._internal();

  Process? _process;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Start the Node.js server. Safe to call multiple times — it won't
  /// spawn a second process if one is already running.
  Future<void> start() async {
    if (_isRunning && _process != null) return;

    final appDir = p.dirname(Platform.resolvedExecutable);
    final serverPath = p.join(appDir, 'server', 'pharmacy-api.exe');

    if (!File(serverPath).existsSync()) {
      throw Exception('Server executable not found at: $serverPath');
    }

    _process = await Process.start(
      serverPath,
      ['--parent-pid', pid.toString()],  // ← add this
      workingDirectory: p.dirname(serverPath),
      mode: ProcessStartMode.normal,
    );
    _isRunning = true;

    // Pipe server logs to the Flutter console
    _process!.stdout
        .transform(const SystemEncoding().decoder)
        .listen((line) => _log('server', line));
    _process!.stderr
        .transform(const SystemEncoding().decoder)
        .listen((line) => _log('server:err', line, isError: true));

    // Detect when the server dies on its own
    _process!.exitCode.then((code) {
      _isRunning = false;
      _log('server', 'exited with code $code', isError: code != 0);
    });
  }

  /// Kill the server process. Call this when the app shuts down.
  Future<void> stop() async {
    if (_process == null) return;

    try {
      _process!.kill(ProcessSignal.sigterm);
      await _process!.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          _process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (_) {
      // Process may already be dead — ignore.
    } finally {
      _process = null;
      _isRunning = false;
    }
  }

  /// Quick health check — pings the /health endpoint.
  Future<bool> isHealthy({int port = 3000}) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 2);
      final req =
      await client.getUrl(Uri.parse('http://localhost:$port/health'));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Poll until the server responds, or timeout.
  Future<bool> waitUntilReady({
    int port = 3000,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await isHealthy(port: port)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  /// Central logging helper — safe for production, no lint warnings,
  /// and visible in DevTools' "Logging" tab.
  void _log(String name, String message, {bool isError = false}) {
    developer.log(
      message.trimRight(),
      name: name,
      level: isError ? 1000 : 800, // 1000 = SEVERE, 800 = INFO
    );
  }
}