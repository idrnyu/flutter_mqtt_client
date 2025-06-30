import 'dart:async';
import 'dart:convert';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

// 定义与mqtt_service.dart中相同的消息类，避免导入冲突
class Mqtt5ReceivedMessage {
  final String topic;
  final String message;

  Mqtt5ReceivedMessage({required this.topic, required this.message});
}

class Mqtt5Service {
  MqttServerClient? _client;
  final _connectionStatus = StreamController<bool>.broadcast();
  final _messageController = StreamController<Mqtt5ReceivedMessage>.broadcast();

  Stream<bool> get connectionStream => _connectionStatus.stream;
  Stream<Mqtt5ReceivedMessage> get messageStream => _messageController.stream;

  Future<bool> connect(String broker, int port, {String? username, String? password, String clientId = 'flutter_client'}) async {
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 60;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    // MQTT5客户端的onSubscribed回调接受MqttSubscription类型参数
    _client!.onSubscribed = (MqttSubscription subscription) {
      _onSubscribed(subscription.topic.toString());
    };
    _client!.pongCallback = _pong;

    // MQTT 5.0特有的设置
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (username != null) {
      connMess.authenticateAs(username, password);
    }

    _client!.connectionMessage = connMess;

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
        // 使用utf8.decode解码消息内容
        final String message = recMess.payload.message != null 
            ? utf8.decode(recMess.payload.message!.toList()) 
            : '';
        _messageController.add(Mqtt5ReceivedMessage(topic: messages[0].topic ?? '', message: message));
      });
    }
  }

  void unsubscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      // MQTT5客户端使用unsubscribeStringTopic方法
      _client!.unsubscribeStringTopic(topic);
    }
  }

  void publish(String topic, String message) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      // 使用UTF8编码消息内容
      final builder = MqttPayloadBuilder();
      builder.addUTF8String(message);
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