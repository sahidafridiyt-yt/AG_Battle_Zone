import 'package:ag_battle_zone/features/home/services/config_service.dart';
import 'package:ag_battle_zone/features/home/services/dispute_service.dart';
import 'package:ag_battle_zone/features/home/services/offerwall_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _configService = ConfigService();
  final _disputeService = DisputeService();
  final _offerwallService = OfferwallService();
  final _referralController = TextEditingController();
  final _withdrawalController = TextEditingController();
  final _adsStatusController = TextEditingController();
  final _gameStatusController = TextEditingController();
  final _videoCooldownController = TextEditingController();
  final _maxDailyVideosController = TextEditingController();
  final _notificationController = TextEditingController();
  final _targetMatchIdController = TextEditingController();
  bool _lockdown = false;
  String _activeSdk = 'none';
  bool _configInitialized = false;

  @override
  void initState() {
    super.initState();
    _configService.ensureDefaults();
  }

  @override
  void dispose() {
    _referralController.dispose();
    _withdrawalController.dispose();
    _adsStatusController.dispose();
    _gameStatusController.dispose();
    _videoCooldownController.dispose();
    _maxDailyVideosController.dispose();
    _notificationController.dispose();
    _targetMatchIdController.dispose();
    super.dispose();
  }

  Future<void> _saveGlobalConfig() async {
    final payload = <String, dynamic>{};
    if (_withdrawalController.text.isNotEmpty) {
      payload['min_withdrawal_limit'] = int.tryParse(_withdrawalController.text) ?? 0;
    }
    if (_adsStatusController.text.isNotEmpty) {
      payload['ads_status'] = _adsStatusController.text.toLowerCase() == 'true';
    }
    if (_gameStatusController.text.isNotEmpty) {
      payload['game_status'] = _gameStatusController.text.toLowerCase() == 'true';
    }
    if (_referralController.text.isNotEmpty) {
      payload['referral_bonus_amount'] = int.tryParse(_referralController.text) ?? 5;
    }
    if (_videoCooldownController.text.isNotEmpty) {
      payload['video_cooldown_seconds'] = int.tryParse(_videoCooldownController.text) ?? 30;
    }
    if (_maxDailyVideosController.text.isNotEmpty) {
      payload['max_daily_videos'] = int.tryParse(_maxDailyVideosController.text) ?? 5;
    }
    payload['active_sdk'] = _activeSdk;

    await _configService.updateConfig(payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global config saved.')));
    }
  }

  Future<void> _sendNotification() async {
    final message = _notificationController.text.trim();
    final matchId = _targetMatchIdController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a message first.')));
      return;
    }

    final payload = {
      'message': message,
      'matchId': matchId,
      'sentAt': FieldValue.serverTimestamp(),
      'type': 'admin_notification',
    };
    await FirebaseFirestore.instance.collection('notifications').add(payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification queued.')));
    }
  }

  Future<void> _setLockdown(bool enabled) async {
    await _configService.setLockdown(enabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enabled ? 'Emergency lockdown enabled' : 'Emergency lockdown disabled')),
      );
    }
    setState(() {
      _lockdown = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Control Center')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _configService.streamConfig(),
        initialData: const <String, dynamic>{},
        builder: (context, snapshot) {
          final config = Map<String, dynamic>.from(snapshot.data ?? const <String, dynamic>{});
          if (!_configInitialized) {
            _configInitialized = true;
            _withdrawalController.text = config['min_withdrawal_limit']?.toString() ?? '100';
            _adsStatusController.text = (config['ads_status'] ?? true).toString();
            _gameStatusController.text = (config['game_status'] ?? true).toString();
            _referralController.text = config['referral_bonus_amount']?.toString() ?? '5';
            _videoCooldownController.text = config['video_cooldown_seconds']?.toString() ?? '30';
            _maxDailyVideosController.text = config['max_daily_videos']?.toString() ?? '5';
            _activeSdk = config['active_sdk'] ?? 'none';
            _lockdown = config['lockdown_enabled'] ?? false;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Global Config', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTextField('Min Withdrawal Limit', _withdrawalController),
              const SizedBox(height: 10),
              _buildTextField('Ads Status (true/false)', _adsStatusController),
              const SizedBox(height: 10),
              _buildTextField('Game Status (true/false)', _gameStatusController),
              const SizedBox(height: 10),
              _buildDropdown('Active SDK', ['none', 'AdManager', 'HTML5'], _activeSdk, (value) {
                if (value != null) {
                  setState(() {
                    _activeSdk = value;
                  });
                }
              }),
              const SizedBox(height: 10),
              _buildTextField('Referral Bonus Coins (Per User)', _referralController),
              const SizedBox(height: 10),
              _buildTextField('Video Cooldown (Seconds)', _videoCooldownController),
              const SizedBox(height: 10),
              _buildTextField('Max Daily Videos Per User', _maxDailyVideosController),
              const SizedBox(height: 20),
              FilledButton(onPressed: _saveGlobalConfig, child: const Text('Save Settings')),
              const SizedBox(height: 24),
              const Text('Emergency Lockdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _lockdown ? Colors.green : Colors.red,
                ),
                onPressed: () => _setLockdown(!_lockdown),
                child: Text(_lockdown ? 'Disable Lockdown' : 'Enable Lockdown'),
              ),
              const SizedBox(height: 24),
              const Text('Push Notification Sender', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField('Custom Message', _notificationController),
              const SizedBox(height: 10),
              _buildTextField('Target Match ID', _targetMatchIdController),
              const SizedBox(height: 10),
              FilledButton(onPressed: _sendNotification, child: const Text('Send to All')),
              const SizedBox(height: 24),
              const Text('Pending Disputes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildPendingDisputes(),
              const SizedBox(height: 24),
              const Text('Offerwall & Task Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildOfferwallLogs(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          onChanged: onChanged,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        ),
      ),
    );
  }

  Widget _buildPendingDisputes() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _disputeService.streamPendingDisputes(),
      initialData: null,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Could not load disputes right now.');
        }
        if (!snapshot.hasData) {
          return const Text('Loading disputes...');
        }
        final disputes = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (disputes.isEmpty) {
          return const Text('No pending disputes.');
        }
        return Column(
          children: disputes.map((doc) {
            final data = doc.data();
            return Card(
              child: ListTile(
                title: Text('Match: ${data['matchId'] ?? 'unknown'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reported by: ${data['reportedBy'] ?? 'unknown'}'),
                    Text('Status: ${data['status'] ?? 'pending'}'),
                    Text('Note: ${data['note'] ?? ''}'),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _disputeService.resolveDispute(doc.id, 'cancel');
                      },
                      child: const Text('Cancel Match & Refund'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _disputeService.resolveDispute(doc.id, 'dismiss');
                      },
                      child: const Text('Ignore Report'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOfferwallLogs() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _offerwallService.streamLogs(),
      initialData: null,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Could not load offerwall logs right now.');
        }
        if (!snapshot.hasData) {
          return const Text('Loading offerwall logs...');
        }
        final logs = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (logs.isEmpty) {
          return const Text('No offerwall logs yet.');
        }
        return Column(
          children: logs.map((log) {
            final data = log.data();
            return Card(
              child: ListTile(
                title: Text('${data['userName'] ?? 'Unknown'} — ${data['taskName'] ?? 'No task'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reward: ${data['rewardAmount'] ?? 0}'),
                    Text('Status: ${data['status'] ?? 'unknown'}'),
                    Text('Time: ${data['timestamp']?.toDate() ?? 'N/A'}'),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
