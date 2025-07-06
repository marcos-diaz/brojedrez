const std = @import("std");
const Board = @import("board.zig").Board;
const terminal = @import("terminal.zig");

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

fn pos_from_notation(
    letter: u8,
    number: u8,
) u6 {
    const col: u8 = letter - 97;
    const row: u8 = number - 49;
    return @intCast((row * 8) + (7 - col));
}

pub fn main() !void {
    var board = Board.init();
    try terminal.clear();
    terminal.print_board(&board);
    var buffer: [8]u8 = undefined;

    while(true) {
        std.debug.print("{s}> {s} ", .{terminal.green, terminal.reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);
        // if (buffer[0] == 10) continue;
        // std.debug.print("{any}\n", .{buffer});
        // std.debug.print("{any}\n", .{board.getPieceAtPos(pos)});

        if (input_len == 3) {
            const pos = pos_from_notation(buffer[0], buffer[1]);
            var moves = board.get_legal_moves(pos);
            terminal.print_boardmask(&moves);
        }

        if(input_len == 5) {
            const orig = pos_from_notation(buffer[0], buffer[1]);
            const dest = pos_from_notation(buffer[2], buffer[3]);
            const piece = board.get(orig);
            board.remove(orig);
            board.add(dest, piece);
            try terminal.clear();
            terminal.print_board(&board);
        }
    }
}
