import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _brokerController = TextEditingController(text: 'iot.idrnyu.top');
  final _portController = TextEditingController(text: '1883');
  final _clientIdController = TextEditingController(text: 'flutter_client');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subscribeTopicController = TextEditingController();
  final _publishTopicController = TextEditingController();
  final _messageController = TextEditingController();
  
  // MQTT版本选择
  int _selectedMqttVersion = 4; // 默认为MQTT 3.1.1

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
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0, bottom: 150.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildConnectionSection(mqttProvider),
                        const SizedBox(height: 10),
                        _buildSubscribeSection(mqttProvider),
                        const SizedBox(height: 10),
                        _buildSubscriptionsList(mqttProvider),
                        const SizedBox(height: 10),
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
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 10.0,
              left: 10.0,
              right: 10.0,
              top: 10.0,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 8),
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
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: mqttProvider.isConnected
                              ? () {
                                  if (_publishTopicController.text.isNotEmpty &&
                                      _messageController.text.isNotEmpty) {
                                    mqttProvider.publish(
                                      _publishTopicController.text,
                                      _messageController.text,
                                    );
                                    _messageController.clear();
                                  }
                                }
                              : null,
                          child: const Text('发布'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: '消息内容',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      enabled: mqttProvider.isConnected,
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

  Widget _buildConnectionSection(MqttProvider mqttProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '连接设置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            if (!mqttProvider.isConnected)
              ElevatedButton(
                onPressed: () async {
                  await mqttProvider.connect(
                    _brokerController.text,
                    int.parse(_portController.text),
                    clientId: _clientIdController.text,
                    username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
                    password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
                    mqttVersion: _selectedMqttVersion,
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
            const SizedBox(height: 8),
            Text(
              mqttProvider.lastError,
              style: TextStyle(
                color: mqttProvider.lastError.contains('连接中') ? Colors.blue : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeSection(MqttProvider mqttProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '订阅主题',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '已订阅主题',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 8),
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '主题: ${message.topic}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '消息: ${message.message}',
                              style: const TextStyle(fontSize: 14),
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
}