import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../services/video_thumbnail_service.dart';
import 'preview_placeholders.dart';

class LayerContentBuilder {
  static Widget build({
    required TimelineClip layer,
    required int playheadMs,
  }) {
    if (layer.type == ClipType.text) {
      return _buildTextContent(layer);
    } else if (layer.type == ClipType.sticker) {
      return _buildStickerContent(layer);
    } else {
      return _buildMediaContent(layer, playheadMs);
    }
  }

  static Widget _buildTextContent(TimelineClip layer) {
    final shadows = <Shadow>[];
    if (layer.isTextShadowEnabled) {
      shadows.add(
        Shadow(
          color: Color(layer.textShadowColor),
          blurRadius: layer.textShadowBlur,
          offset: const Offset(2, 2),
        ),
      );
    }
    if (layer.isTextGlowEnabled) {
      shadows.add(
        Shadow(
          color: Color(layer.textGlowColor),
          blurRadius: layer.textGlowRadius,
        ),
      );
    }
    if (shadows.isEmpty) {
      shadows.add(
        Shadow(
          color: Colors.black.withValues(alpha: 0.8),
          blurRadius: 8,
          offset: const Offset(2, 2),
        ),
      );
    }

    TextAlign align = TextAlign.center;
    if (layer.textAlign == 'left') align = TextAlign.left;
    if (layer.textAlign == 'right') align = TextAlign.right;

    final textMain = Text(
      layer.textContent,
      textAlign: align,
      style: TextStyle(
        color: layer.color,
        fontSize: layer.fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: layer.letterSpacing,
        height: layer.lineSpacing,
        shadows: shadows,
      ),
    );

    Widget resultWidget;
    if (layer.isTextOutlineEnabled) {
      resultWidget = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            layer.textContent,
            textAlign: align,
            style: TextStyle(
              fontSize: layer.fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: layer.letterSpacing,
              height: layer.lineSpacing,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = layer.textOutlineWidth
                ..color = Color(layer.textOutlineColor),
            ),
          ),
          textMain,
        ],
      );
    } else {
      resultWidget = textMain;
    }

    if (layer.isTextBackgroundEnabled) {
      resultWidget = Container(
        padding: EdgeInsets.all(layer.textBackgroundPadding),
        decoration: BoxDecoration(
          color: Color(layer.textBackgroundColor),
          borderRadius:
              BorderRadius.circular(layer.textBackgroundCornerRadius),
        ),
        child: resultWidget,
      );
    }

    return resultWidget;
  }

  static Widget _buildStickerContent(TimelineClip layer) {
    return Text(
      layer.textContent,
      style: TextStyle(
        fontSize: layer.fontSize * 1.5,
        color: layer.color,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  static Widget _buildMediaContent(TimelineClip layer, int playheadMs) {
    final file = layer.assetPath != null ? File(layer.assetPath!) : null;

    if (file != null && file.existsSync()) {
      if (layer.type == ClipType.image) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              PreviewPlaceholders.buildLayerPlaceholder(layer),
        );
      } else if (layer.type == ClipType.video) {
        final relMs = (playheadMs - layer.startMs).clamp(0, layer.durationMs);
        return FutureBuilder<File?>(
          future: VideoThumbnailService()
              .getThumbnailFile(layer.assetPath!, atMs: relMs),
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.existsSync()) {
              return Image.file(
                snapshot.data!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    PreviewPlaceholders.buildLayerPlaceholder(layer),
              );
            }
            return PreviewPlaceholders.buildLayerPlaceholder(layer);
          },
        );
      }
    }
    return PreviewPlaceholders.buildLayerPlaceholder(layer);
  }
}
