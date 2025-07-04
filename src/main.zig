const std = @import("std");
const Board = @import("board.zig").Board;
const term = @import("common.zig").term;

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    const board = Board.init();
    try board.displayClear();
    board.display();
    var buffer: [8]u8 = undefined;

    while(true) {
        std.debug.print("{s}> {s} ", .{term.green, term.reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);
        _ = input_len;
        if (buffer[0] == 10) continue;
        std.debug.print("{any}\n", .{buffer});

    }
}
