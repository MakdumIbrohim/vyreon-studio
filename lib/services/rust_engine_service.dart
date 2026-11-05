import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'rust/rust_audio_ops.dart';
import 'rust/rust_ffi_bindings.dart';
import 'rust/rust_visual_ops.dart';

class RustEngineService with RustAudioOps, RustVisualOps {
  static final RustEngineService instance = RustEngineService._internal();
  factory RustEngineService() => instance;
  RustEngineService._internal() {
    _initLibrary();
  }

  ffi.DynamicLibrary? _lib;
  VersionDart? _versionFn;
  ParseSrtDart? _parseSrtFn;
  FreeStringDart? _freeStringFn;

  @override
  WaveformDart? waveformFn;
  @override
  BeatPeaksDart? beatFn;
  @override
  AudioDspPcm16Dart? dspPcm16Fn;
  @override
  AudioDspF32Dart? dspF32Fn;
  @override
  LerpTransformDart? lerpFn;
  @override
  ChromaDart? chromaFn;
  @override
  ColorGradeDart? colorGradeFn;
  @override
  ApplyLutDart? applyLutFn;
  @override
  BezierEvalDart? bezierFn;
  @override
  BezierBatchDart? bezierBatchFn;
  @override
  BlendLayersDart? blendLayersFn;

  bool get isAvailable => _lib != null;

  void _initLibrary() {
    _lib = RustFfiBindings.loadLibrary();
    if (_lib != null) {
      try {
        _versionFn = _lib!.lookupFunction<VersionC, VersionDart>('vyreon_rust_version');
        waveformFn = _lib!.lookupFunction<WaveformC, WaveformDart>('vyreon_extract_waveform_peaks');
        beatFn = _lib!.lookupFunction<BeatPeaksC, BeatPeaksDart>('vyreon_detect_beat_peaks');
        lerpFn = _lib!.lookupFunction<LerpTransformC, LerpTransformDart>('vyreon_lerp_transform');
        chromaFn = _lib!.lookupFunction<ChromaC, ChromaDart>('vyreon_chroma_key_alpha');
        colorGradeFn = _lib!.lookupFunction<ColorGradeC, ColorGradeDart>('vyreon_color_grade_rgba');
        applyLutFn = _lib!.lookupFunction<ApplyLutC, ApplyLutDart>('vyreon_apply_lut_3d_rgba');
        dspPcm16Fn = _lib!.lookupFunction<AudioDspPcm16C, AudioDspPcm16Dart>('vyreon_audio_dsp_process_pcm16');
        dspF32Fn = _lib!.lookupFunction<AudioDspF32C, AudioDspF32Dart>('vyreon_audio_dsp_process_f32');
        bezierFn = _lib!.lookupFunction<BezierEvalC, BezierEvalDart>('vyreon_bezier_eval');
        bezierBatchFn = _lib!.lookupFunction<BezierBatchC, BezierBatchDart>('vyreon_speed_curve_eval_batch');
        blendLayersFn = _lib!.lookupFunction<BlendLayersC, BlendLayersDart>('vyreon_blend_layers_rgba');
        _parseSrtFn = _lib!.lookupFunction<ParseSrtC, ParseSrtDart>('vyreon_parse_srt_to_json');
        _freeStringFn = _lib!.lookupFunction<FreeStringC, FreeStringDart>('vyreon_free_string');
      } catch (_) {
        // Partial load fallback
      }
    }
  }

  String get version {
    if (_versionFn == null) return 'Dart VM Fallback Engine';
    try {
      final ptr = _versionFn!();
      return ptr.toDartString();
    } catch (_) {
      return 'Dart VM Fallback Engine';
    }
  }

  /// Fast native SRT Subtitle Parser in Rust
  String? parseSrtToJson(String srtContent) {
    if (_parseSrtFn == null) return null;
    final cStr = srtContent.toNativeUtf8();
    try {
      final resPtr = _parseSrtFn!(cStr);
      if (resPtr == ffi.nullptr) return null;
      try {
        return resPtr.toDartString();
      } finally {
        _freeStringFn?.call(resPtr);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(cStr);
    }
  }
}
