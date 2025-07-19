const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;
const Board = @import("board.zig").Board;
const Piece = @import("board.zig").Piece;
const Pos = @import("pos.zig").Pos;

const stdout = std.io.getStdOut().writer();

pub const blue =  "\x1b[94m";
pub const red =   "\x1b[31m";
pub const green = "\x1b[32m";
pub const grey =  "\x1b[90m";

pub const red2 =  "\x1b[38;5;215m";
pub const blue2 = "\x1b[38;5;117m";

pub const reset = "\x1b[0m";
pub const force_clear = "\x1b[3J\x1b[2J\x1b[H";


pub fn clear() !void {
    try stdout.writeAll(force_clear);
}

pub fn print_board(
    board: *Board,
    highlight: *BoardMask,
) void {
    std.debug.print("\n     A  B  C  D  E  F  G  H\n\n", .{});
    for (0..8) |row| {
        std.debug.print("{d}   ", .{8-row});
        for (0..8) |col| {
            const pos = Pos.from_row_col(@intCast(row), @intCast(col)).reverse();
            const piece = board.get(pos);
            const pre: u8 =  if (highlight.has(pos)) '[' else ' ';
            const post: u8 = if (highlight.has(pos)) ']' else ' ';
            switch (piece) {
                Piece.NONE  => std.debug.print("{c}{s}-{s}{c}", .{pre, grey, reset, post}),
                Piece.PAWN1 => std.debug.print("{c}{s}o{s}{c}", .{pre, blue, reset, post}),
                Piece.ROOK1 => std.debug.print("{c}{s}+{s}{c}", .{pre, blue, reset, post}),
                Piece.KNIG1 => std.debug.print("{c}{s}L{s}{c}", .{pre, blue, reset, post}),
                Piece.BISH1 => std.debug.print("{c}{s}x{s}{c}", .{pre, blue, reset, post}),
                Piece.QUEN1 => std.debug.print("{c}{s}Q{s}{c}", .{pre, blue2, reset, post}),
                Piece.KING1 => std.debug.print("{c}{s}K{s}{c}", .{pre, blue2, reset, post}),
                Piece.PAWN2 => std.debug.print("{c}{s}o{s}{c}", .{pre, red, reset, post}),
                Piece.ROOK2 => std.debug.print("{c}{s}+{s}{c}", .{pre, red, reset, post}),
                Piece.KNIG2 => std.debug.print("{c}{s}L{s}{c}", .{pre, red, reset, post}),
                Piece.BISH2 => std.debug.print("{c}{s}x{s}{c}", .{pre, red, reset, post}),
                Piece.QUEN2 => std.debug.print("{c}{s}Q{s}{c}", .{pre, red2, reset, post}),
                Piece.KING2 => std.debug.print("{c}{s}K{s}{c}", .{pre, red2, reset, post}),
            }
        }
        std.debug.print("  {d}", .{8-row});
        std.debug.print("\n", .{});
    }
    std.debug.print("\n     A  B  C  D  E  F  G  H\n\n", .{});
    std.debug.print("Turn: {any}\n", .{board.turn});
}

pub fn print_boardmask(
    boardmask: *BoardMask,
) void {
    for (0..64) |_pos| {
        const pos = Pos.from_int(@intCast(_pos)).reverse();
        if ((63-pos.index) % 8 == 0) std.debug.print("\n", .{});
        const char: u8 = if (boardmask.has(pos)) 'X' else '-';
        std.debug.print("{c} ", .{char});
    }
    std.debug.print("\n", .{});
}

pub fn print_bin(
    number: u8,
) void {
    std.debug.print("{b:0>8}\n", .{number});
}




