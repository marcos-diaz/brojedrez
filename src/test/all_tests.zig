const std = @import("std");

pub const boardmask = @import("boardmask_test.zig");
pub const tables = @import("tables_test.zig");

test {
    std.testing.refAllDecls(@This());
}
