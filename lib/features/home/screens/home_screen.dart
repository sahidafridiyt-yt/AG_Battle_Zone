import 'dart:io';

import 'package:ag_battle_zone/core/constants/app_constants.dart';
import 'package:ag_battle_zone/features/home/screens/admin_panel_screen.dart';
import 'package:ag_battle_zone/features/home/screens/leaderboard_screen.dart';
import 'package:ag_battle_zone/features/home/screens/settings_help_screen.dart';
import 'package:ag_battle_zone/features/home/screens/refer_screen.dart';
import 'package:ag_battle_zone/features/home/services/config_service.dart';
import 'package:ag_battle_zone/features/home/services/dispute_service.dart';
import 'package:ag_battle_zone/features/home/services/transaction_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key, this.userEmail, this.configStream});

  final String? userEmail;
  final Stream<Map<String, dynamic>>? configStream;
  final _configService = ConfigService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slides = [
      _PromoCard(
        title: 'Weekend Tournament',
        subtitle: 'Join the battle and unlock bonus coins.',
        icon: Icons.emoji_events_rounded,
      ),
      _PromoCard(
        title: 'New Feature',
        subtitle: 'Track reports faster with instant updates.',
        icon: Icons.flash_on_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: configStream ?? _configService.streamConfig(),
        initialData: const <String, dynamic>{},
        builder: (context, configSnapshot) {
          final config = Map<String, dynamic>.from(configSnapshot.data ?? const <String, dynamic>{});
          final lockdownEnabled = config['lockdown_enabled'] ?? false;
          final gameStatus = config['game_status'] ?? true;
          final adsStatus = config['ads_status'] ?? true;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lockdownEnabled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Emergency lockdown is active. Some features may be disabled.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: const Icon(Icons.person_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              AppConstants.appName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _WalletCard(
                          title: 'Total Coins',
                          value: '12,450',
                          icon: Icons.monetization_on_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WalletCard(
                          title: 'Winning Balance',
                          value: '\$3,240',
                          icon: Icons.savings_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 150,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.95,
                    ),
                    items: slides.map((slide) => slide).toList(),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        try {
                          await TransactionService().requestCoinUpdate(
                            type: 'credit',
                            amount: 100,
                            note: 'Onboarding reward',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transaction request created.')),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to create request: $error')),
                            );
                          }
                        }
                      },
                      child: const Text('Send Test Transaction Request'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                        final menuItems = <_MenuItem>[
                        const _MenuItem(title: 'Task Zone', icon: Icons.workspaces_outline),
                        const _MenuItem(title: 'Play to Win', icon: Icons.videogame_asset_rounded),
                        const _MenuItem(title: 'Join FF Match', icon: Icons.group_add_outlined),
                        const _MenuItem(title: 'Watch & Earn', icon: Icons.play_circle_outline_rounded),
                        const _MenuItem(title: 'Withdrawal', icon: Icons.money_outlined),
                        const _MenuItem(title: 'Refer & Earn', icon: Icons.share_rounded),
                        const _MenuItem(title: 'Top Leaderboard', icon: Icons.emoji_events_outlined),
                      ];

                      final isAdmin = _isAdminEmail(userEmail);
                      final items = isAdmin
                          ? [...menuItems, const _MenuItem(title: 'Admin Panel', icon: Icons.admin_panel_settings_rounded)]
                          : menuItems;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.02,
                        children: items.map((item) {
                          return _MenuTile(
                            title: item.title,
                            icon: item.icon,
                            onTap: () {
                              if (item.title == 'Admin Panel') {
                                if (!_isAdminEmail(userEmail)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Admin access required.')),
                                  );
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                                );
                              } else if (item.title == 'Top Leaderboard') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                                );
                              } else if (item.title == 'Refer & Earn') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ReferScreen()),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${item.title} coming soon.')),
                                );
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Match History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsHelpScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.help_outline_rounded),
                        label: const Text('Settings/Help'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MatchCard(
                    title: 'Solo Royale',
                    subtitle: 'Win • 12 mins ago',
                    score: '+250 coins',
                    onReport: () => _showReportDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _MatchCard(
                    title: 'Team Clash',
                    subtitle: 'Lost • 1 hour ago',
                    score: '-120 coins',
                    onReport: () => _showReportDialog(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _ReportCheaterDialog(),
    );
  }

  bool _isAdminEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    return normalized == AppConstants.adminEmail.toLowerCase();
  }
}

class _MenuItem {
  const _MenuItem({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.onReport,
  });

  final String title;
  final String subtitle;
  final String score;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Text(score, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Report Cheater'),
          ),
        ],
      ),
    );
  }
}

class _ReportCheaterDialog extends StatefulWidget {
  const _ReportCheaterDialog();

  @override
  State<_ReportCheaterDialog> createState() => _ReportCheaterDialogState();
}

class _ReportCheaterDialogState extends State<_ReportCheaterDialog> {
  final _idController = TextEditingController();
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _uploadReport() async {
    final hackerId = _idController.text.trim();
    if (hackerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the cheater ID.')));
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a screenshot.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child('reports/${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}');
      final file = File(_selectedImage!.path);
      await storageRef.putFile(file);
      final screenshotUrl = await storageRef.getDownloadURL();
      final currentUser = FirebaseAuth.instance.currentUser;
      await DisputeService().createDispute({
        'reportedBy': currentUser?.uid ?? '',
        'reporterEmail': currentUser?.email ?? '',
        'cheaterId': hackerId,
        'screenshotUrl': screenshotUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'note': 'User report submitted via mobile app.',
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report uploaded successfully.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Cheater'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Cheater ID'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Pick screenshot'),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              Text('Selected: ${_selectedImage!.name}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _isUploading ? null : _uploadReport,
          icon: _isUploading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_rounded),
          label: Text(_isUploading ? 'Uploading...' : 'Submit report'),
        ),
      ],
    );
  }
}
