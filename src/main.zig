const std = @import("std");
const terminal = @import("terminal.zig");
const all_tests = @import("test/all_tests.zig");

test {
    std.testing.refAllDecls(all_tests);
}

pub fn main() !void {
    try terminal.loop();
}
