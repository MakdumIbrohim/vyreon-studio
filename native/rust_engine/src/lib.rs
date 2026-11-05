pub mod color_grading;
pub mod audio_dsp;
pub mod bezier;
pub mod blending;
pub mod srt_parser;

pub use color_grading::*;
pub use audio_dsp::*;
pub use bezier::*;
pub use blending::*;
pub use srt_parser::*;

use std::os::raw::c_char;
use std::slice;

/// Engine version tag
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_rust_version() -> *const c_char {
    c"VyreonStudio-RustCore-v1.0.1".as_ptr()
}

/// High-performance audio waveform peak extraction in Rust
/// Reads decimation chunks across byte buffer and calculates normalized RMS peaks
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_extract_waveform_peaks(
    data_ptr: *const u8,
    data_len: usize,
    target_samples: usize,
    out_ptr: *mut f32,
) -> i32 {
    if data_ptr.is_null() || out_ptr.is_null() || data_len == 0 || target_samples == 0 {
        return -1;
    }

    let bytes = unsafe { slice::from_raw_parts(data_ptr, data_len) };
    let out = unsafe { slice::from_raw_parts_mut(out_ptr, target_samples) };

    let step = (data_len / target_samples).max(1);
    let mut max_val: f32 = 0.05;

    for (i, slot) in out.iter_mut().enumerate().take(target_samples) {
        let start = i * step;
        let end = (start + 64).min(data_len);
        if start >= end {
            *slot = 0.1;
            continue;
        }

        let chunk = &bytes[start..end];
        let mut sum_diff: f32 = 0.0;
        for &b in chunk {
            let diff = ((b as f32) - 128.0).abs();
            sum_diff += diff;
        }

        let avg = (sum_diff / ((chunk.len() as f32) * 128.0)).clamp(0.05, 1.0);
        if avg > max_val {
            max_val = avg;
        }
        *slot = avg;
    }

    // Normalize peaks so maximum is ~0.95
    for slot in out.iter_mut().take(target_samples) {
        *slot = ((*slot / max_val) * 0.95).clamp(0.08, 1.0);
    }

    0
}

/// Audio Beat / Transient Peak Detection in Rust
/// Analyzes waveform peak samples and detects rhythmic pulse beats (spectral flux / energy transients).
/// Writes detected beat timestamps in milliseconds into out_ms buffer (up to max_beats).
/// Returns the actual count of beats detected.
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_detect_beat_peaks(
    peaks_ptr: *const f32,
    peaks_len: usize,
    duration_ms: u32,
    threshold_multiplier: f32,
    out_ms_ptr: *mut u32,
    max_beats: usize,
) -> i32 {
    if peaks_ptr.is_null() || out_ms_ptr.is_null() || peaks_len < 4 || duration_ms == 0 || max_beats == 0 {
        return 0;
    }

    let peaks = unsafe { slice::from_raw_parts(peaks_ptr, peaks_len) };
    let out_ms = unsafe { slice::from_raw_parts_mut(out_ms_ptr, max_beats) };

    let sum: f32 = peaks.iter().sum();
    let mean = sum / (peaks.len() as f32);
    let mult = threshold_multiplier.clamp(1.05, 2.5);
    let threshold = mean * mult;

    let mut beat_count = 0;
    let min_distance_samples = (peaks_len / 40).max(2);
    let mut last_beat_idx: isize = -100;

    for i in 1..(peaks.len() - 1) {
        if beat_count >= max_beats {
            break;
        }

        let curr = peaks[i];
        let prev = peaks[i - 1];
        let next = peaks[i + 1];

        if curr > threshold && curr >= prev && curr >= next {
            if (i as isize - last_beat_idx) >= (min_distance_samples as isize) {
                let time_ms = ((i as f64 / peaks.len() as f64) * duration_ms as f64).round() as u32;
                out_ms[beat_count] = time_ms;
                beat_count += 1;
                last_beat_idx = i as isize;
            }
        }
    }

    beat_count as i32
}

/// Fast Keyframe & Ken Burns Transform Interpolation (SIMD-friendly lerp)
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_lerp_transform(
    t: f32,
    start_scale: f32,
    end_scale: f32,
    start_x: f32,
    end_x: f32,
    start_y: f32,
    end_y: f32,
    out_scale: *mut f32,
    out_x: *mut f32,
    out_y: *mut f32,
) {
    let progress = t.clamp(0.0, 1.0);
    unsafe {
        if !out_scale.is_null() {
            *out_scale = start_scale + (end_scale - start_scale) * progress;
        }
        if !out_x.is_null() {
            *out_x = start_x + (end_x - start_x) * progress;
        }
        if !out_y.is_null() {
            *out_y = start_y + (end_y - start_y) * progress;
        }
    }
}

/// Chroma Key Mask Calculation for single RGBA pixel
/// Returns calculated Alpha channel (0 = transparent mask, 255 = keep)
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_chroma_key_alpha(
    r: u8,
    g: u8,
    b: u8,
    key_r: u8,
    key_g: u8,
    key_b: u8,
    threshold: f32,
    smoothness: f32,
) -> u8 {
    let dr = (r as f32 - key_r as f32) / 255.0;
    let dg = (g as f32 - key_g as f32) / 255.0;
    let db = (b as f32 - key_b as f32) / 255.0;

    let dist = (dr * dr * 0.299 + dg * dg * 0.587 + db * db * 0.114).sqrt();

    let t = threshold.clamp(0.05, 0.95);
    let s = smoothness.clamp(0.01, 0.5);

    if dist < t {
        0
    } else if dist < (t + s) {
        let factor = (dist - t) / s;
        ((factor.clamp(0.0, 1.0)) * 255.0) as u8
    } else {
        255
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CStr;

    #[test]
    fn test_version() {
        let v = unsafe { CStr::from_ptr(vyreon_rust_version()) };
        assert!(v.to_str().unwrap().contains("VyreonStudio"));
    }

    #[test]
    fn test_lerp() {
        let mut s = 0.0;
        let mut x = 0.0;
        let mut y = 0.0;
        vyreon_lerp_transform(0.5, 1.0, 2.0, 0.0, 10.0, -5.0, 5.0, &mut s, &mut x, &mut y);
        assert!((s - 1.5).abs() < 1e-4);
        assert!((x - 5.0).abs() < 1e-4);
        assert!(y.abs() < 1e-4);
    }

    #[test]
    fn test_chroma() {
        let a = vyreon_chroma_key_alpha(0, 255, 0, 0, 255, 0, 0.35, 0.1);
        assert_eq!(a, 0);

        let a_red = vyreon_chroma_key_alpha(255, 0, 0, 0, 255, 0, 0.35, 0.1);
        assert_eq!(a_red, 255);
    }

    #[test]
    fn test_beat_peaks() {
        let sample_peaks = vec![0.1, 0.2, 0.9, 0.3, 0.1, 0.85, 0.2, 0.1];
        let mut out_beats = vec![0u32; 8];
        let count = vyreon_detect_beat_peaks(
            sample_peaks.as_ptr(),
            sample_peaks.len(),
            8000,
            1.2,
            out_beats.as_mut_ptr(),
            out_beats.len(),
        );
        assert!(count >= 1);
        assert!(out_beats[0] > 0);
    }
}
