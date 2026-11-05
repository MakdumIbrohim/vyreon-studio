# KILO CODE INSTRUCTIONS & WORKSPACE MEMORY: Vyreon Studio

Kamu adalah asisten pengembang Kilo Code untuk proyek **Vyreon Studio**. Gunakan konteks di bawah ini sebagai memori percakapan dan panduan arsitektur resmi:

## Konteks Proyek
- **Aplikasi**: Vyreon Studio (Video Editor Mobile Profesional berbasis arsitektur KineMaster v8.1.3).
- **Teknologi**: Flutter 3.13+ (Dart), Native Rust Core Engine FFI (`native/rust_engine`), FFmpeg CLI (`ffmpeg n9.0.2`), dan package `record` + `just_audio`.
- **Status Rilis**: Versi v1.0.0 telah dirilis resmi di GitHub Releases (https://github.com/MakdumIbrohim/vyreon-studio/releases/tag/v1.0.0).

## Aturan Pengembangan & Konvensi
1. **Modularitas**: Setiap file kode yang panjangnya melebihi 300 baris wajib dipecah ke sub-modul terisolasi.
2. **State Management**: Gunakan pola Dart Domain Mixin pada `EditorController` (`lib/state/mixins/`). Jangan membuat state management baru yang tidak diperlukan.
3. **Validasi**: Setiap perubahan kode wajib lulus:
   - `flutter analyze` (0 issues).
   - `flutter test` (seluruh test suite passed).
4. **Build & Release**:
   - Skrip rilis otomatis tersedia di `./scripts/publish_release.sh`.
   - Menghasilkan 4 format APK: `arm64-v8a`, `armeabi-v7a`, `x86_64`, dan `universal`.
   - CI/CD GitHub Actions terpasang di `.github/workflows/release.yml`.

## Peta Modul Kunci
- `lib/state/editor_controller.dart`: Controller inti dengan 4 mixin (`editor_playback_mixin`, `editor_history_mixin`, `editor_clip_ops_mixin`, `editor_layer_ops_mixin`).
- `lib/services/rust_engine_service.dart`: Jembatan Dart FFI ke `libvyreon_rust_engine.so`.
- `lib/services/video_render_service.dart` & `lib/services/ffmpeg_graph_builder.dart`: Pipeline rendering FFmpeg multi-layer (overlay, subtitle, drawtext, audio mixer).
- `lib/services/audio_recording_service.dart`: Perekam audio mikrofon live.
- `lib/services/project_package_service.dart`: Ekspor & impor arsip `.vyreon`.
- `lib/widgets/preview_player.dart`: Pratinjau video dengan Loupe Eyedropper & Direct Manipulation.
- `lib/widgets/timeline_view.dart`: Timeline multi-track dengan magnetic snap-to-beat.
