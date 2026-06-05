import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onReplayTutorial;

  const SettingsScreen({
    super.key,
    required this.onReset,
    required this.onReplayTutorial,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.replay, color: Color(0xFF0A6375)),
              title: const Text('Replay Tutorial'),
              subtitle: const Text('Show the welcome screens again'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _confirmDialog(
                  context,
                  title: 'Replay Tutorial',
                  content: 'The welcome guide will appear again. Continue?',
                  onConfirm: onReplayTutorial,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title:
                  const Text('Reset App', style: TextStyle(color: Colors.red)),
              subtitle: const Text(
                  'Erase all data and start fresh',
                  style: TextStyle(color: Colors.black54)),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () {
                _confirmDialog(
                  context,
                  title: 'Reset App Data?',
                  content:
                      'This will permanently delete all pantry items, shopping lists, recipes, meal plans, expenses, and settings.',
                  isDestructive: true,
                  onConfirm: onReset,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm == true) onConfirm();
  }
}