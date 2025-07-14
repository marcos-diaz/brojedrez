const std = @import("std");
const Board = @import("board.zig").Board;
const Pos = @import("pos.zig").Pos;
const BoardMask = @import("boardmask.zig").BoardMask;
const terminal = @import("terminal.zig");

pub const all_tests = @import("test/all_tests.zig");
test {
    std.testing.refAllDecls(all_tests);
}

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    var board = Board.init();
    try terminal.clear();
    var selected: Pos = undefined;
    var has_selected = false;
    var highlight = BoardMask{.mask=0};
    terminal.print_board(&board, &highlight);
    var buffer: [8]u8 = undefined;

    while(true) {
        if (has_selected) {
            std.debug.print("\nSelected: {s}\n", .{selected.notation()});
            std.debug.print("Available moves: ", .{});
            for(0..64) |_pos| {
                const pos = Pos.from_int(@intCast(63 - _pos));
                if (highlight.has(pos)) {
                    std.debug.print("{s}{s}, ", .{
                        selected.notation(),
                        pos.notation(),
                    });
                }
            }
        }

        std.debug.print("\n{s}> {s} ", .{terminal.green, terminal.reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);

        try terminal.clear();

        if (std.mem.eql(u8, buffer[0..5], "reset")) {
            board.reset();
            has_selected = false;
        }

        if (input_len == 3) {
            const pos = Pos.from_notation(buffer[0], buffer[1]);
            selected = pos;
            has_selected = true;
            highlight = board.get_legal_moves(pos);
        }

        if(input_len == 5) {
            const orig = Pos.from_notation(buffer[0], buffer[1]);
            const dest = Pos.from_notation(buffer[2], buffer[3]);
            const piece = board.get(orig);
            board.remove(orig);
            board.remove(dest);
            board.add(dest, piece);
            highlight.reset();
            has_selected = false;
        }
        terminal.print_board(&board, &highlight);
    }
}
