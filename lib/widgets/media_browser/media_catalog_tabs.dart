import 'package:flutter/material.dart';
import '../../services/media_catalog_service.dart';
import '../../theme/app_theme.dart';

class ColorSolidsTab extends StatelessWidget {
  final ValueChanged<MediaCatalogItem> onSelect;

  const ColorSolidsTab({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
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
          onTap: () => onSelect(item),
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
}

class AudioCatalogTab extends StatelessWidget {
  final ValueChanged<MediaCatalogItem> onSelect;

  const AudioCatalogTab({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            item.subtitle ?? '',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          trailing: ElevatedButton.icon(
            onPressed: () => onSelect(item),
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
}

class TextTemplatesTab extends StatelessWidget {
  final ValueChanged<MediaCatalogItem> onSelect;

  const TextTemplatesTab({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            item.textContent ?? '',
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          trailing: ElevatedButton.icon(
            onPressed: () => onSelect(item),
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
}

class StickersTab extends StatelessWidget {
  final ValueChanged<MediaCatalogItem> onSelect;

  const StickersTab({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
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
          onTap: () => onSelect(item),
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
