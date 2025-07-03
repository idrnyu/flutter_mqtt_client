import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/mqtt_provider.dart';
import '../models/ssl_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final _brokerController = TextEditingController(text: 'iot.idrnyu.top');
  final _brokerController = TextEditingController(text: 'j91fc661.ala.cn-hangzhou.emqxsl.cn');
  final _portController = TextEditingController(text: '1883');
  // 使用更短的客户端ID，减小连接数据包大小
  final _clientIdController = TextEditingController(text: 'flutter_${DateTime.now().millisecondsSinceEpoch % 10000}');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subscribeTopicController = TextEditingController();
  final _publishTopicController = TextEditingController();
  final _messageController = TextEditingController();
  
  // MQTT版本选择
  int _selectedMqttVersion = 4; // 默认为MQTT 3.1.1
  
  // SSL配置
  ProtocolType _selectedProtocol = ProtocolType.mqtt;
  bool _sslEnabled = false;
  bool _verifyServerCertificate = true;
  CertificateType _selectedCertificateType = CertificateType.caSigned;
  String? _caFilePath;
  String? _clientCertPath;
  String? _clientKeyPath;

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _subscribeTopicController.dispose();
    _publishTopicController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('MQTT客户端'),
        actions: [
          Consumer<MqttProvider>(
            builder: (context, mqttProvider, child) {
              return IconButton(
                icon: Icon(
                  mqttProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: mqttProvider.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  if (mqttProvider.isConnected) {
                    mqttProvider.disconnect();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<MqttProvider>(
        builder: (context, mqttProvider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6.0, right: 6.0, top: 6.0, bottom: 300.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildConnectionSection(mqttProvider),
                        const SizedBox(height: 6),
                        _buildSubscribeSection(mqttProvider),
                        const SizedBox(height: 6),
                        _buildSubscriptionsList(mqttProvider),
                        const SizedBox(height: 6),
                        _buildMessagesSection(mqttProvider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Consumer<MqttProvider>(
        builder: (context, mqttProvider, child) {
          return AnimatedPadding(
            padding: const EdgeInsets.only(
              bottom: 0,
              left: 0,
              right: 0,
              top: 0,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                // borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '发布消息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _publishTopicController,
                            decoration: const InputDecoration(
                              labelText: '主题',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            enabled: mqttProvider.isConnected,
                            onChanged: (value) {
                              // 强制更新UI以反映文本变化
                              setState(() {});
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: mqttProvider.isConnected && 
                                     _publishTopicController.text.isNotEmpty &&
                                     _messageController.text.isNotEmpty
                              ? () {
                                  mqttProvider.publish(
                                    _publishTopicController.text,
                                    _messageController.text,
                                  );
                                  _messageController.clear();
                                }
                              : null,
                          child: const Text('发布'),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: '消息内容',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      enabled: mqttProvider.isConnected,
                      onChanged: (value) {
                        // 强制更新UI以反映文本变化
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 添加一个状态变量来控制连接设置的展开/收起状态
  bool _isConnectionExpanded = false;

  Widget _buildConnectionSection(MqttProvider mqttProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题行，包含展开/收起按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '连接设置',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: Icon(_isConnectionExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isConnectionExpanded = !_isConnectionExpanded;
                    });
                  },
                ),
              ],
            ),
            
            // 始终显示的内容：Broker地址和协议
            Row(
              children: [
                Expanded(
                  child: Text('Broker: ${_brokerController.text}'),
                ),
                const SizedBox(width: 8),
                Text('${_selectedProtocol == ProtocolType.mqtt ? "mqtt://" : "mqtts://"} ${_selectedMqttVersion == 3 ? "3.1" : _selectedMqttVersion == 4 ? "3.1.1" : "5.0"}'),
              ],
            ),
            
            // 展开时显示的详细设置
            if (_isConnectionExpanded) ...[  
              const SizedBox(height: 16),
              
              // 协议选择
              DropdownButtonFormField<ProtocolType>(
                decoration: const InputDecoration(
                  labelText: '协议类型',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: _selectedProtocol,
                items: const [
                  DropdownMenuItem(value: ProtocolType.mqtt, child: Text('mqtt://')),
                  DropdownMenuItem(value: ProtocolType.mqtts, child: Text('mqtts://')),
                ],
                onChanged: mqttProvider.isConnected
                    ? null
                    : (value) {
                        setState(() {
                          _selectedProtocol = value!;
                          if (value == ProtocolType.mqtts) {
                            _sslEnabled = true;
                            _portController.text = '8883'; // 默认SSL端口
                          } else {
                            _sslEnabled = false;
                            _portController.text = '1883'; // 默认非SSL端口
                          }
                        });
                      },
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _brokerController,
                decoration: const InputDecoration(
                  labelText: 'Broker地址',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                enabled: !mqttProvider.isConnected,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '端口',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                enabled: !mqttProvider.isConnected,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: '客户端ID',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                enabled: !mqttProvider.isConnected,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名（可选）',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                enabled: !mqttProvider.isConnected,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码（可选）',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                obscureText: true,
                enabled: !mqttProvider.isConnected,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'MQTT版本',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: _selectedMqttVersion,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('MQTT 3.1')),
                  DropdownMenuItem(value: 4, child: Text('MQTT 3.1.1')),
                  DropdownMenuItem(value: 5, child: Text('MQTT 5.0')),
                ],
                onChanged: mqttProvider.isConnected
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMqttVersion = value!;
                        });
                      },
              ),
              
              // SSL配置部分
              if (_selectedProtocol == ProtocolType.mqtts) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'SSL/TLS 配置',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // SSL开关
                SwitchListTile(
                  title: const Text('启用 SSL/TLS'),
                  subtitle: const Text('使用安全连接'),
                  value: _sslEnabled,
                  onChanged: mqttProvider.isConnected
                      ? null
                      : (value) {
                          setState(() {
                            _sslEnabled = value;
                          });
                        },
                ),
                
                // SSL安全验证开关
                SwitchListTile(
                  title: const Text('验证服务端证书'),
                  subtitle: const Text('验证服务端证书链和地址名称'),
                  value: _verifyServerCertificate,
                  onChanged: mqttProvider.isConnected || !_sslEnabled
                      ? null
                      : (value) {
                          setState(() {
                            _verifyServerCertificate = value;
                          });
                        },
                ),
                
                // 证书类型选择
                DropdownButtonFormField<CertificateType>(
                  decoration: const InputDecoration(
                    labelText: '证书类型',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedCertificateType,
                  items: const [
                    DropdownMenuItem(value: CertificateType.caSigned, child: Text('CA Signed Server')),
                    DropdownMenuItem(value: CertificateType.selfSigned, child: Text('Self Signed')),
                  ],
                  onChanged: mqttProvider.isConnected || !_sslEnabled
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCertificateType = value!;
                          });
                        },
                ),
                
                // 自签名证书文件选择
                if (_selectedCertificateType == CertificateType.selfSigned) ...[
                  const SizedBox(height: 8),
                  _buildFilePickerField(
                    'CA 证书文件',
                    _caFilePath,
                    (path) => setState(() => _caFilePath = path),
                    mqttProvider.isConnected,
                  ),
                  const SizedBox(height: 8),
                  _buildFilePickerField(
                    '客户端证书文件',
                    _clientCertPath,
                    (path) => setState(() => _clientCertPath = path),
                    mqttProvider.isConnected,
                  ),
                  const SizedBox(height: 8),
                  _buildFilePickerField(
                    '客户端私钥文件',
                    _clientKeyPath,
                    (path) => setState(() => _clientKeyPath = path),
                    mqttProvider.isConnected,
                  ),
                ],
                
                // CA签名证书文件选择
                if (_selectedCertificateType == CertificateType.caSigned) ...[
                  const SizedBox(height: 8),
                  _buildFilePickerField(
                    'CA 证书文件（可选）',
                    _caFilePath,
                    (path) => setState(() => _caFilePath = path),
                    mqttProvider.isConnected,
                  ),
                ],
              ],
            ],
            
            const SizedBox(height: 16),
            if (!mqttProvider.isConnected)
              ElevatedButton(
                onPressed: () async {
                  // 创建SSL配置
                  SslConfig sslConfig = SslConfig(
                    protocolType: _selectedProtocol,
                    sslEnabled: _sslEnabled,
                    verifyServerCertificate: _verifyServerCertificate,
                    certificateType: _selectedCertificateType,
                    caFilePath: _caFilePath,
                    clientCertPath: _clientCertPath,
                    clientKeyPath: _clientKeyPath,
                  );
                  
                  await mqttProvider.connect(
                    _brokerController.text,
                    int.parse(_portController.text),
                    clientId: _clientIdController.text,
                    username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
                    password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
                    mqttVersion: _selectedMqttVersion,
                    sslConfig: sslConfig,
                  );
                },
                child: const Text('连接'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  mqttProvider.disconnect();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('断开连接'),
              ),
            
            if (mqttProvider.lastError.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Text(
                mqttProvider.lastError,
                style: TextStyle(
                  color: mqttProvider.lastError.contains('连接中') ? Colors.blue : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeSection(MqttProvider mqttProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '订阅主题',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subscribeTopicController,
                    decoration: const InputDecoration(
                      labelText: '主题',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    enabled: mqttProvider.isConnected,
                    onChanged: (value) {
                      // 强制更新UI以反映文本变化
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: mqttProvider.isConnected && _subscribeTopicController.text.isNotEmpty
                      ? () {
                          mqttProvider.subscribe(_subscribeTopicController.text);
                          _subscribeTopicController.clear();
                        }
                      : null,
                  child: const Text('订阅'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(MqttProvider mqttProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '已订阅主题',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (mqttProvider.subscribedTopics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('暂无订阅主题'),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mqttProvider.subscribedTopics.length,
                  itemBuilder: (context, index) {
                    final topic = mqttProvider.subscribedTopics.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(topic),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        iconSize: 16,
                        onPressed: () {
                          mqttProvider.unsubscribe(topic);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesSection(MqttProvider mqttProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '接收到的消息',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (mqttProvider.messages.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      mqttProvider.clearMessages();
                    },
                    child: const Text('清空'),
                  ),
              ],
            ),
            if (mqttProvider.messages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('暂无消息'),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mqttProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = mqttProvider.messages[mqttProvider.messages.length - 1 - index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '主题: ${message.topic}',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        Text(
                          '消息: ${message.message}',
                          style: const TextStyle(fontSize: 12),
                          // maxLines: 10,
                          // overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerField(
    String label,
    String? currentPath,
    Function(String?) onPathSelected,
    bool disabled,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: label,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: currentPath != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: disabled ? null : () => onPathSelected(null),
                    )
                  : null,
            ),
            readOnly: true,
            controller: TextEditingController(text: currentPath ?? ''),
            enabled: false,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: disabled
              ? null
              : () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pem', 'crt', 'key', 'p12', 'pfx'],
                  );
                  if (result != null) {
                    onPathSelected(result.files.single.path);
                  }
                },
          child: const Text('选择'),
        ),
      ],
    );
  }
}