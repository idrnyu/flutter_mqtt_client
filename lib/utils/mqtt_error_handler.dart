import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// MQTT5错误处理工具类
class Mqtt5ErrorHandler {
  /// 检查是否是数据包过大错误
  static bool isPacketTooLargeError(MqttConnectionStatus? status) {
    if (status == null) return false;
    return status.reasonCode == MqttConnectReasonCode.packetTooLarge;
  }
  
  /// 获取MQTT5连接错误的友好提示
  static String getFriendlyErrorMessage(MqttConnectionStatus? status) {
    if (status == null) return '未知错误';
    
    switch (status.reasonCode) {
      case MqttConnectReasonCode.packetTooLarge:
        return '数据包过大错误，请尝试以下解决方案:\n'
               '1. 使用更短的客户端ID\n'
               '2. 如果使用SSL/TLS，检查证书大小或考虑使用更小的证书\n'
               '3. 减小keepAlivePeriod值\n'
               '4. 简化连接消息配置';
      case MqttConnectReasonCode.notAuthorized:
        return '认证失败，请检查用户名和密码';
      case MqttConnectReasonCode.badUsernameOrPassword:
        return '用户名或密码错误';
      case MqttConnectReasonCode.serverUnavailable:
        return '服务器不可用，请稍后重试';
      case MqttConnectReasonCode.malformedPacket:
        return '数据包格式错误';
      case MqttConnectReasonCode.unspecifiedError:
        return '未指定错误，请检查连接配置';
      case MqttConnectReasonCode.serverMoved:
        return '服务器已移动，请更新服务器地址';
      case MqttConnectReasonCode.connectionRateExceeded:
        return '连接速率超限，请稍后重试';
      default:
        return '连接错误: ${status.reasonCode}';
    }
  }
  
  /// 获取解决packetTooLarge错误的建议
  static List<String> getPacketTooLargeSolutions() {
    return [
      '使用更短的客户端ID（10-20字符）',
      '减小keepAlivePeriod值（建议20-30秒）',
      '如果使用SSL/TLS，检查证书大小或考虑使用更小的证书',
      '简化连接消息配置，减少不必要的属性',
      '降低QoS级别（使用QoS 0代替QoS 1或2）',
      '检查是否有大量的遗嘱消息或用户属性',
    ];
  }
}


/// MQTT错误处理工具类
class MqttErrorHandler {
  /// 获取MQTT连接错误的友好提示
  static String getFriendlyErrorMessage(MqttClientConnectionStatus? status) {
    if (status == null) return '未知错误';

    switch (status.returnCode) {
      case MqttConnectReturnCode.notAuthorized:
        return '认证失败，请检查用户名和密码';
      case MqttConnectReturnCode.badUsernameOrPassword:
        return '用户名或密码错误';
      case MqttConnectReturnCode.unacceptedProtocolVersion:
        return '无效的协议版本';
      case MqttConnectReturnCode.identifierRejected:
        return '无效的客户端标识符';
      case MqttConnectReturnCode.brokerUnavailable:
        return 'Broker不可用';
      case MqttConnectReturnCode.noneSpecified:
        return '可能是不支持的协议';
      default:
        return '连接错误: ${status.returnCode}';
    }
  }
}