use std::sync::atomic::{AtomicU8, Ordering};
static VERB: AtomicU8 = AtomicU8::new(0);

pub fn init_logging(verbosity: u8) {
    VERB.store(verbosity, Ordering::SeqCst);
}

pub fn info(msg: &str) {
    // Info-level messages are always printed; use `debug` (verbosity>=1) for extra output.
    println!("[INFO] {}", msg);
}

// Provide debug logging only when verbosity >= 1. Keep function but guard its body
// so it's used when callers call it; if still unused later we can remove it.
pub fn debug(msg: &str) {
    if VERB.load(Ordering::SeqCst) >= 1 {
        println!("[DEBUG] {}", msg);
    }
}
