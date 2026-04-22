import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'secure_storage_service.dart';
import 'api_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  final SecureStorageService _storage = SecureStorageService();
  
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => socket?.connected ?? false;

  Future<void> init() async {
    final token = await _storage.getAccessToken();
    if (token == null) return;

    if (socket != null) {
      socket!.dispose();
    }

    // Using Render URL for Sockets
    socket = io.io(ApiClient.renderBaseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .build());

    socket!.onConnect((_) {
      // Socket connected
      _connectionController.add(true);
    });

    socket!.onDisconnect((_) {
      // Socket disconnected
      _connectionController.add(false);
    });

    socket!.onConnectError((err) { /* Socket connection error: $err */ });
    socket!.onError((err) { /* Socket error: $err */ });

    socket!.connect();
  }
  
  Future<void> updateToken(String newToken) async {
    if (socket != null) {
      socket!.auth = {'token': newToken};
      socket!.disconnect().connect();
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    _connectionController.add(false);
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  Future<io.Socket?> createNamespacedSocket(String namespace) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final nspSocket = io.io('${ApiClient.renderBaseUrl}/$namespace', io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());
    
    return nspSocket;
  }
}

