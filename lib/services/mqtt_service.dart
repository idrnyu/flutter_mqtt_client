import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? _client;
  final _connectionStatus = StreamController<bool>.broadcast();
  final _messageController = StreamController<ReceivedMessage>.broadcast();

  Stream<bool> get connectionStream => _connectionStatus.stream;
  Stream<ReceivedMessage> get messageStream => _messageController.stream;

  Future<bool> connect(String broker, int port, {String? username, String? password, String clientId = 'flutter_client', int mqttVersion = 4}) async {
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 60;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.pongCallback = _pong;
    
    // 设置MQTT协议版本
    if (mqttVersion == 3) {
      _client!.setProtocolV31(); // 3.1
    } else if (mqttVersion == 4) {
      _client!.setProtocolV311(); // 3.1.1
    }
    // 注意：当前mqtt_client库版本(10.5.1)不支持MQTT 5.0
    // 如果选择了MQTT 5.0，我们默认使用3.1.1版本

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (username != null) {
      connMessage.authenticateAs(username, password);
    }

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      return true;
    } catch (e) {
      print('Exception: $e');
      _client!.disconnect();
      return false;
    }
  }

  void subscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage recMess = messages[0].payload as MqttPublishMessage;
        final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _messageController.add(ReceivedMessage(topic: messages[0].topic, message: message));
      });
    }
  }

  void unsubscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.unsubscribe(topic);
    }
  }

  void publish(String topic, String message) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void disconnect() {
    _client?.disconnect();
    _connectionStatus.add(false);
  }

  void _onConnected() {
    _connectionStatus.add(true);
  }

  void _onDisconnected() {
    _connectionStatus.add(false);
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void dispose() {
    _connectionStatus.close();
    _messageController.close();
    _client?.disconnect();
  }
}

class ReceivedMessage {
  final String topic;
  final String message;

  ReceivedMessage({required this.topic, required this.message});
}