import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

enum ServerStatus { unknown, checking, up, down }

class ServerStatusCubit extends Cubit<ServerStatus> {
  final String baseUrl;
  Timer? _poll;

  ServerStatusCubit(this.baseUrl) : super(ServerStatus.unknown);

  Future<void> check() async {
    emit(ServerStatus.checking);
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      emit(r.statusCode == 200 ? ServerStatus.up : ServerStatus.down);
    } catch (_) {
      emit(ServerStatus.down);
    }
  }

  void startPolling() {
    check();
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (state != ServerStatus.up) check();
    });
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}