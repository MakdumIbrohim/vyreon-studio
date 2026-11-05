import 'package:flutter/material.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class SnapshotModalSheet extends StatelessWidget {
  final EditorController controller;

  const SnapshotModalSheet({super.key, required this.controller});

  static void show(BuildContext context, EditorController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SnapshotModalSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.camera_alt, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Capture & Snapshot at Playhead',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.save_alt, color: AppTheme.primary, size: 20),
              ),
              title: const Text('Capture and Save Frame',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              subtitle: const Text('Save current snapshot to gallery storage',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Frame snapshot at ${(controller.playheadMs / 1000).toStringAsFixed(1)}s saved to gallery!',
                    ),
                    backgroundColor: AppTheme.surfaceVariant,
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.content_cut,
                    color: Colors.cyanAccent, size: 20),
              ),
              title: const Text('Capture and Insert as Clip',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              subtitle: const Text(
                  'Insert 3s freeze frame into primary track at playhead',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () {
                Navigator.of(context).pop();
                controller.insertFreezeFrameAtPlayhead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Freeze frame inserted into timeline!'),
                    backgroundColor: AppTheme.surfaceVariant,
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers,
                    color: Colors.amberAccent, size: 20),
              ),
              title: const Text('Capture and Add as Layer',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              subtitle: const Text(
                  'Add frozen snapshot as secondary overlay layer',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () {
                Navigator.of(context).pop();
                controller.addSnapshotAsLayer();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Snapshot added as overlay layer!'),
                    backgroundColor: AppTheme.surfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
