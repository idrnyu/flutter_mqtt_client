import 'package:flutter/foundation.dart';
import '../services/mqtt_service.dart';
import '../services/mqtt5_service.dart';
import '../models/ssl_config.dart';
import '../utils/mqtt_error_handler.dart';

// 统一消息类型，用于在Provider中处理
class UnifiedMessage {
  final String topic;
  final String message;

  UnifiedMessage({required this.topic, required this.message});
}

class MqttProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final Mqtt5Service _mqtt5Service = Mqtt5Service();
  bool _isConnected = false;
  List<UnifiedMessage> _messages = [];
  String _lastError = '';
  final Set<String> _subscribedTopics = {};
  int _currentMqttVersion = 4; // 默认为MQTT 3.1.1
  SslConfig _sslConfig = SslConfig();

  bool get isConnected => _isConnected;
  List<UnifiedMessage> get messages => _messages;
  String get lastError => _lastError;
  Set<String> get subscribedTopics => _subscribedTopics;
  int get currentMqttVersion => _currentMqttVersion;
  SslConfig get sslConfig => _sslConfig;

  MqttProvider() {
    _mqttService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    _mqttService.messageStream.listen((message) {
      _messages.add(UnifiedMessage(topic: message.topic, message: message.message));
      notifyListeners();
    });

    _mqtt5Service.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    _mqtt5Service.messageStream.listen((message) {
      _messages.add(UnifiedMessage(topic: message.topic, message: message.message));
      notifyListeners();
    });
  }

  Future<void> connect(String broker, int port, {String? username, String? password, String? clientId, int mqttVersion = 4, SslConfig? sslConfig}) async {
    try {
      _lastError = '连接中...';
      notifyListeners(); // 立即通知UI更新
      _currentMqttVersion = mqttVersion;
      if (sslConfig != null) {
        _sslConfig = sslConfig;
      }
      
      // 生成更短的客户端ID，以减小连接数据包大小
      String effectiveClientId = clientId ?? 'flutter_${DateTime.now().millisecondsSinceEpoch % 10000}';
      
      // 记录连接信息
      print('log： 连接到MQTT服务器: $broker:$port');
      print('log： MQTT版本: ${mqttVersion == 5 ? "5.0" : mqttVersion == 4 ? "3.1.1" : "3.1"}');
      print('log： 协议类型: ${_sslConfig.protocolType.name}');
      print('log： 客户端ID: $effectiveClientId');
      
      bool success = false;
      
      if (mqttVersion == 5) {
        // 使用MQTT 5.0
        print('log： 使用MQTT 5.0协议连接');
        success = await _mqtt5Service.connect(
          broker, 
          port, 
          username: username, 
          password: password,
          clientId: effectiveClientId,
          sslConfig: _sslConfig
        );
      } else {
        // 使用MQTT 3.1或3.1.1
        print('log： 使用MQTT ${mqttVersion == 4 ? "3.1.1" : "3.1"}协议连接');
        success = await _mqttService.connect(
          broker, 
          port, 
          username: username, 
          password: password,
          clientId: effectiveClientId,
          mqttVersion: mqttVersion,
          sslConfig: _sslConfig
        );
      }
      
      if (success) {
        _lastError = '';
        print('log： MQTT连接成功');
      } else {
        // 检查是否是MQTT5连接，并获取更详细的错误信息
        if (mqttVersion == 5) {
          // 尝试获取MQTT5的连接状态和原因码
          var connectionStatus = _mqtt5Service.getConnectionStatus();
          if (connectionStatus != null) {
            // 使用错误处理工具类获取友好的错误消息
            _lastError = '连接失败: ${MqttErrorHandler.getFriendlyErrorMessage(connectionStatus)}';
            
            // 如果是数据包过大错误，记录更多调试信息
            if (MqttErrorHandler.isPacketTooLargeError(connectionStatus)) {
              print('log： 检测到数据包过大错误，可能的解决方案:');
              MqttErrorHandler.getPacketTooLargeSolutions().forEach((solution) {
                print('log： - $solution');
              });
            }
          } else {
            _lastError = '连接失败';
          }
        } else {
          _lastError = '连接失败';
        }
      }
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      print('log： 连接异常: $e');
      notifyListeners();
    }
  }

  void updateSslConfig(SslConfig sslConfig) {
    _sslConfig = sslConfig;
    notifyListeners();
  }

  void subscribe(String topic) {
    if (_currentMqttVersion == 5) {
      _mqtt5Service.subscribe(topic);
    } else {
      _mqttService.subscribe(topic);
    }
    _subscribedTopics.add(topic);
    notifyListeners();
  }

  void unsubscribe(String topic) {
    if (_currentMqttVersion == 5) {
      _mqtt5Service.unsubscribe(topic);
    } else {
      _mqttService.unsubscribe(topic);
    }
    _subscribedTopics.remove(topic);
    notifyListeners();
  }

  void publish(String topic, String message) {
    if (_currentMqttVersion == 5) {
      _mqtt5Service.publish(topic, message);
    } else {
      _mqttService.publish(topic, message);
    }
  }

  void disconnect() {
    if (_currentMqttVersion == 5) {
      _mqtt5Service.disconnect();
    } else {
      _mqttService.disconnect();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _mqttService.dispose();
    _mqtt5Service.dispose();
    super.dispose();
  }
}