const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;
const Board = @import("board.zig").Board;
const Piece = @import("board.zig").Piece;
const Player = @import("board.zig").Player;
const Stats = @import("board.zig").Stats;
const Pos = @import("pos.zig").Pos;
const Move = @import("pos.zig").Move;

const print = std.debug.print;
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub const blue =  "\x1b[94m";
pub const red =   "\x1b[31m";
pub const green = "\x1b[32m";
pub const grey =  "\x1b[90m";
pub const grey2 = "\x1b[38;5;236m";

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
    print("\n     A  B  C  D  E  F  G  H\n\n", .{});
    for (0..8) |row| {
        print("{d}   ", .{8-row});
        for (0..8) |col| {
            const pos = Pos.from_row_col(@intCast(row), @intCast(col)).reverse();
            const piece = board.get(pos);
            const pre: u8 =  if (highlight.has(pos)) '[' else ' ';
            const post: u8 = if (highlight.has(pos)) ']' else ' ';
            switch (piece) {
                Piece.NONE => {
                    const color = if (pos.row() % 2 == pos.col() % 2) grey else grey2;
                    print("{c}{s}-{s}{c}", .{pre, color, reset, post});
                },
                Piece.PAWN1 => print("{c}{s}○{s}{c}", .{pre, blue, reset, post}),
                Piece.PAWN2 => print("{c}{s}○{s}{c}", .{pre, red, reset, post}),
                Piece.ROOK1 => print("{c}{s}■{s}{c}", .{pre, blue, reset, post}),
                Piece.ROOK2 => print("{c}{s}■{s}{c}", .{pre, red, reset, post}),
                Piece.KNIG1 => print("{c}{s}◖{s}{c}", .{pre, blue, reset, post}),
                Piece.KNIG2 => print("{c}{s}◖{s}{c}", .{pre, red, reset, post}),
                Piece.BISH1 => print("{c}{s}▲{s}{c}", .{pre, blue, reset, post}),
                Piece.BISH2 => print("{c}{s}▲{s}{c}", .{pre, red, reset, post}),
                Piece.QUEN1 => print("{c}{s}◆{s}{c}", .{pre, blue2, reset, post}),
                Piece.QUEN2 => print("{c}{s}◆{s}{c}", .{pre, red2, reset, post}),
                Piece.KING1 => print("{c}{s}✖{s}{c}", .{pre, blue2, reset, post}),
                Piece.KING2 => print("{c}{s}✖{s}{c}", .{pre, red2, reset, post}),
            }
        }
        print("  {d}", .{8-row});
        if (8-row > 4 and board.turn == Player.PLAYER2) print("  █", .{});
        if (8-row <= 4 and board.turn == Player.PLAYER1) print("  █", .{});
        print("\n", .{});
    }
    print("\n     A  B  C  D  E  F  G  H\n\n", .{});
}

pub fn print_boardmask(
    boardmask: *BoardMask,
) void {
    for (0..64) |_pos| {
        const pos = Pos.from_int(@intCast(_pos)).reverse();
        if ((63-pos.index) % 8 == 0) print("\n", .{});
        const char: u8 = if (boardmask.has(pos)) 'X' else '-';
        print("{c} ", .{char});
    }
    print("\n", .{});
}

pub fn print_bin(
    number: u8,
) void {
    print("{b:0>8}\n", .{number});
}

pub fn indent(
    spaces: u8,
) void {
    for (0..spaces) |_| {
        print("  ", .{});
    }
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
        print("{s}>{s} ", .{green, reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);

        // try clear();

        if (std.mem.eql(u8, buffer[0..5], "reset")) {
            board.reset();
            has_selected = false;
            highlight = BoardMask{.mask=0};
            try clear();
            print_board(&board, &highlight);
        }

        else if (std.mem.eql(u8, buffer[0..5], "legal")) {
            const legal = board.get_legal_moves(false);
            for (0..legal.len) |i| {
                const move = legal.data[i];
                print("{s}, ", .{ move.notation() });
            }
            print("\n", .{});
        }

        else if (std.mem.eql(u8, buffer[0..4], "king")) {
            const can_capture_king = board.can_capture_king();
            print("can_capture_king={}\n", .{can_capture_king});
        }

        // Autoplay once.
        else if (
            (input_len == 5 and (std.mem.eql(u8, buffer[0..4], "play"))) or
            (input_len == 2 and buffer[0] == 'p')
        ) {
            var stats: Stats = .{0} ** 16;
            const minmax = board.minmax(4, &stats);
            const move = minmax.move orelse unreachable;
            const score = minmax.score;
            _ = board.move(move);
            highlight.reset();
            highlight.add(move.orig);
            highlight.add(move.dest);
            try clear();
            print_board(&board, &highlight);
            print("{s}>{s} play\n", .{green, reset});
            print("evaluated d=1 {d}\n", .{stats[3]});
            print("evaluated d=2 {d}\n", .{stats[2]});
            print("evaluated d=3 {d}\n", .{stats[1]});
            print("evaluated d=4 {d}\n", .{stats[0]});
            print("minmax {s} {d}\n", .{move.notation(), score});
        }

        // Autoplay loop.
        else if (std.mem.eql(u8, buffer[0..8], "autoplay")) {
            for (0..100) |_| {
                var stats: Stats = .{0} ** 16;
                const minmax = board.minmax(4, &stats);
                const move = minmax.move orelse break;
                const score = minmax.score;
                _ = board.move(move);
                highlight.reset();
                highlight.add(move.orig);
                highlight.add(move.dest);
                try clear();
                print_board(&board, &highlight);
                print("{s}>{s} play\n", .{green, reset});
                print("evaluated d=1 {d}\n", .{stats[3]});
                print("evaluated d=2 {d}\n", .{stats[2]});
                print("evaluated d=3 {d}\n", .{stats[1]});
                print("evaluated d=4 {d}\n", .{stats[0]});
                print("minmax {s} {d}\n", .{move.notation(), score});
                std.time.sleep(1_000_000_000);
            }
        }

        // Select.
        else if (input_len == 3) {
            const pos = Pos.from_notation(buffer[0], buffer[1]);
            selected = pos;
            has_selected = true;
            highlight = board.get_legal_moves_for_pos(pos);
            try clear();
            print_board(&board, &highlight);
            print("{s}>{s} {s}\n", .{green, reset, selected.notation()});
            print("Selected: {s}\n", .{selected.notation()});
            print("Available moves: ", .{});
            for(0..64) |_pos| {
                const hpos = Pos.from_int(@intCast(63 - _pos));
                if (highlight.has(hpos)) {
                    print("{s}{s}, ", .{
                        selected.notation(),
                        hpos.notation(),
                    });
                }
            }
            print("\n", .{});
        }

        // Move.
        else if(input_len == 5) {
            const orig = Pos.from_notation(buffer[0], buffer[1]);
            const dest = Pos.from_notation(buffer[2], buffer[3]);
            const captured = board.move(Move{.orig=orig, .dest=dest});
            highlight.reset();
            highlight.add(orig);
            highlight.add(dest);
            has_selected = false;
            try clear();
            print_board(&board, &highlight);
            print("{s}>{s} {s}{s}\n", .{green, reset, orig.notation(), dest.notation()});
            if (captured) print("CAPTURED\n", .{});
        }

        else {
            print("command not found\n", .{});
        }
    }
}



