use std::slice;

/// Real-time Audio DSP filter for 16-bit PCM audio
/// In-place processing:
/// - Volume gain multiplier
/// - Noise Gate with threshold (-dB converted to linear amplitude) and smoothing
/// - High-pass rumble filter (single-pole highpass)
/// - Soft limiting / clamp to prevent digital clipping
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_audio_dsp_process_pcm16(
    samples_ptr: *mut i16,
    samples_len: usize,
    volume: f32,
    noise_gate_threshold: f32, // linear amplitude threshold, e.g. 0.02 (approx -34dB)
    enable_highpass: i32,      // 1 to enable 80Hz rumble filter
) -> i32 {
    if samples_ptr.is_null() || samples_len == 0 {
        return -1;
    }

    let samples = unsafe { slice::from_raw_parts_mut(samples_ptr, samples_len) };
    let vol = volume.clamp(0.0, 4.0);
    let gate_thresh = (noise_gate_threshold.clamp(0.0, 0.5) * 32768.0) as f32;

    // Single-pole highpass filter coefficient (approx 80Hz cutoff at 44.1kHz)
    let hp_alpha = 0.988f32;
    let mut prev_in = 0.0f32;
    let mut prev_out = 0.0f32;
    let mut gate_gain = if samples[0].abs() < (gate_thresh as i16) { 0.0f32 } else { 1.0f32 };

    for s in samples.iter_mut() {
        let mut sample_f = *s as f32;

        // 1. High-pass filter
        if enable_highpass != 0 {
            let hp_out = hp_alpha * (prev_out + sample_f - prev_in);
            prev_in = sample_f;
            prev_out = hp_out;
            sample_f = hp_out;
        }

        // 2. Noise Gate with fast attack and smooth release
        let abs_val = sample_f.abs();
        let target_gate = if abs_val < gate_thresh { 0.0f32 } else { 1.0f32 };
        let coeff = if target_gate > gate_gain { 0.35f32 } else { 0.05f32 };
        gate_gain += (target_gate - gate_gain) * coeff;
        sample_f *= gate_gain;

        // 3. Volume Scaling
        sample_f *= vol;

        // 4. Soft Limiter / Clamping
        *s = sample_f.clamp(-32767.0, 32767.0) as i16;
    }

    0
}

/// Float32 audio DSP processing
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_audio_dsp_process_f32(
    samples_ptr: *mut f32,
    samples_len: usize,
    volume: f32,
    noise_gate_threshold: f32,
) -> i32 {
    if samples_ptr.is_null() || samples_len == 0 {
        return -1;
    }

    let samples = unsafe { slice::from_raw_parts_mut(samples_ptr, samples_len) };
    let vol = volume.clamp(0.0, 4.0);
    let gate_thresh = noise_gate_threshold.clamp(0.0, 0.5);
    let mut gate_gain = if samples[0].abs() < gate_thresh { 0.0f32 } else { 1.0f32 };

    for s in samples.iter_mut() {
        let mut sample_f = *s;
        let abs_val = sample_f.abs();
        let target_gate = if abs_val < gate_thresh { 0.0f32 } else { 1.0f32 };
        let coeff = if target_gate > gate_gain { 0.35f32 } else { 0.05f32 };
        gate_gain += (target_gate - gate_gain) * coeff;
        sample_f = sample_f * gate_gain * vol;

        // Soft saturation limiter
        *s = sample_f.tanh();
    }

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pcm16_noise_gate_and_volume() {
        let mut samples = vec![10i16, 20i16, 15i16];
        let res = vyreon_audio_dsp_process_pcm16(
            samples.as_mut_ptr(),
            samples.len(),
            1.5,
            0.05, // 5% of 32768 = ~1638
            0,
        );
        assert_eq!(res, 0);
        // Small values below threshold should be gated down
        assert!(samples[0].abs() < 10);

        // Loud sustained audio
        let mut loud = vec![10000i16; 10];
        let res2 = vyreon_audio_dsp_process_pcm16(loud.as_mut_ptr(), loud.len(), 1.5, 0.05, 0);
        assert_eq!(res2, 0);
        assert!(loud[9] > 14000);
    }

    #[test]
    fn test_f32_dsp() {
        let mut samples = vec![0.001f32; 5];
        let res = vyreon_audio_dsp_process_f32(samples.as_mut_ptr(), samples.len(), 1.0, 0.01);
        assert_eq!(res, 0);
        assert!(samples[4].abs() < 0.001); // Gated

        let mut loud = vec![0.5f32; 10];
        let res2 = vyreon_audio_dsp_process_f32(loud.as_mut_ptr(), loud.len(), 1.2, 0.01);
        assert_eq!(res2, 0);
        assert!(loud[9] > 0.5);
    }
}
