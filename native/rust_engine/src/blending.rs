use std::slice;

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BlendMode {
    Normal = 0,
    Multiply = 1,
    Screen = 2,
    Overlay = 3,
    Darken = 4,
    Lighten = 5,
    ColorDodge = 6,
    ColorBurn = 7,
    HardLight = 8,
    SoftLight = 9,
    Difference = 10,
    Exclusion = 11,
}

impl BlendMode {
    pub fn from_i32(val: i32) -> Self {
        match val {
            1 => BlendMode::Multiply,
            2 => BlendMode::Screen,
            3 => BlendMode::Overlay,
            4 => BlendMode::Darken,
            5 => BlendMode::Lighten,
            6 => BlendMode::ColorDodge,
            7 => BlendMode::ColorBurn,
            8 => BlendMode::HardLight,
            9 => BlendMode::SoftLight,
            10 => BlendMode::Difference,
            11 => BlendMode::Exclusion,
            _ => BlendMode::Normal,
        }
    }
}

#[inline(always)]
fn blend_channel(base: f32, top: f32, mode: BlendMode) -> f32 {
    let b = base / 255.0;
    let t = top / 255.0;

    let res = match mode {
        BlendMode::Normal => t,
        BlendMode::Multiply => b * t,
        BlendMode::Screen => 1.0 - (1.0 - b) * (1.0 - t),
        BlendMode::Overlay => {
            if b < 0.5 {
                2.0 * b * t
            } else {
                1.0 - 2.0 * (1.0 - b) * (1.0 - t)
            }
        }
        BlendMode::Darken => b.min(t),
        BlendMode::Lighten => b.max(t),
        BlendMode::ColorDodge => {
            if t >= 1.0 {
                1.0
            } else {
                (b / (1.0 - t)).min(1.0)
            }
        }
        BlendMode::ColorBurn => {
            if t <= 0.0 {
                0.0
            } else {
                1.0 - ((1.0 - b) / t).min(1.0)
            }
        }
        BlendMode::HardLight => {
            if t < 0.5 {
                2.0 * b * t
            } else {
                1.0 - 2.0 * (1.0 - b) * (1.0 - t)
            }
        }
        BlendMode::SoftLight => {
            if t < 0.5 {
                2.0 * b * t + b * b * (1.0 - 2.0 * t)
            } else {
                (b.sqrt() * (2.0 * t - 1.0)) + (2.0 * b * (1.0 - t))
            }
        }
        BlendMode::Difference => (b - t).abs(),
        BlendMode::Exclusion => b + t - 2.0 * b * t,
    };

    (res * 255.0).clamp(0.0, 255.0)
}

/// Blends foreground RGBA buffer onto destination RGBA buffer in-place
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_blend_layers_rgba(
    dst_ptr: *mut u8,
    src_ptr: *const u8,
    len: usize,
    mode: i32,
    opacity: f32,
) -> i32 {
    if dst_ptr.is_null() || src_ptr.is_null() || len < 4 || (len % 4) != 0 {
        return -1;
    }

    let dst = unsafe { slice::from_raw_parts_mut(dst_ptr, len) };
    let src = unsafe { slice::from_raw_parts(src_ptr, len) };
    let blend_mode = BlendMode::from_i32(mode);
    let alpha_scale = opacity.clamp(0.0, 1.0);

    for (d_chunk, s_chunk) in dst.chunks_exact_mut(4).zip(src.chunks_exact(4)) {
        let src_a = ((s_chunk[3] as f32) / 255.0) * alpha_scale;
        if src_a <= 0.0 {
            continue;
        }

        let inv_a = 1.0 - src_a;
        let blended_r = blend_channel(d_chunk[0] as f32, s_chunk[0] as f32, blend_mode);
        let blended_g = blend_channel(d_chunk[1] as f32, s_chunk[1] as f32, blend_mode);
        let blended_b = blend_channel(d_chunk[2] as f32, s_chunk[2] as f32, blend_mode);

        d_chunk[0] = ((d_chunk[0] as f32) * inv_a + blended_r * src_a).clamp(0.0, 255.0) as u8;
        d_chunk[1] = ((d_chunk[1] as f32) * inv_a + blended_g * src_a).clamp(0.0, 255.0) as u8;
        d_chunk[2] = ((d_chunk[2] as f32) * inv_a + blended_b * src_a).clamp(0.0, 255.0) as u8;

        // Composite destination alpha: A_out = A_dst + A_src*(1 - A_dst)
        let dst_a = (d_chunk[3] as f32) / 255.0;
        let out_a = dst_a + src_a * (1.0 - dst_a);
        d_chunk[3] = (out_a * 255.0).clamp(0.0, 255.0) as u8;
    }

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_blend_normal() {
        let mut dst = vec![100u8, 100u8, 100u8, 255u8];
        let src = vec![200u8, 50u8, 10u8, 255u8];
        let res = vyreon_blend_layers_rgba(dst.as_mut_ptr(), src.as_ptr(), dst.len(), 0, 1.0);
        assert_eq!(res, 0);
        assert_eq!(dst[0], 200);
        assert_eq!(dst[1], 50);
        assert_eq!(dst[2], 10);
    }

    #[test]
    fn test_blend_multiply() {
        let mut dst = vec![128u8, 128u8, 128u8, 255u8];
        let src = vec![128u8, 128u8, 128u8, 255u8];
        // Multiply: ~0.5 * 0.5 = 0.25 -> ~64
        let res = vyreon_blend_layers_rgba(dst.as_mut_ptr(), src.as_ptr(), dst.len(), 1, 1.0);
        assert_eq!(res, 0);
        assert!((dst[0] as i32 - 64).abs() <= 2);
    }

    #[test]
    fn test_blend_screen() {
        let mut dst = vec![128u8, 128u8, 128u8, 255u8];
        let src = vec![128u8, 128u8, 128u8, 255u8];
        // Screen: 1 - 0.5*0.5 = 0.75 -> ~191
        let res = vyreon_blend_layers_rgba(dst.as_mut_ptr(), src.as_ptr(), dst.len(), 2, 1.0);
        assert_eq!(res, 0);
        assert!((dst[0] as i32 - 191).abs() <= 2);
    }

    #[test]
    fn test_blend_opacity() {
        let mut dst = vec![100u8, 100u8, 100u8, 255u8];
        let src = vec![200u8, 200u8, 200u8, 255u8];
        // 50% opacity normal blend -> halfway between 100 and 200 = 150
        let res = vyreon_blend_layers_rgba(dst.as_mut_ptr(), src.as_ptr(), dst.len(), 0, 0.5);
        assert_eq!(res, 0);
        assert_eq!(dst[0], 150);
    }
}
