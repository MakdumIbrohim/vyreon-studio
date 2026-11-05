# KILO CODE MEMORY: Vyreon Studio

Dokumen ini merupakan ringkasan memori percakapan, arsitektur, dan riwayat pengembangan Vyreon Studio v1.0.0 untuk asisten Kilo Code.

---

## 📌 Ringkasan Proyek
- **Nama Proyek**: Vyreon Studio (`vyreon_studio`)
- **Tipe**: Aplikasi penyunting video mobile profesional (Flutter + Dart + Native Rust Core Engine + FFmpeg).
- **Target Platform**: Android (ARM64, ARMv7, x86_64, Universal) & Linux Desktop (ELF x64).
- **Branch Aktif**: `dev` (Upstream: `origin/dev`, Main: `origin/main`).
- **Versi Rilis**: `v1.0.0` (Tag GitHub: `https://github.com/MakdumIbrohim/vyreon-studio/releases/tag/v1.0.0`).

---

## 🏛️ Arsitektur & Struktur Codebase

### 1. State Management (Modular Mixins)
State controller inti berlokasi di `lib/state/editor_controller.dart` (83 baris) yang mewarisi `ChangeNotifier` dan 4 modul domain mixin di `lib/state/mixins/`:
- **`editor_playback_mixin.dart`**: Timer playhead 30fps, play/pause, seek dengan *magnetic snap-to-beat* radius 90ms, autoscroll timeline scale.
- **`editor_history_mixin.dart`**: Stack 30-level undo/redo (`undo()`, `redo()`), master settings update, dan auto-save triggers.
- **`editor_clip_ops_mixin.dart`**: Operasi penambahan klip primer/sekunder, split at playhead, trim kiri/kanan, freeze frame, live voiceover, reverse video, audio extraction, dan beat detection.
- **`editor_layer_ops_mixin.dart`**: Pengurutan Z-index layer sekunder (`bringToFront`, `sendToBack`, `reorderSecondaryClips`), dan PiP split screen presets.

### 2. Native Rust Core Engine (FFI)
- Direktori crate: `native/rust_engine/` (`Cargo.toml`, `src/lib.rs`).
- Biner ELF terkompilasi: `native/rust_engine/target/release/libvyreon_rust_engine.so`.
- Jembatan Dart FFI: `lib/services/rust_engine_service.dart`.
- Fungsi yang diakselerasi Rust:
  1. `vyreon_extract_waveform_peaks`: RMS byte decimation & peak normalization gelombang suara.
  2. `vyreon_detect_beat_peaks`: Deteksi transient puncak ritme / ketukan musik untuk auto-marker timeline.
  3. `vyreon_lerp_transform`: Interpolasi SIMD transformasi linier Keyframe & Ken Burns.
  4. `vyreon_chroma_key_alpha`: Kalkulasi jarak Euclidean RGB untuk masking green screen.

### 3. Rendering & Multi-Layer Export (FFmpeg)
- **`lib/services/ffmpeg_graph_builder.dart`**: Membangun grafik *filter_complex* FFmpeg lengkap:
  - Trek primer: Concat video/gambar dengan letterboxing adaptif.
  - Layer sekunder: Overlay transformasi posisi X/Y, skala, rotasi, opasitas, dan *colorkey* chroma key.
  - Tipografi: Burn-in teks via `drawtext` (font size, outline border, dan *background box*).
  - Subtitle: Burn-in file `.srt` via libass filter `subtitles`.
  - Audio: Multi-track mixing (`amix`), sinkronisasi `adelay`, master volume, *fade-in*, dan *fade-out*.
- **`lib/services/video_render_service.dart`**: Mengeksekusi proses FFmpeg CLI, menghitung progres render secara berkala, dan menyimpan berkas MP4 ke direktori custom (`project.settings.customExportDirectory`) atau default (`~/Videos/VyreonStudio`).

### 4. Audio Suite
- **`lib/services/audio_playback_service.dart`**: Sinkronisasi pemutaran audio real-time via `just_audio`.
- **`lib/services/audio_recording_service.dart`**: Perekaman mikrofon live ke format AAC/M4A via package `record`.
- **`lib/widgets/editor/voiceover_modal_sheet.dart`**: UI perekaman suara dengan VU level meter dan auto-insert ke playhead.
- **`lib/widgets/editor/audio_master_mixer_modal_sheet.dart`**: Master mixer, mute global, fade in/out sliders.
- **`lib/services/audio_waveform_service.dart`**: Generator sampel waveform audio.

### 5. UI & Responsivitas
- **`lib/widgets/media_wheel.dart`**: Dial roda kontrol 4-arah KineMaster.
- **`lib/widgets/preview_player.dart`**: Layar pratinjau dengan `RepaintBoundary`, `DirectManipulationOverlay`, dan `EyedropperOverlay` (sampling piksel warna langsung dari frame).
- **`lib/widgets/timeline_view.dart`**: Canvas timeline 2D dengan zoom toolbar, time ruler, primary track, secondary layers, text track, dan audio track.
- **`lib/utils/responsive.dart`**: Breakpoint layout adaptif (Mobile Portrait, Mobile Landscape, Tablet, Desktop).

### 6. Project Packaging & Custom Export
- **`lib/services/project_package_service.dart`**: Ekspor & impor paket `.vyreon` (arsip ZIP berisi `project.json`, `manifest.json`, dan aset media lokal).
- Penyimpanan lokal: `~/.vyreon_studio/projects.json`.

---

## 🚀 Prosedur Build & Rilis
- Jalankan analisis: `flutter analyze` (harus 0 issues).
- Jalankan test: `flutter test` (3/3 test suite).
- Build APK Release per-arsitektur dan universal:
  ```bash
  ./scripts/publish_release.sh
  ```
  Menghasilkan 4 berkas:
  - `vyreon-studio-arm64-v8a-v1.0.0.apk`
  - `vyreon-studio-armeabi-v7a-v1.0.0.apk`
  - `vyreon-studio-x86_64-v1.0.0.apk`
  - `vyreon-studio-universal-v1.0.0.apk`
- Publikasi GitHub Releases: Menggunakan GitHub CLI (`gh release create`).
