import 'dart:math';
import 'package:flutter/material.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';

class MediaWheel extends StatelessWidget {
  final EditorController controller;
  final VoidCallback onOpenMedia;
  final VoidCallback onOpenLayer;
  final VoidCallback onOpenAudio;
  final VoidCallback onOpenRecord;

  const MediaWheel({
    super.key,
    required this.controller,
    required this.onOpenMedia,
    required this.onOpenLayer,
    required this.onOpenAudio,
    required this.onOpenRecord,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isPlaying = controller.isPlaying;

        return LayoutBuilder(
          builder: (context, constraints) {
            final dim = min(constraints.maxWidth, constraints.maxHeight);
            if (dim <= 80) return const SizedBox.shrink();

            final centerBtnSize = (dim * 0.25).clamp(42.0, 52.0);
            final dialRadius = (dim / 2) * 0.62;

            return Center(
              child: SizedBox(
                width: dim,
                height: dim,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer decorative circle with radial gradient
                    Container(
                      width: dim - 10,
                      height: dim - 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF16171E),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                    ),

                    // Top: MEDIA Button
                    Transform.translate(
                      offset: Offset(0, -dialRadius),
                      child: _buildDialButton(
                        icon: Icons.perm_media_outlined,
                        label: 'Media',
                        color: const Color(0xFF3B82F6),
                        onTap: onOpenMedia,
                      ),
                    ),

                    // Left: LAYER Button
                    Transform.translate(
                      offset: Offset(-dialRadius, 0),
                      child: _buildDialButton(
                        icon: Icons.layers_outlined,
                        label: 'Layer',
                        color: const Color(0xFFEC4899),
                        onTap: onOpenLayer,
                      ),
                    ),

                    // Right: AUDIO Button
                    Transform.translate(
                      offset: Offset(dialRadius, 0),
                      child: _buildDialButton(
                        icon: Icons.audiotrack_outlined,
                        label: 'Audio',
                        color: const Color(0xFF10B981),
                        onTap: onOpenAudio,
                      ),
                    ),

                    // Bottom: RECORD Button
                    Transform.translate(
                      offset: Offset(0, dialRadius),
                      child: _buildDialButton(
                        icon: Icons.mic_none_outlined,
                        label: 'Record',
                        color: const Color(0xFFF59E0B),
                        onTap: onOpenRecord,
                      ),
                    ),

                    // Center PLAY / PAUSE Button
                    GestureDetector(
                      onTap: controller.togglePlay,
                      child: Container(
                        width: centerBtnSize,
                        height: centerBtnSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying
                              ? AppTheme.primaryVariant
                              : AppTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                          size: centerBtnSize * 0.58,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
