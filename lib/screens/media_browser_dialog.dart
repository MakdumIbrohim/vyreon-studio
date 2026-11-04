import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../services/media_catalog_service.dart';
import '../theme/app_theme.dart';

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
        trackIndex: widget.isPrimaryMode ? 0 : (detectedType == ClipType.audio ? 3 : 1),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.file_upload, size: 16),
                    label: const Text('Device Storage', style: TextStyle(fontSize: 12)),
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
                  _buildColorSolidsGrid(),
                  _buildAudioList(),
                  if (!widget.isPrimaryMode) ...[
                    _buildTextTemplatesList(),
                    _buildStickersGrid(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSolidsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: MediaCatalogService.colorSolids.length,
      itemBuilder: (context, index) {
        final item = MediaCatalogService.colorSolids[index];
        return InkWell(
          onTap: () => _selectCatalogItem(item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Color(item.colorValue),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: MediaCatalogService.stockAudio.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppTheme.divider),
      itemBuilder: (context, index) {
        final item = MediaCatalogService.stockAudio[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(item.colorValue).withValues(alpha: 0.2),
            child: Icon(Icons.music_note, color: Color(item.colorValue)),
          ),
          title: Text(item.title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          subtitle: Text(item.subtitle ?? '',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          trailing: ElevatedButton.icon(
            onPressed: () => _selectCatalogItem(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceVariant,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add', style: TextStyle(fontSize: 11)),
          ),
        );
      },
    );
  }

  Widget _buildTextTemplatesList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: MediaCatalogService.stockTextTemplates.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppTheme.divider),
      itemBuilder: (context, index) {
        final item = MediaCatalogService.stockTextTemplates[index];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.title, color: AppTheme.primary),
            ),
          ),
          title: Text(item.title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          subtitle: Text(item.textContent ?? '',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          trailing: ElevatedButton.icon(
            onPressed: () => _selectCatalogItem(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceVariant,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add', style: TextStyle(fontSize: 11)),
          ),
        );
      },
    );
  }

  Widget _buildStickersGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: MediaCatalogService.stickers.length,
      itemBuilder: (context, index) {
        final item = MediaCatalogService.stickers[index];
        return InkWell(
          onTap: () => _selectCatalogItem(item),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.textContent ?? '',
                  style: TextStyle(
                    fontSize: 36,
                    color: Color(item.colorValue),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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
