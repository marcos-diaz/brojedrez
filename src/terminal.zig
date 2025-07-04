const std = @import("std");
const Board = @import("board.zig").Board;
const Piece = @import("piece.zig").Piece;

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

pub fn printBoard(
    board: *Board,
) void {
    std.debug.print("\n    A B C D E F G H\n\n", .{});
    for (0..8) |row| {
        std.debug.print("{d}   ", .{8-row});
        for (0..8) |col| {
            const pos: u6 = @intCast((row * 8) + col);
            const piece = board.get(63 - pos);
            switch (piece) {
                Piece.NONE  => std.debug.print("{s}- {s}", .{grey, reset}),
                Piece.PAWN1 => std.debug.print("{s}o {s}", .{blue, reset}),
                Piece.ROOK1 => std.debug.print("{s}+ {s}", .{blue, reset}),
                Piece.KNIG1 => std.debug.print("{s}L {s}", .{blue, reset}),
                Piece.BISH1 => std.debug.print("{s}x {s}", .{blue, reset}),
                Piece.QUEN1 => std.debug.print("{s}Q {s}", .{blue2, reset}),
                Piece.KING1 => std.debug.print("{s}K {s}", .{blue2, reset}),
                Piece.PAWN2 => std.debug.print("{s}o {s}", .{red, reset}),
                Piece.ROOK2 => std.debug.print("{s}+ {s}", .{red, reset}),
                Piece.KNIG2 => std.debug.print("{s}L {s}", .{red, reset}),
                Piece.BISH2 => std.debug.print("{s}x {s}", .{red, reset}),
                Piece.QUEN2 => std.debug.print("{s}Q {s}", .{red2, reset}),
                Piece.KING2 => std.debug.print("{s}K {s}", .{red2, reset}),
            }
        }
        std.debug.print("  {d}", .{8-row});
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
    std.debug.print("    A B C D E F G H\n\n", .{});
}




