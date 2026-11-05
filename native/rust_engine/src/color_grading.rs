use std::slice;

/// Fast in-place RGBA Color Grading (Brightness, Contrast, Saturation, Temperature, Tint)
/// Operates directly on raw RGBA byte slice in native memory.
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_color_grade_rgba(
    pixels_ptr: *mut u8,
    len: usize,
    brightness: f32,
    contrast: f32,
    saturation: f32,
    temperature: f32,
    tint: f32,
) -> i32 {
    if pixels_ptr.is_null() || len < 4 || (len % 4) != 0 {
        return -1;
    }

    let pixels = unsafe { slice::from_raw_parts_mut(pixels_ptr, len) };
    let c_factor = (contrast.clamp(-1.0, 1.0) + 1.0).max(0.0);
    let sat = saturation.clamp(0.0, 3.0);
    let temp = temperature.clamp(-1.0, 1.0);
    let t_tint = tint.clamp(-1.0, 1.0);
    let bright_offset = brightness.clamp(-1.0, 1.0) * 255.0;

    // Precalculate temperature & tint multipliers
    let temp_r = 1.0 + (temp * 0.2);
    let temp_b = 1.0 - (temp * 0.2);
    let tint_g = 1.0 - (t_tint * 0.2);
    let tint_m = 1.0 + (t_tint * 0.1);

    for chunk in pixels.chunks_exact_mut(4) {
        let mut r = chunk[0] as f32;
        let mut g = chunk[1] as f32;
        let mut b = chunk[2] as f32;

        // 1. Brightness
        r += bright_offset;
        g += bright_offset;
        b += bright_offset;

        // 2. Contrast around midpoint 128.0
        r = (r - 128.0) * c_factor + 128.0;
        g = (g - 128.0) * c_factor + 128.0;
        b = (b - 128.0) * c_factor + 128.0;

        // 3. Saturation (Rec.601 Luma)
        let luma = 0.299 * r + 0.587 * g + 0.114 * b;
        r = luma + (r - luma) * sat;
        g = luma + (g - luma) * sat;
        b = luma + (b - luma) * sat;

        // 4. Temperature & Tint
        r = r * temp_r * tint_m;
        g = g * tint_g;
        b = b * temp_b * tint_m;

        chunk[0] = r.clamp(0.0, 255.0) as u8;
        chunk[1] = g.clamp(0.0, 255.0) as u8;
        chunk[2] = b.clamp(0.0, 255.0) as u8;
        // chunk[3] (Alpha) is preserved untouched
    }

    0
}

/// Applies a 3D LUT (Look-Up Table) with trilinear interpolation to raw RGBA buffer
/// lut_table is an array of f32 containing N*N*N*3 floats (R, G, B in 0.0..1.0 range).
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_apply_lut_3d_rgba(
    pixels_ptr: *mut u8,
    len: usize,
    lut_ptr: *const f32,
    lut_size: usize,
    intensity: f32,
) -> i32 {
    if pixels_ptr.is_null() || lut_ptr.is_null() || len < 4 || (len % 4) != 0 || lut_size < 2 {
        return -1;
    }

    let pixels = unsafe { slice::from_raw_parts_mut(pixels_ptr, len) };
    let lut_total_floats = lut_size * lut_size * lut_size * 3;
    let lut = unsafe { slice::from_raw_parts(lut_ptr, lut_total_floats) };
    let blend = intensity.clamp(0.0, 1.0);
    let inv_blend = 1.0 - blend;
    let max_idx = (lut_size - 1) as f32;

    let sample_lut = |r_idx: usize, g_idx: usize, b_idx: usize| -> (f32, f32, f32) {
        let index = (r_idx + g_idx * lut_size + b_idx * lut_size * lut_size) * 3;
        (lut[index], lut[index + 1], lut[index + 2])
    };

    for chunk in pixels.chunks_exact_mut(4) {
        let orig_r = chunk[0] as f32;
        let orig_g = chunk[1] as f32;
        let orig_b = chunk[2] as f32;

        let r_coord = (orig_r / 255.0) * max_idx;
        let g_coord = (orig_g / 255.0) * max_idx;
        let b_coord = (orig_b / 255.0) * max_idx;

        let r0 = (r_coord.floor() as usize).min(lut_size - 1);
        let r1 = (r0 + 1).min(lut_size - 1);
        let g0 = (g_coord.floor() as usize).min(lut_size - 1);
        let g1 = (g0 + 1).min(lut_size - 1);
        let b0 = (b_coord.floor() as usize).min(lut_size - 1);
        let b1 = (b0 + 1).min(lut_size - 1);

        let fr = r_coord - r0 as f32;
        let fg = g_coord - g0 as f32;
        let fb = b_coord - b0 as f32;

        // Trilinear Interpolation of 8 corners
        let c000 = sample_lut(r0, g0, b0);
        let c100 = sample_lut(r1, g0, b0);
        let c010 = sample_lut(r0, g1, b0);
        let c110 = sample_lut(r1, g1, b0);
        let c001 = sample_lut(r0, g0, b1);
        let c101 = sample_lut(r1, g0, b1);
        let c011 = sample_lut(r0, g1, b1);
        let c111 = sample_lut(r1, g1, b1);

        let c00 = (c000.0 * (1.0 - fr) + c100.0 * fr, c000.1 * (1.0 - fr) + c100.1 * fr, c000.2 * (1.0 - fr) + c100.2 * fr);
        let c10 = (c010.0 * (1.0 - fr) + c110.0 * fr, c010.1 * (1.0 - fr) + c110.1 * fr, c010.2 * (1.0 - fr) + c110.2 * fr);
        let c01 = (c001.0 * (1.0 - fr) + c101.0 * fr, c001.1 * (1.0 - fr) + c101.1 * fr, c001.2 * (1.0 - fr) + c101.2 * fr);
        let c11 = (c011.0 * (1.0 - fr) + c111.0 * fr, c011.1 * (1.0 - fr) + c111.1 * fr, c011.2 * (1.0 - fr) + c111.2 * fr);

        let c0 = (c00.0 * (1.0 - fg) + c10.0 * fg, c00.1 * (1.0 - fg) + c10.1 * fg, c00.2 * (1.0 - fg) + c10.2 * fg);
        let c1 = (c01.0 * (1.0 - fg) + c11.0 * fg, c01.1 * (1.0 - fg) + c11.1 * fg, c01.2 * (1.0 - fg) + c11.2 * fg);

        let lut_r = (c0.0 * (1.0 - fb) + c1.0 * fb) * 255.0;
        let lut_g = (c0.1 * (1.0 - fb) + c1.1 * fb) * 255.0;
        let lut_b = (c0.2 * (1.0 - fb) + c1.2 * fb) * 255.0;

        chunk[0] = (orig_r * inv_blend + lut_r * blend).clamp(0.0, 255.0) as u8;
        chunk[1] = (orig_g * inv_blend + lut_g * blend).clamp(0.0, 255.0) as u8;
        chunk[2] = (orig_b * inv_blend + lut_b * blend).clamp(0.0, 255.0) as u8;
    }

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_color_grade_brightness() {
        let mut pixels = vec![100u8, 100u8, 100u8, 255u8];
        let res = vyreon_color_grade_rgba(pixels.as_mut_ptr(), pixels.len(), 0.2, 0.0, 1.0, 0.0, 0.0);
        assert_eq!(res, 0);
        assert!(pixels[0] > 100);
        assert_eq!(pixels[3], 255); // Alpha preserved
    }

    #[test]
    fn test_apply_lut_identity() {
        let mut pixels = vec![128u8, 64u8, 32u8, 255u8];
        // 2x2x2 identity LUT
        let mut identity_lut = vec![0.0f32; 2 * 2 * 2 * 3];
        for b in 0..2 {
            for g in 0..2 {
                for r in 0..2 {
                    let idx = (r + g * 2 + b * 4) * 3;
                    identity_lut[idx] = r as f32;
                    identity_lut[idx + 1] = g as f32;
                    identity_lut[idx + 2] = b as f32;
                }
            }
        }

        let res = vyreon_apply_lut_3d_rgba(pixels.as_mut_ptr(), pixels.len(), identity_lut.as_ptr(), 2, 1.0);
        assert_eq!(res, 0);
        assert_eq!(pixels[0], 128);
        assert_eq!(pixels[1], 64);
        assert_eq!(pixels[2], 32);
    }
}
