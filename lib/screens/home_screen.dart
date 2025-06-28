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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0, bottom: 150.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildConnectionSection(),
                    const SizedBox(height: 10),
                    _buildSubscribeSection(),
                    const SizedBox(height: 10),
                    _buildSubscriptionsList(),
                    const SizedBox(height: 10),
                    _buildMessagesSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10.0,
          left: 10.0,
          right: 10.0,
          top: 10.0,
        ),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          // decoration: BoxDecoration(
          //   color: Colors.white,
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.grey.withOpacity(0.3),
          //       spreadRadius: 1,
          //       blurRadius: 5,
          //       offset: const Offset(0, -3),
          //     ),
          //   ],
          // ),
          // padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _publishTopicController,
                decoration: InputDecoration(
                  hintText: '发布主题...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Consumer<MqttProvider>(
                    builder: (context, mqttProvider, child) {
                      return ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Consumer<MqttProvider>(
      builder: (context, mqttProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('连接设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _brokerController,
                  decoration: const InputDecoration(
                    labelText: 'Broker地址',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  enabled: !mqttProvider.isConnected,
                ),
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: '端口',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !mqttProvider.isConnected,
                ),
                TextField(
                  controller: _clientIdController,
                  decoration: const InputDecoration(
                    labelText: '客户端ID',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  enabled: !mqttProvider.isConnected,
                ),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名（可选）',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  enabled: !mqttProvider.isConnected,
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码（可选）',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  obscureText: true,
                  enabled: !mqttProvider.isConnected,
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
                      );
                    },
                    child: const Text('连接'),
                  ),
                if (mqttProvider.lastError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      mqttProvider.lastError,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscribeSection() {
    return Consumer<MqttProvider>(
      builder: (context, mqttProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('订阅主题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _subscribeTopicController,
                  decoration: const InputDecoration(
                    labelText: '主题',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: mqttProvider.isConnected
                      ? () {
                          if (_subscribeTopicController.text.isNotEmpty) {
                            mqttProvider.subscribe(_subscribeTopicController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已订阅主题: ${_subscribeTopicController.text}'),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('订阅'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsList() {
    return Consumer<MqttProvider>(
      builder: (context, mqttProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('订阅列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                mqttProvider.subscribedTopics.isEmpty
                    ? const Text('暂无订阅的主题')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: mqttProvider.subscribedTopics.length,
                        itemBuilder: (context, index) {
                          final topic = mqttProvider.subscribedTopics.elementAt(index);
                          return ListTile(
                            title: Text(topic),
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                mqttProvider.unsubscribe(topic);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已取消订阅主题: $topic'),
                                  ),
                                );
                              },
                            ),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesSection() {
    return Consumer<MqttProvider>(
      builder: (context, mqttProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('消息记录',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: () => mqttProvider.clearMessages(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Scrollbar(
                    thickness: 8.0,
                    radius: const Radius.circular(4.0),
                    child: ListView.builder(
                      itemCount: mqttProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = mqttProvider.messages[index];
                        return ListTile(
                          title: Text(message.topic),
                          subtitle: Text(message.message),
                          dense: true,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}