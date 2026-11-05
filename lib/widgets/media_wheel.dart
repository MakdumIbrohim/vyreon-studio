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
            final radius = (dim - 32) / 2;
            if (radius <= 0) return const SizedBox.shrink();

            return Center(
              child: SizedBox(
                width: dim,
                height: dim,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer decorative circle with radial gradient
                    Container(
                      width: dim - 12,
                      height: dim - 12,
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
                    Positioned(
                      top: 10,
                      child: _buildDialButton(
                        icon: Icons.perm_media_outlined,
                        label: 'Media',
                        color: const Color(0xFF3B82F6),
                        onTap: onOpenMedia,
                      ),
                    ),

                    // Left: LAYER Button
                    Positioned(
                      left: 10,
                      child: _buildDialButton(
                        icon: Icons.layers_outlined,
                        label: 'Layer',
                        color: const Color(0xFFEC4899),
                        onTap: onOpenLayer,
                      ),
                    ),

                    // Right: AUDIO Button
                    Positioned(
                      right: 10,
                      child: _buildDialButton(
                        icon: Icons.audiotrack_outlined,
                        label: 'Audio',
                        color: const Color(0xFF10B981),
                        onTap: onOpenAudio,
                      ),
                    ),

                    // Bottom: RECORD Button
                    Positioned(
                      bottom: 10,
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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying
                              ? AppTheme.primaryVariant
                              : AppTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                          size: 36,
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
        borderRadius: BorderRadius.circular(28),
        splashColor: color.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
