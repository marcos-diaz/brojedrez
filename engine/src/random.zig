const std = @import("std");
const builtin = @import("builtin");
extern fn js_random() u32;

pub fn random() u32 {
    if (builtin.os.tag != .freestanding) {
        return @intCast(@mod(std.time.milliTimestamp(), 0xFFFFFFFF));
    } else {
        return js_random();
    }
}
