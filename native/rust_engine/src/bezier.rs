use std::slice;

/// Evaluates a single cubic-bezier easing curve y-value for a given x in [0.0, 1.0]
/// Standard cubic bezier with P0=(0,0), P1=(x1, y1), P2=(x2, y2), P3=(1,1).
/// Uses Newton-Raphson root-finding on x(t) followed by bisection fallback.
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_bezier_eval(
    x: f32,
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
) -> f32 {
    let target_x = x.clamp(0.0, 1.0);
    if target_x <= 0.0 {
        return 0.0;
    }
    if target_x >= 1.0 {
        return 1.0;
    }

    // Bezier polynomial coefficients for x(t) and y(t)
    // x(t) = 3*(1-t)^2 * t * x1 + 3*(1-t) * t^2 * x2 + t^3
    let cx = 3.0 * x1;
    let bx = 3.0 * (x2 - x1) - cx;
    let ax = 1.0 - cx - bx;

    let cy = 3.0 * y1;
    let by = 3.0 * (y2 - y1) - cy;
    let ay = 1.0 - cy - by;

    let sample_x = |t: f32| -> f32 { ((ax * t + bx) * t + cx) * t };
    let sample_dx = |t: f32| -> f32 { (3.0 * ax * t + 2.0 * bx) * t + cx };
    let sample_y = |t: f32| -> f32 { ((ay * t + by) * t + cy) * t };

    // Newton-Raphson iteration
    let mut t = target_x;
    for _ in 0..8 {
        let current_x = sample_x(t) - target_x;
        if current_x.abs() < 1e-5 {
            return sample_y(t);
        }
        let d = sample_dx(t);
        if d.abs() < 1e-6 {
            break;
        }
        t -= current_x / d;
    }

    // Bisection fallback if Newton fails to converge
    let mut t0 = 0.0f32;
    let mut t1 = 1.0f32;
    t = target_x;

    while t0 < t1 {
        let current_x = sample_x(t);
        if (current_x - target_x).abs() < 1e-5 {
            return sample_y(t);
        }
        if target_x > current_x {
            t0 = t;
        } else {
            t1 = t;
        }
        t = (t1 - t0) * 0.5 + t0;
    }

    sample_y(t)
}

/// Batch evaluates cubic bezier speed curve on an array of normalized timestamps
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_speed_curve_eval_batch(
    in_times_ptr: *const f32,
    out_values_ptr: *mut f32,
    count: usize,
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
) -> i32 {
    if in_times_ptr.is_null() || out_values_ptr.is_null() || count == 0 {
        return -1;
    }

    let in_times = unsafe { slice::from_raw_parts(in_times_ptr, count) };
    let out_values = unsafe { slice::from_raw_parts_mut(out_values_ptr, count) };

    for i in 0..count {
        out_values[i] = vyreon_bezier_eval(in_times[i], x1, y1, x2, y2);
    }

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bezier_linear() {
        // Linear curve: (0,0) to (1,1)
        let mid = vyreon_bezier_eval(0.5, 0.0, 0.0, 1.0, 1.0);
        assert!((mid - 0.5).abs() < 1e-3);
    }

    #[test]
    fn test_bezier_ease_in() {
        // Standard ease-in: (0.42, 0.0, 1.0, 1.0)
        let early = vyreon_bezier_eval(0.2, 0.42, 0.0, 1.0, 1.0);
        assert!(early < 0.2); // Ease-in starts slow
    }

    #[test]
    fn test_bezier_batch() {
        let times = vec![0.0f32, 0.5f32, 1.0f32];
        let mut out = vec![0.0f32; 3];
        let res = vyreon_speed_curve_eval_batch(times.as_ptr(), out.as_mut_ptr(), 3, 0.25, 0.1, 0.25, 1.0);
        assert_eq!(res, 0);
        assert_eq!(out[0], 0.0);
        assert_eq!(out[2], 1.0);
        assert!(out[1] > 0.0 && out[1] < 1.0);
    }
}
