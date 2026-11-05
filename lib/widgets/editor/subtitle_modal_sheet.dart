import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/subtitle_entry.dart';
import '../../services/srt_service.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class SubtitleModalSheet extends StatefulWidget {
  final EditorController controller;

  const SubtitleModalSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, EditorController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SubtitleModalSheet(controller: controller),
    );
  }

  @override
  State<SubtitleModalSheet> createState() => _SubtitleModalSheetState();
}

class _SubtitleModalSheetState extends State<SubtitleModalSheet> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addSubtitleAtPlayhead() {
    final playhead = widget.controller.playheadMs;
    final nextIdx = (widget.controller.project.subtitles.isEmpty)
        ? 1
        : widget.controller.project.subtitles.map((s) => s.index).reduce(
                    (a, b) => a > b ? a : b) +
            1;

    final newSub = SubtitleEntry(
      index: nextIdx,
      startMs: playhead,
      endMs: playhead + 3000,
      text: _textController.text.trim().isEmpty
          ? 'New Subtitle'
          : _textController.text.trim(),
    );
    widget.controller.addSubtitle(newSub);
    _textController.clear();
    setState(() {});
  }

  Future<void> _importSrtFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (files.isNotEmpty && files.first.path != null) {
      final file = File(files.first.path!);
      final content = await file.readAsString();
      widget.controller.importSrt(content);
      if (mounted) setState(() {});
    }
  }

  void _exportSrtDialog() {
    final srtString =
        SrtService.exportSrt(widget.controller.project.subtitles);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Exported SRT Content'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: SelectableText(
            srtString.isEmpty ? '(No subtitles in project)' : srtString,
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitles = widget.controller.project.subtitles;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.subtitles, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Subtitles & SRT (${subtitles.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.file_upload,
                      size: 20, color: AppTheme.textSecondary),
                  tooltip: 'Import .SRT',
                  onPressed: _importSrtFile,
                ),
                IconButton(
                  icon: const Icon(Icons.download,
                      size: 20, color: AppTheme.textSecondary),
                  tooltip: 'Export .SRT',
                  onPressed: _exportSrtDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter subtitle text...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addSubtitleAtPlayhead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add at Playhead'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 8),
            Expanded(
              child: subtitles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.subtitles_outlined,
                              size: 40,
                              color: AppTheme.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          const Text(
                            'No subtitles yet.\nAdd manually or import an .SRT file.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: subtitles.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppTheme.divider),
                      itemBuilder: (context, idx) {
                        final sub = subtitles[idx];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(
                            sub.text,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${SrtService.formatTimestamp(sub.startMs)} ➔ ${SrtService.formatTimestamp(sub.endMs)} (${sub.durationMs}ms)',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppTheme.primary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            onPressed: () {
                              widget.controller.deleteSubtitle(sub.index);
                              setState(() {});
                            },
                          ),
                          onTap: () {
                            widget.controller.seekTo(sub.startMs);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
