import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class NodeServerManager {
  Process? _serverProcess;

  Future<void> startServer() async {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final serverExePath = p.join(exeDir, 'zpharmacy-server.exe');

    if (!File(serverExePath).existsSync()) {
      throw Exception('Server executable not found at: $serverExePath');
    }

    _serverProcess = await Process.start(
      serverExePath,
      [],
      workingDirectory: exeDir,
    );

    _serverProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => print('[Server] $line'));

    _serverProcess!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => print('[Server Error] $line'));

    // Detect if the server crashes immediately.
    _serverProcess!.exitCode.then((code) {
      print('[Server] exited with code $code');
      _serverProcess = null;
    });
  }

  Future<void> stopServer() async {
    final proc = _serverProcess;
    if (proc == null) return;
    proc.kill(ProcessSignal.sigterm);
    // Give it a moment, then force-kill if still alive (Windows-safe).
    await Future.delayed(const Duration(seconds: 1));
    if (_serverProcess != null) {
      proc.kill(ProcessSignal.sigkill);
    }
    _serverProcess = null;
  }
}