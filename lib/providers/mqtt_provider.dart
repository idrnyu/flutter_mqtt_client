import 'package:flutter/foundation.dart';
import '../services/mqtt_service.dart';

class MqttProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();
  bool _isConnected = false;
  List<ReceivedMessage> _messages = [];
  String _lastError = '';
  final Set<String> _subscribedTopics = {};

  bool get isConnected => _isConnected;
  List<ReceivedMessage> get messages => _messages;
  String get lastError => _lastError;
  Set<String> get subscribedTopics => _subscribedTopics;

  MqttProvider() {
    _mqttService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    _mqttService.messageStream.listen((message) {
      _messages.add(message);
      notifyListeners();
    });
  }

  Future<void> connect(String broker, int port, {String? username, String? password, String? clientId}) async {
    try {
      _lastError = '连接中...';
      final success = await _mqttService.connect(
        broker, 
        port, 
        username: username, 
        password: password,
        clientId: clientId ?? 'flutter_client'
      );
      if (success) {
        _lastError = '';
      } else {
        _lastError = '连接失败';
      }
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  void subscribe(String topic) {
    _mqttService.subscribe(topic);
    _subscribedTopics.add(topic);
    notifyListeners();
  }

  void unsubscribe(String topic) {
    _mqttService.unsubscribe(topic);
    _subscribedTopics.remove(topic);
    notifyListeners();
  }

  void publish(String topic, String message) {
    _mqttService.publish(topic, message);
  }

  void disconnect() {
    _mqttService.disconnect();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }
}