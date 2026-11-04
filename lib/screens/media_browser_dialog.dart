import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../services/media_catalog_service.dart';
import '../theme/app_theme.dart';
import '../widgets/media_browser/media_catalog_tabs.dart';

class MediaBrowserDialog extends StatefulWidget {
  final bool isPrimaryMode;

  const MediaBrowserDialog({super.key, required this.isPrimaryMode});

  @override
  State<MediaBrowserDialog> createState() => _MediaBrowserDialogState();
}

class _MediaBrowserDialogState extends State<MediaBrowserDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isPrimaryMode ? 2 : 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectCatalogItem(MediaCatalogItem item) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final clip = TimelineClip(
      id: 'clip_${item.id}_$now',
      name: item.title,
      type: item.type,
      startMs: 0,
      durationMs: item.durationMs,
      sourceDurationMs: item.durationMs,
      colorValue: item.colorValue,
      textContent: item.textContent ?? 'Sample Text',
      isPrimary: widget.isPrimaryMode,
      trackIndex: widget.isPrimaryMode ? 0 : 1,
    );
    Navigator.of(context).pop(clip);
  }

  Future<void> _pickDeviceFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final path = file.path;
      final name = file.name;
      final ext = file.extension?.toLowerCase() ?? '';

      ClipType detectedType = ClipType.video;
      int defaultDuration = 5000;
      int colorVal = 0xFF2196F3;

      if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
        detectedType = ClipType.image;
        defaultDuration = 4500;
        colorVal = 0xFF9C27B0;
      } else if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(ext)) {
        detectedType = ClipType.audio;
        defaultDuration = 10000;
        colorVal = 0xFF009688;
      } else {
        detectedType = ClipType.video;
        defaultDuration = 6000;
        colorVal = 0xFFE91E63;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final clip = TimelineClip(
        id: 'imported_${now}_$name',
        name: name,
        type: detectedType,
        startMs: 0,
        durationMs: defaultDuration,
        sourceDurationMs: defaultDuration,
        assetPath: path,
        colorValue: colorVal,
        isPrimary: widget.isPrimaryMode,
        trackIndex: widget.isPrimaryMode
            ? 0
            : (detectedType == ClipType.audio ? 3 : 1),
      );

      if (mounted) {
        Navigator.of(context).pop(clip);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.cardColor,
              child: Row(
                children: [
                  Icon(
                    widget.isPrimaryMode
                        ? Icons.perm_media
                        : Icons.layers_outlined,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isPrimaryMode
                        ? 'Add Media (Primary Track)'
                        : 'Add Layer (Overlay Track)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _pickDeviceFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.file_upload, size: 16),
                    label: const Text('Device Storage',
                        style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: [
                const Tab(text: 'Solid Colors'),
                const Tab(text: 'Audio Tracks'),
                if (!widget.isPrimaryMode) ...[
                  const Tab(text: 'Text Templates'),
                  const Tab(text: 'Stickers & Badges'),
                ],
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ColorSolidsTab(onSelect: _selectCatalogItem),
                  AudioCatalogTab(onSelect: _selectCatalogItem),
                  if (!widget.isPrimaryMode) ...[
                    TextTemplatesTab(onSelect: _selectCatalogItem),
                    StickersTab(onSelect: _selectCatalogItem),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
