use std::ffi::{CStr, CString};
use std::os::raw::c_char;

fn parse_srt_timestamp(s: &str) -> Option<u32> {
    let clean = s.trim().replace(',', ".");
    let parts: Vec<&str> = clean.split(':').collect();

    match parts.len() {
        3 => {
            let h: f64 = parts[0].trim().parse().ok()?;
            let m: f64 = parts[1].trim().parse().ok()?;
            let sec: f64 = parts[2].trim().parse().ok()?;
            Some(((h * 3600.0 + m * 60.0 + sec) * 1000.0).round() as u32)
        }
        2 => {
            let m: f64 = parts[0].trim().parse().ok()?;
            let sec: f64 = parts[1].trim().parse().ok()?;
            Some(((m * 60.0 + sec) * 1000.0).round() as u32)
        }
        _ => None,
    }
}

/// Fast native SRT subtitle parser in Rust
/// Returns a JSON-formatted string of parsed subtitles
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_parse_srt_to_json(srt_ptr: *const c_char) -> *mut c_char {
    if srt_ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(srt_ptr) };
    let content = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let normalized = content.replace("\r\n", "\n").replace('\r', "\n");
    let blocks = normalized.split("\n\n");

    let mut json_items = Vec::new();
    let mut fallback_idx = 1;

    for block in blocks {
        let lines: Vec<&str> = block
            .lines()
            .map(|l| l.trim())
            .filter(|l| !l.is_empty())
            .collect();

        if lines.len() < 2 {
            continue;
        }

        let mut idx = fallback_idx;
        let mut line_offset = 0;

        if let Ok(parsed_idx) = lines[0].parse::<u32>() {
            idx = parsed_idx;
            line_offset = 1;
        }

        if lines.len() <= line_offset {
            continue;
        }

        let time_line = lines[line_offset];
        let parts: Vec<&str> = time_line.split("-->").collect();
        if parts.len() != 2 {
            continue;
        }

        let start_ms = match parse_srt_timestamp(parts[0]) {
            Some(ms) => ms,
            None => continue,
        };
        let end_ms = match parse_srt_timestamp(parts[1]) {
            Some(ms) => ms,
            None => continue,
        };

        let text_lines = &lines[line_offset + 1..];
        let text = text_lines.join("\\n").replace('"', "\\\"");

        json_items.push(format!(
            r#"{{"index":{},"startMs":{},"endMs":{},"text":"{}"}}"#,
            idx, start_ms, end_ms, text
        ));
        fallback_idx = idx + 1;
    }

    let json_output = format!("[{}]", json_items.join(","));
    match CString::new(json_output) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Frees a string allocated by Rust native engine
#[unsafe(no_mangle)]
pub extern "C" fn vyreon_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_srt_timestamp() {
        let ms = parse_srt_timestamp("00:01:23,456").unwrap();
        assert_eq!(ms, 83456);

        let ms2 = parse_srt_timestamp("02:10.500").unwrap();
        assert_eq!(ms2, 130500);
    }

    #[test]
    fn test_parse_srt_to_json() {
        let srt = "1\n00:00:01,000 --> 00:00:03,500\nHello world!\n\n2\n00:00:04,000 --> 00:00:06,000\nLine 1\nLine 2";
        let c_srt = CString::new(srt).unwrap();
        let ptr = vyreon_parse_srt_to_json(c_srt.as_ptr());
        assert!(!ptr.is_null());

        let res_str = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap();
        assert!(res_str.contains("Hello world!"));
        assert!(res_str.contains("\"startMs\":1000"));
        assert!(res_str.contains("\"endMs\":3500"));

        vyreon_free_string(ptr);
    }
}
