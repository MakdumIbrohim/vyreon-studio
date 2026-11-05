import '../models/timeline_clip.dart';

class MediaCatalogItem {
  final String id;
  final String title;
  final ClipType type;
  final int durationMs;
  final int colorValue;
  final String? subtitle;
  final String? textContent;

  const MediaCatalogItem({
    required this.id,
    required this.title,
    required this.type,
    required this.durationMs,
    required this.colorValue,
    this.subtitle,
    this.textContent,
  });
}

class MediaCatalogService {
  static const List<MediaCatalogItem> colorSolids = [
    MediaCatalogItem(
      id: 'color_black',
      title: 'Dark Studio',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFF121214,
      subtitle: 'Pure Black Backdrop',
    ),
    MediaCatalogItem(
      id: 'color_white',
      title: 'Clean White',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFFF5F5F7,
      subtitle: 'Clean High-Key',
    ),
    MediaCatalogItem(
      id: 'color_crimson',
      title: 'Vyreon Red',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFFE53935,
      subtitle: 'Dynamic Red',
    ),
    MediaCatalogItem(
      id: 'color_ocean',
      title: 'Ocean Deep',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFF1565C0,
      subtitle: 'Navy Blue Backdrop',
    ),
    MediaCatalogItem(
      id: 'color_emerald',
      title: 'Emerald Green',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFF2E7D32,
      subtitle: 'Chroma / Green Screen',
    ),
    MediaCatalogItem(
      id: 'color_gold',
      title: 'Amber Gold',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFFFF8F00,
      subtitle: 'Warm Studio Lighting',
    ),
    MediaCatalogItem(
      id: 'color_purple',
      title: 'Cyber Purple',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFF7B1FA2,
      subtitle: 'Neon Aesthetic',
    ),
    MediaCatalogItem(
      id: 'color_slate',
      title: 'Modern Slate',
      type: ClipType.color,
      durationMs: 4000,
      colorValue: 0xFF37474F,
      subtitle: 'Neutral Slate Grey',
    ),
  ];

  static const List<MediaCatalogItem> stockAudio = [
    MediaCatalogItem(
      id: 'audio_upbeat',
      title: 'Electro Pulse',
      type: ClipType.audio,
      durationMs: 15000,
      colorValue: 0xFF00ACC1,
      subtitle: 'Upbeat Synthwave • 120 BPM',
    ),
    MediaCatalogItem(
      id: 'audio_chill',
      title: 'Midnight Breeze',
      type: ClipType.audio,
      durationMs: 20000,
      colorValue: 0xFF5E35B1,
      subtitle: 'Lo-Fi Chill Hop • 85 BPM',
    ),
    MediaCatalogItem(
      id: 'audio_cinematic',
      title: 'Heroic Horizons',
      type: ClipType.audio,
      durationMs: 18000,
      colorValue: 0xFFD81B60,
      subtitle: 'Cinematic Orchestral',
    ),
    MediaCatalogItem(
      id: 'audio_acoustic',
      title: 'Sunlit Acoustic',
      type: ClipType.audio,
      durationMs: 14000,
      colorValue: 0xFFF4511E,
      subtitle: 'Acoustic Guitar Folk',
    ),
  ];

  static const List<MediaCatalogItem> stockTextTemplates = [
    MediaCatalogItem(
      id: 'text_headline',
      title: 'Bold Headline',
      type: ClipType.text,
      durationMs: 3000,
      colorValue: 0xFFFFFFFF,
      textContent: 'YOUR HEADLINE HERE',
      subtitle: 'Bold Centered Title',
    ),
    MediaCatalogItem(
      id: 'text_subtitle',
      title: 'Minimal Subtitle',
      type: ClipType.text,
      durationMs: 4000,
      colorValue: 0xFFFFD54F,
      textContent: 'Captivating story subtitle',
      subtitle: 'Lower Third Style',
    ),
    MediaCatalogItem(
      id: 'text_quote',
      title: 'Callout Quote',
      type: ClipType.text,
      durationMs: 3500,
      colorValue: 0xFF80D8FF,
      textContent: '"Simplicity is the soul of efficiency."',
      subtitle: 'Italic Quote Card',
    ),
  ];

  static const List<MediaCatalogItem> stickers = [
    MediaCatalogItem(
      id: 'sticker_star',
      title: 'Glowing Star',
      type: ClipType.sticker,
      durationMs: 3000,
      colorValue: 0xFFFFD700,
      textContent: '★',
      subtitle: 'Vector Graphic Badge',
    ),
    MediaCatalogItem(
      id: 'sticker_heart',
      title: 'Neon Heart',
      type: ClipType.sticker,
      durationMs: 3000,
      colorValue: 0xFFFF4081,
      textContent: '♥',
      subtitle: 'Social Reaction',
    ),
    MediaCatalogItem(
      id: 'sticker_fire',
      title: 'Trending Flame',
      type: ClipType.sticker,
      durationMs: 3000,
      colorValue: 0xFFFF5722,
      textContent: '🔥',
      subtitle: 'Viral Highlight Badge',
    ),
  ];
}
