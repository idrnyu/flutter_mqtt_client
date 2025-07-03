# Flutter MQTT客户端

这是一个基于Flutter的MQTT客户端应用，支持MQTT 3.1、3.1.1和5.0协议，以及SSL/TLS安全连接。

## 功能特性

- 支持MQTT 3.1、3.1.1和5.0协议
- 支持SSL/TLS安全连接
- 支持CA签名和自签名证书
- 支持订阅和发布消息
- 支持用户名/密码认证
- 实时显示连接状态和错误信息

## MQTT5连接问题解决方案

### 问题：数据包过大错误 (packetTooLarge)

当使用MQTT5 + MQTTS连接时，可能会遇到以下错误：

```
mqtt-client::NoConnectionException: The maximum allowed connection attempts ({3}) were exceeded. The broker is not responding to the connection request message correctly The reason code is MqttConnectReasonCode.packetTooLarge
```

### 解决方案

1. **使用更短的客户端ID**
   - 应用已更新为使用更短的客户端ID格式：`flutter_XXXX`，其中XXXX是时间戳的后4位数字
   - 避免使用过长的客户端ID，建议保持在20个字符以内

2. **减小心跳周期**
   - 应用已将默认心跳周期从60秒减小到20秒
   - 这有助于减小连接数据包的大小

3. **SSL/TLS证书优化**
   - 如果使用自签名证书，确保证书文件不要过大（建议小于10KB）
   - 应用现在会检测证书文件大小并提供警告

4. **简化连接消息**
   - 应用已优化MQTT5连接消息，减少不必要的属性
   - 降低QoS级别（从QoS 1降至QoS 0）以减小数据包大小

5. **避免使用大量的用户属性或遗嘱消息**
   - 减少连接消息中的自定义属性
   - 如果使用遗嘱消息，保持其简短

## 使用说明

1. 在连接设置中选择MQTT版本（3.1、3.1.1或5.0）
2. 选择协议类型（mqtt://或mqtts://）
3. 输入Broker地址、端口和客户端ID
4. 如果需要，提供用户名和密码
5. 如果使用mqtts://，配置SSL/TLS设置
6. 点击连接按钮

## SSL/TLS配置

### CA签名证书

- 选择证书类型为"CA Signed Server"
- 可选择提供CA证书文件

### 自签名证书

- 选择证书类型为"Self Signed"
- 提供CA证书文件
- 可选择提供客户端证书和私钥文件

## 调试信息

应用现在提供更详细的连接错误信息和解决方案建议。当遇到连接问题时，请查看控制台日志以获取更多信息。

## 构建和安装

```bash
flutter pub get --no-example
flutter pub get
flutter build apk
flutter install
```