const std = @import("std");
const Board = @import("board.zig").Board;
const terminal = @import("terminal.zig");

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    var board = Board.init();
    try terminal.clear();
    terminal.printBoard(&board);
    var buffer: [8]u8 = undefined;

    while(true) {
        std.debug.print("{s}> {s} ", .{terminal.green, terminal.reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);
        _ = input_len;
        // if (buffer[0] == 10) continue;
        // std.debug.print("{any}\n", .{buffer});
        const row: u8 = buffer[1] - 49;
        const col: u8 = buffer[0] - 97;
        const pos: u6 = @intCast((row * 8) + (7 - col));
        // std.debug.print("{any}\n", .{board.getPieceAtPos(pos)});

        board.remove(pos);
        try terminal.clear();
        terminal.printBoard(&board);

    }
}
