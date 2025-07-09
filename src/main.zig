const std = @import("std");
const Board = @import("board.zig").Board;
const BoardMask = @import("boardmask.zig").BoardMask;
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

fn notation_from_pos(
    pos: u6,
) [2]u8 {
    const row = pos / 8;
    const col = pos % 8;
    const letters = "hgfedcba";
    const numbers = "12345678";
    var string = [_]u8{0, 0};
    string[0] = letters[col];
    string[1] = numbers[row];
    return string;
}

pub fn main() !void {
    var board = Board.init();
    try terminal.clear();
    var selected: u6 = 0;
    var has_selected = false;
    var highlight = BoardMask{.mask=0};
    terminal.print_board(&board, &highlight);
    var buffer: [8]u8 = undefined;

    while(true) {
        if (has_selected) {
            std.debug.print("\nSelected: {s}\n", .{notation_from_pos(selected)});
            std.debug.print("Available moves: ", .{});
            for(0..64) |_pos| {
                const pos: u6 = @intCast(63 - _pos);
                if (highlight.has(pos)) {
                    std.debug.print("{s}{s}, ", .{
                        notation_from_pos(selected),
                        notation_from_pos(pos),
                    });
                }
            }
        }

        std.debug.print("\n{s}> {s} ", .{terminal.green, terminal.reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);

        if (std.mem.eql(u8, buffer[0..5], "reset")) {
            board.reset();
        }

        if (input_len == 3) {
            const pos = pos_from_notation(buffer[0], buffer[1]);
            selected = pos;
            has_selected = true;
            highlight = board.get_legal_moves(pos);
        }

        if(input_len == 5) {
            const orig = pos_from_notation(buffer[0], buffer[1]);
            const dest = pos_from_notation(buffer[2], buffer[3]);
            const piece = board.get(orig);
            board.remove(orig);
            board.add(dest, piece);
            highlight.reset();
            has_selected = false;
        }
        try terminal.clear();
        terminal.print_board(&board, &highlight);
    }
}
