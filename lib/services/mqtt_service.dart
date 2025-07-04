import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/ssl_config.dart';

class MqttService {
  MqttServerClient? _client;
  final _connectionStatus = StreamController<bool>.broadcast();
  final _messageController = StreamController<ReceivedMessage>.broadcast();

  Stream<bool> get connectionStream => _connectionStatus.stream;
  Stream<ReceivedMessage> get messageStream => _messageController.stream;

  /// 获取当前连接状态
  getConnectionStatus() {
    return _client?.connectionStatus;
  }

  Future<bool> connect(String broker, int port, {String? username, String? password, String clientId = 'flutter_client', int mqttVersion = 4, SslConfig? sslConfig}) async {
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

    // 配置SSL/TLS
    if (sslConfig != null && sslConfig.protocolType == ProtocolType.mqtts) {
      await _configureSsl(sslConfig);
    }

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    if (username != null) {
      connMessage.authenticateAs(username, password);
    }

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      return true;
    } catch (e) {
      print('log： Exception: $e');
      _client!.disconnect();
      return false;
    }
  }

  Future<void> _configureSsl(SslConfig sslConfig) async {
    if (!sslConfig.sslEnabled) return;

    try {
      SecurityContext? securityContext;
      
      if (sslConfig.certificateType == CertificateType.selfSigned) {
        // 自签名证书配置
        securityContext = SecurityContext(withTrustedRoots: false);
        
        if (sslConfig.caFilePath != null && sslConfig.caFilePath!.isNotEmpty) {
          final caFile = File(sslConfig.caFilePath!);
          if (await caFile.exists()) {
            securityContext.setTrustedCertificates(sslConfig.caFilePath!);
          }
        }
        
        if (sslConfig.clientCertPath != null && sslConfig.clientCertPath!.isNotEmpty &&
            sslConfig.clientKeyPath != null && sslConfig.clientKeyPath!.isNotEmpty) {
          final certFile = File(sslConfig.clientCertPath!);
          final keyFile = File(sslConfig.clientKeyPath!);
          
          if (await certFile.exists() && await keyFile.exists()) {
            securityContext.useCertificateChain(sslConfig.clientCertPath!);
            securityContext.usePrivateKey(sslConfig.clientKeyPath!);
          }
        }
      } else {
        // CA签名证书配置
        securityContext = SecurityContext(withTrustedRoots: true);
        
        if (sslConfig.caFilePath != null && sslConfig.caFilePath!.isNotEmpty) {
          final caFile = File(sslConfig.caFilePath!);
          if (await caFile.exists()) {
            securityContext.setTrustedCertificates(sslConfig.caFilePath!);
          }
        }
      }

      _client!.secure = true;
      _client!.securityContext = securityContext;
      _client!.onBadCertificate = sslConfig.verifyServerCertificate ? null : (cert) => true;
      
    } catch (e) {
      print('log： SSL配置错误: $e');
      throw Exception('SSL配置失败: $e');
    }
  }

  // 存储消息监听器的订阅对象，用于取消订阅时移除监听器
  StreamSubscription? _messageSubscription;

  void subscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      // 先取消之前的监听器，避免重复接收消息
      _messageSubscription?.cancel();
      
      // 订阅主题
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      
      // 添加新的监听器
      _messageSubscription = _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage recMess = messages[0].payload as MqttPublishMessage;
        final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _messageController.add(ReceivedMessage(topic: messages[0].topic, message: message));
      });
    }
  }

  void unsubscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.unsubscribe(topic);
      // 取消消息监听器
      _messageSubscription?.cancel();
      _messageSubscription = null;
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
    print('log： Subscribed to topic: $topic');
  }

  void _pong() {
    print('log： Ping response received');
  }

  void dispose() {
    // 取消消息监听器
    _messageSubscription?.cancel();
    _messageSubscription = null;
    
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