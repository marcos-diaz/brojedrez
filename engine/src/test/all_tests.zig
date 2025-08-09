const std = @import("std");

pub const board = @import("board_test.zig");
pub const boardmask = @import("boardmask_test.zig");
pub const pos = @import("pos_test.zig");
pub const tables = @import("tables_test.zig");

// Test all modules imported above.
test {
    std.testing.refAllDecls(@This());
}
