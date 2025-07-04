import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import '../models/ssl_config.dart';
import '../utils/mqtt_error_handler.dart';

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
  
  /// 获取当前连接状态
  MqttConnectionStatus? getConnectionStatus() {
    return _client?.connectionStatus;
  }

  Future<bool> connect(String broker, int port, {String? username, String? password, String clientId = 'flutter_client', SslConfig? sslConfig}) async {
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

    // 配置SSL/TLS
    if (sslConfig != null && sslConfig.protocolType == ProtocolType.mqtts) {
      await _configureSsl(sslConfig);
    }

    // MQTT 5.0特有的设置 - 简化连接消息以减小数据包大小
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean() // 使用clean session
        .withWillQos(MqttQos.atMostOnce); // 降低QoS级别以减小数据包大小

    if (username != null) {
      connMess.authenticateAs(username, password);
    }

    _client!.connectionMessage = connMess;

    try {
      print('log： 正在连接到MQTT5服务器: $broker:$port');
      await _client!.connect();
      print('log： 连接成功');
      return true;
    } catch (e) {
      print('log： 连接异常: $e');
      // 检查是否是packetTooLarge错误
      if (_client!.connectionStatus != null) {
        print('log： 连接状态: ${_client!.connectionStatus!.state}');
        print('log： 原因码: ${_client!.connectionStatus!.reasonCode}');
        if (_client!.connectionStatus!.reasonCode == MqttConnectReasonCode.packetTooLarge) {
          print('log： 数据包过大错误，尝试简化连接配置或减小证书大小');
        }
      }
      _client!.disconnect();
      return false;
    }
  }

  Future<void> _configureSsl(SslConfig sslConfig) async {
    if (!sslConfig.sslEnabled) return;

    try {
      print('log： 配置SSL/TLS连接');
      SecurityContext? securityContext;
      
      if (sslConfig.certificateType == CertificateType.selfSigned) {
        // 自签名证书配置
        print('log： 使用自签名证书配置');
        securityContext = SecurityContext(withTrustedRoots: false);
        
        if (sslConfig.caFilePath != null && sslConfig.caFilePath!.isNotEmpty) {
          final caFile = File(sslConfig.caFilePath!);
          if (await caFile.exists()) {
            print('log： 加载CA证书: ${sslConfig.caFilePath}');
            // 检查证书文件大小
            final fileSize = await caFile.length();
            print('log： CA证书文件大小: ${fileSize} 字节');
            if (fileSize > 10240) { // 如果大于10KB
              print('log： 警告: CA证书文件较大，可能导致数据包过大错误');
            }
            securityContext.setTrustedCertificates(sslConfig.caFilePath!);
          } else {
            print('log： 错误: CA证书文件不存在: ${sslConfig.caFilePath}');
          }
        }
        
        // 仅在必要时加载客户端证书和私钥
        bool needClientAuth = sslConfig.clientCertPath != null && sslConfig.clientCertPath!.isNotEmpty &&
                             sslConfig.clientKeyPath != null && sslConfig.clientKeyPath!.isNotEmpty;
        
        if (needClientAuth) {
          final certFile = File(sslConfig.clientCertPath!);
          final keyFile = File(sslConfig.clientKeyPath!);
          
          if (await certFile.exists() && await keyFile.exists()) {
            print('log： 加载客户端证书: ${sslConfig.clientCertPath}');
            print('log： 加载客户端私钥: ${sslConfig.clientKeyPath}');
            
            // 检查证书和私钥文件大小
            final certSize = await certFile.length();
            final keySize = await keyFile.length();
            print('log： 客户端证书文件大小: ${certSize} 字节');
            print('log： 客户端私钥文件大小: ${keySize} 字节');
            
            if (certSize + keySize > 10240) { // 如果总大小大于10KB
              print('log： 警告: 客户端证书和私钥文件较大，可能导致数据包过大错误');
            }
            
            securityContext.useCertificateChain(sslConfig.clientCertPath!);
            securityContext.usePrivateKey(sslConfig.clientKeyPath!);
          } else {
            print('log： 错误: 客户端证书或私钥文件不存在');
          }
        } else {
          print('log： 未配置客户端证书和私钥');
        }
      } else {
        // CA签名证书配置
        print('log： 使用CA签名证书配置');
        securityContext = SecurityContext(withTrustedRoots: true);
        
        if (sslConfig.caFilePath != null && sslConfig.caFilePath!.isNotEmpty) {
          final caFile = File(sslConfig.caFilePath!);
          if (await caFile.exists()) {
            print('log： 加载CA证书: ${sslConfig.caFilePath}');
            // 检查证书文件大小
            final fileSize = await caFile.length();
            print('log： CA证书文件大小: ${fileSize} 字节');
            securityContext.setTrustedCertificates(sslConfig.caFilePath!);
          } else {
            print('log： 警告: CA证书文件不存在，将使用系统根证书');
          }
        } else {
          print('log： 使用系统根证书');
        }
      }

      _client!.secure = true;
      _client!.securityContext = securityContext;
      
      if (!sslConfig.verifyServerCertificate) {
        print('log： 禁用服务器证书验证');
        _client!.onBadCertificate = (cert) => true;
      } else {
        print('log： 启用服务器证书验证');
        _client!.onBadCertificate = null;
      }
      
      print('log： SSL/TLS配置完成');
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
      // 取消消息监听器
      _messageSubscription?.cancel();
      _messageSubscription = null;
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
    
    // 记录断开连接的详细信息
    if (_client?.connectionStatus != null) {
      print('log： MQTT5断开连接');
      print('log： 连接状态: ${_client!.connectionStatus!.state}');
      print('log： 原因码: ${_client!.connectionStatus!.reasonCode}');
      
      // 使用错误处理工具类处理断开连接错误
      String errorMessage = Mqtt5ErrorHandler.getFriendlyErrorMessage(_client!.connectionStatus);
      print('log： 断开原因: $errorMessage');
      
      // 特别处理packetTooLarge错误
      if (Mqtt5ErrorHandler.isPacketTooLargeError(_client!.connectionStatus)) {
        print('log： 数据包过大错误，可能的解决方案:');
        Mqtt5ErrorHandler.getPacketTooLargeSolutions().forEach((solution) {
          print('log： - $solution');
        });
      }
    }
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