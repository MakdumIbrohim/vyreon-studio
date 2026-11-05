import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';

class DirectManipulationOverlay extends StatelessWidget {
  final EditorController controller;
  final TimelineClip layer;
  final int playheadMs;

  const DirectManipulationOverlay({
    super.key,
    required this.controller,
    required this.layer,
    required this.playheadMs,
  });

  @override
  Widget build(BuildContext context) {
    final transform = layer.getInterpolatedTransform(playheadMs);

    return LayoutBuilder(
      builder: (context, constraints) {
        final vpW = constraints.maxWidth;
        final vpH = constraints.maxHeight;

        double boxW = 160.0;
        double boxH = 110.0;
        if (layer.type == ClipType.text) {
          boxW = 200.0;
          boxH = 60.0;
        }

        return Positioned.fill(
          child: Align(
            alignment: Alignment(transform.offsetX, transform.offsetY),
            child: Transform.rotate(
              angle: transform.rotation * (pi / 180),
              child: Transform.scale(
                scale: transform.scale,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    final dx = details.delta.dx / (vpW / 2);
                    final dy = details.delta.dy / (vpH / 2);
                    final updated = layer.copyWith(
                      offsetX: (layer.offsetX + dx).clamp(-1.5, 1.5),
                      offsetY: (layer.offsetY + dy).clamp(-1.5, 1.5),
                    );
                    controller.updateClip(updated);
                  },
                  child: Container(
                    width: boxW,
                    height: boxH,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildCornerHandle(top: -5, left: -5),
                        _buildCornerHandle(top: -5, right: -5),
                        _buildCornerHandle(bottom: -5, left: -5),
                        // Bottom-right scale handle
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              final scaleDelta = details.delta.dx * 0.01;
                              final updated = layer.copyWith(
                                scale:
                                    (layer.scale + scaleDelta).clamp(0.2, 4.0),
                              );
                              controller.updateClip(updated);
                            },
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.open_in_full,
                                  size: 9, color: Colors.black),
                            ),
                          ),
                        ),
                        // Top rotate handle
                        Positioned(
                          top: -24,
                          left: (boxW / 2) - 8,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              final rotDelta = details.delta.dx * 1.5;
                              final updated = layer.copyWith(
                                rotation: (layer.rotation + rotDelta) % 360,
                              );
                              controller.updateClip(updated);
                            },
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.rotate_right,
                                  size: 10, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700),
          border: Border.all(color: Colors.black, width: 1),
        ),
      ),
    );
  }
}
