import 'dart:async';
import 'dart:io';

import 'package:ag_battle_zone/features/home/services/config_service.dart';
import 'package:ag_battle_zone/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  final _configService = ConfigService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<Map<String, dynamic>>? _configStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    _configStream = _configService.streamConfig();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _userStream = _firestore.collection('users').doc(uid).snapshots().cast<DocumentSnapshot<Map<String, dynamic>>>();
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  Future<void> _shareToWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    // Prefer whatsapp native scheme if available
    final uriAndroid = Uri.parse('whatsapp://send?text=$encoded');
    final uriWeb = Uri.parse('https://wa.me/?text=$encoded');

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (await canLaunchUrl(uriAndroid)) {
          await launchUrl(uriAndroid);
          return;
        }
      }
    } catch (_) {}

    // Fallback to web
    if (await canLaunchUrl(uriWeb)) {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
    }
  }

  Future<void> _shareGeneric(String message) async {
    final encoded = Uri.encodeComponent(message);
    final mailUri = Uri.parse('mailto:?subject=${Uri.encodeComponent('Join AG Battle Zone')}&body=$encoded');
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
      return;
    }

    final webShare = Uri.parse('https://example.com/share?text=$encoded');
    if (await canLaunchUrl(webShare)) {
      await launchUrl(webShare, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No sharing method available.')));
  }

  Uri _buildReferralRedirectLink(String referralCode) {
    // Constructs a server-side redirect link which should be hosted on your domain.
    // The server endpoint should redirect to app links / store with the ref param preserved.
    return Uri.parse('${AppConstants.dynamicLinkDomain}/r?ref=${Uri.encodeComponent(referralCode)}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              stream: _userStream,
              builder: (context, userSnap) {
                final userData = userSnap.data?.data() ?? {};
                final referralCode = (userData['referral_code'] ?? '').toString();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your referral code', style: TextStyle(fontSize: 14)) ,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              referralCode.isEmpty ? 'Not available yet' : referralCode,
                              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: referralCode.isEmpty ? null : () => _copyToClipboard(referralCode),
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            StreamBuilder<Map<String, dynamic>>(
              stream: _configStream,
              initialData: const {},
              builder: (context, configSnap) {
                final config = configSnap.data ?? {}; 
                final bonus = config['referral_bonus_amount'] ?? 0;
                return Text('Invite friends and earn $bonus coins when they complete first action.', style: theme.textTheme.bodyLarge);
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.whatsapp),
                    label: const Text('Share via WhatsApp'),
                    onPressed: () async {
                      final uid = _auth.currentUser?.uid;
                      final userDoc = await _firestore.collection('users').doc(uid).get();
                      final referralCode = (userDoc.data()?['referral_code'] ?? '').toString();

                      final configSnapshot = await _configService.configDoc.get();
                      final bonus = configSnapshot.data()?['referral_bonus_amount'] ?? 0;

                      final linkToShare = _buildReferralRedirectLink(referralCode).toString();
                      final message = 'Join me on AG Battle Zone! Use my referral code $referralCode to get $bonus coins. Download: $linkToShare';
                      await _shareToWhatsApp(message);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                    onPressed: () async {
                      final uid = _auth.currentUser?.uid;
                      final userDoc = await _firestore.collection('users').doc(uid).get();
                      final referralCode = (userDoc.data()?['referral_code'] ?? '').toString();

                      final configSnapshot = await _configService.configDoc.get();
                      final bonus = configSnapshot.data()?['referral_bonus_amount'] ?? 0;

                      final linkToShare = _buildReferralRedirectLink(referralCode).toString();
                      final message = 'Use my code $referralCode to get $bonus coins on AG Battle Zone! $linkToShare';
                      await _shareGeneric(message);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
                  child: TextButton(
                onPressed: () async {
                  final uid = _auth.currentUser?.uid;
                  final userDoc = await _firestore.collection('users').doc(uid).get();
                  final referralCode = (userDoc.data()?['referral_code'] ?? '').toString();
                    if (referralCode.isNotEmpty) {
                    final linkToCopy = _buildReferralRedirectLink(referralCode).toString();
                    await _copyToClipboard(linkToCopy);
                  }
                },
                child: const Text('Copy App Link'),
              ),
            ),
            const SizedBox(height: 18),
            const Text('How it works', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('1. Share your code with friends.\n2. Friend installs and signs up with your code.\n3. When they complete their first match or action, you get the bonus automatically.'),
          ],
        ),
      ),
    );
  }
}
