const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;
const Board = @import("board.zig").Board;
const Piece = @import("board.zig").Piece;
const Pos = @import("pos.zig").Pos;
const Move = @import("pos.zig").Move;

const print = std.debug.print;
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

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

pub fn loop() !void {
    var board = Board.init();
    try clear();
    var selected: Pos = undefined;
    var has_selected = false;
    var highlight = BoardMask{.mask=0};
    print_board(&board, &highlight);
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

        std.debug.print("\n{s}> {s} ", .{green, reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);

        try clear();

        if (std.mem.eql(u8, buffer[0..5], "reset")) {
            board.reset();
            has_selected = false;
            highlight = BoardMask{.mask=0};
        }

        if (std.mem.eql(u8, buffer[0..5], "legal")) {
            const legal = board.get_legal_moves();
            for (0..legal.len) |i| {
                const move = legal.data[i];
                print("{s}, ", .{ move.notation() });
            }
            print("\n", .{});
        }

        if (std.mem.eql(u8, buffer[0..4], "play")) {
            // for (0..1000000) |_| {
            const legal = board.get_legal_moves();
            _ = board.move(legal.data[0]);
            // }
        }

        else if (input_len == 3) {
            const pos = Pos.from_notation(buffer[0], buffer[1]);
            selected = pos;
            has_selected = true;
            highlight = board.get_legal_moves_for_pos(pos);
        }

        else if(input_len == 5) {
            const orig = Pos.from_notation(buffer[0], buffer[1]);
            const dest = Pos.from_notation(buffer[2], buffer[3]);
            const captured = board.move(Move{.orig=orig, .dest=dest});
            if (captured) print("CAPTURED\n", .{});
            highlight.reset();
            has_selected = false;
        }
        print_board(&board, &highlight);
    }
}



