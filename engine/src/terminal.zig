const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;
const Board = @import("board.zig").Board;
const Piece = @import("board.zig").Piece;
const Player = @import("board.zig").Player;
const Pos = @import("pos.zig").Pos;
const Move = @import("pos.zig").Move;
const minmax = @import("minmax.zig").minmax;
const Stats = @import("minmax.zig").Stats;

const tables = @import("tables.zig");

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
                Piece.KING1 => print("{c}{s}✚{s}{c}", .{pre, blue2, reset, post}),
                Piece.KING2 => print("{c}{s}✚{s}{c}", .{pre, red2, reset, post}),
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
    var prev_board = Board.init();
    try clear();
    // var selected: Pos = undefined;
    var has_selected = false;
    var highlight = BoardMask{.mask=0};
    print_board(&board, &highlight);
    var buffer: [128]u8 = undefined;

    while(true) {
        print("{s}>{s} ", .{green, reset});
        @memset(&buffer, 0);
        const input_len = try stdin.read(&buffer);

        if (std.mem.eql(u8, buffer[0..5], "reset")) {
            board.reset();
            has_selected = false;
            highlight = BoardMask{.mask=0};
            try clear();
            print_board(&board, &highlight);
            continue;
        }

        if (std.mem.eql(u8, buffer[0..5], "setup")) {
            board = Board{};
            board.setup();
            board.switch_turn();
            has_selected = false;
            highlight = BoardMask{.mask=0};
            try clear();
            print_board(&board, &highlight);
            continue;
        }

        if (
            std.mem.eql(u8, buffer[0..4], "undo") or
            std.mem.eql(u8, buffer[0..1], "u")
        ) {
            board = prev_board;
            try clear();
            print_board(&board, &highlight);
            continue;
        }

        if (std.mem.eql(u8, buffer[0..5], "legal")) {
            const legal = board.get_legal_moves();
            for (0..legal.len) |i| {
                const move = legal.data[i];
                print("{s}, ", .{ move.notation() });
            }
            print("\n", .{});
            continue;
        }

        // if (std.mem.eql(u8, buffer[0..5], "capture")) {
        //     const legal = board.get_legal_moves();
        //     for (0..legal.len) |i| {
        //         const move = legal.data[i];
        //         print("{s}, ", .{ move.notation() });
        //     }
        //     print("\n", .{});
        //     continue;
        // }

        if (std.mem.eql(u8, buffer[0..4], "eval")) {
            const score = board.get_score();
            print("score={d}\n", .{score});
            continue;
        }

        if (std.mem.eql(u8, buffer[0..4], "hash")) {
            print("hash={x}\n", .{board.hash});
            continue;
        }

        if (std.mem.eql(u8, buffer[0..4], "king")) {
            const can_capture_king = board.is_check_on_opp();
            print("can_capture_king={}\n", .{can_capture_king});
            continue;
        }

        if (std.mem.eql(u8, buffer[0..8], "dumpcode")) {
            const str = board.save_to_string();
            print("\"{s}\" ++\n", .{str[8*0..1*8]});
            print("\"{s}\" ++\n", .{str[8*1..2*8]});
            print("\"{s}\" ++\n", .{str[8*2..3*8]});
            print("\"{s}\" ++\n", .{str[8*3..4*8]});
            print("\"{s}\" ++\n", .{str[8*4..5*8]});
            print("\"{s}\" ++\n", .{str[8*5..6*8]});
            print("\"{s}\" ++\n", .{str[8*6..7*8]});
            print("\"{s}\"\n",    .{str[8*7..8*8]});
            continue;
        }

        if (std.mem.eql(u8, buffer[0..4], "dump")) {
            const str = board.save_to_string();
            print("{s}\n", .{str});
            continue;
        }

        if (std.mem.eql(u8, buffer[0..4], "load")) {
            const str = buffer[5..69];
            board.load_from_string(str);
            board.switch_turn();
            try clear();
            print_board(&board, &highlight);
            continue;
        }

        // Autoplay once.
        if (
            (input_len == 5 and (std.mem.eql(u8, buffer[0..4], "play"))) or
            (input_len == 2 and buffer[0] == 'p')
        ) {
            var stats = Stats{};
            const start = std.time.nanoTimestamp();
            const mm = minmax(&board, &stats);
            const end = std.time.nanoTimestamp();
            const elapsed = @divFloor(end-start, 1_000_000_000);
            const total_evals: i64 = @intCast(stats.total);
            const per_eval = @divFloor(end-start, total_evals);
            const move = mm.move orelse unreachable;
            const score = mm.score;
            prev_board = board;
            board = board.fork_with_move(move);
            highlight.reset();
            highlight.add(move.orig);
            highlight.add(move.dest);
            try clear();
            print_board(&board, &highlight);
            print("{s}>{s} play\n", .{green, reset});
            print("evaluated\n", .{});
            // print("  cache {d:>9}\n", .{stats.evals[15]});
            print("  d=3   {d:>9} {d:>9}\n", .{stats.evals[ 3], stats.prune[ 3]});
            print("  d=4   {d:>9} {d:>9}\n", .{stats.evals[ 4], stats.prune[ 4]});
            print("  d=5   {d:>9} {d:>9}\n", .{stats.evals[ 5], stats.prune[ 5]});
            print("  d=6   {d:>9} {d:>9}\n", .{stats.evals[ 6], stats.prune[ 6]});
            print("  d=7   {d:>9} {d:>9}\n", .{stats.evals[ 7], stats.prune[ 7]});
            print("  d=8   {d:>9} {d:>9}\n", .{stats.evals[ 8], stats.prune[ 8]});
            print("  d=9   {d:>9} {d:>9}\n", .{stats.evals[ 9], stats.prune[ 9]});
            print("  d=10  {d:>9} {d:>9}\n", .{stats.evals[10], stats.prune[10]});
            const total = @as(f32, @floatFromInt(total_evals)) / 1_000_000.0;
            print("{d:.1}M in {d} seconds\n", .{total, elapsed});
            print("{d} ns / node\n", .{per_eval});
            print("minmax {s} {d}\n", .{move.notation(), score});
            // print("eval path {d}\n", .{stats.history.len});
            // var i: usize = 0;
            // while (i<stats.history.len) : (i+=2) {
            //     print("  {s}, ", .{stats.history.data[i].notation()});
            //     print("{s} \n", .{stats.history.data[i+1].notation()});
            // }
            continue;
        }

        // // Autoplay loop.
        // if (std.mem.eql(u8, buffer[0..8], "autoplay")) {
        //     for (0..100) |_| {
        //         var stats: Stats = .{0} ** 16;
        //         const minmax = board.minmax(0, 4, 7, 32000, -32000, &stats);
        //         const move = minmax.move orelse break;
        //         prev_board = board;
        //         board = board.fork_with_move(move);
        //         highlight.reset();
        //         highlight.add(move.orig);
        //         highlight.add(move.dest);
        //         try clear();
        //         print_board(&board, &highlight);
        //         std.time.sleep(500_000_000);
        //     }
        //     continue;
        // }

        // // Select.
        // if (input_len == 3) {
        //     const pos = Pos.from_notation(buffer[0], buffer[1]);
        //     selected = pos;
        //     has_selected = true;
        //     highlight = board.get_moves_for_pos(pos);
        //     try clear();
        //     print_board(&board, &highlight);
        //     print("{s}>{s} {s}\n", .{green, reset, selected.notation()});
        //     print("Selected: {s}\n", .{selected.notation()});
        //     print("Available moves: ", .{});
        //     for(0..64) |_pos| {
        //         const hpos = Pos.from_int(@intCast(63 - _pos));
        //         if (highlight.has(hpos)) {
        //             print("{s}, ", .{hpos.notation()});
        //         }
        //     }
        //     print("\n", .{});
        //     continue;
        // }

        // Move.
        if(
            (input_len == 5) or
            (input_len == 4 and buffer[0] == '.')
        ) {
            var orig: Pos = undefined;
            var dest: Pos = undefined;
            if (input_len == 5) {
                orig = Pos.from_notation(buffer[0], buffer[1]);
                dest = Pos.from_notation(buffer[2], buffer[3]);
            }
            if (input_len == 4) {
                // orig = selected;
                dest = Pos.from_notation(buffer[1], buffer[2]);
            }
            prev_board = board;
            board = board.fork_with_move(Move{.orig=orig, .dest=dest});
            highlight.reset();
            highlight.add(orig);
            highlight.add(dest);
            has_selected = false;
            try clear();
            print_board(&board, &highlight);
            print("{s}>{s} {s}{s}\n", .{green, reset, orig.notation(), dest.notation()});
            continue;
        }

        // Move easy notation.
        if(input_len == 4) {
            var orig_: ?Pos = null;
            const dest = Pos.from_notation(buffer[1], buffer[2]);
            const legal = board.get_legal_moves();
            for(0..legal.len) |i| {
                const move = legal.data[i];
                if (move.dest.index != dest.index) continue;
                const piece = board.get(move.orig);
                switch (buffer[0]) {
                    'p' => {if (piece==Piece.PAWN1 or piece==Piece.PAWN2) orig_ = move.orig;},
                    'r' => {if (piece==Piece.ROOK1 or piece==Piece.ROOK2) orig_ = move.orig;},
                    'n' => {if (piece==Piece.KNIG1 or piece==Piece.KNIG2) orig_ = move.orig;},
                    'b' => {if (piece==Piece.BISH1 or piece==Piece.BISH2) orig_ = move.orig;},
                    'q' => {if (piece==Piece.QUEN1 or piece==Piece.QUEN2) orig_ = move.orig;},
                    'k' => {if (piece==Piece.KING1 or piece==Piece.KING2) orig_ = move.orig;},
                    else => {},
                }
            }
            if (orig_) |orig| {
                prev_board = board;
                board = board.fork_with_move(Move{.orig=orig, .dest=dest});
                highlight.reset();
                highlight.add(orig);
                highlight.add(dest);
                has_selected = false;
                try clear();
                print_board(&board, &highlight);
                print("{s}>{s} {s}{s}\n", .{green, reset, orig.notation(), dest.notation()});
            } else {
                print("notation error\n", .{});
            }
            continue;
        }

        // Move easy notation even easier.
        if(input_len == 3) {
            var orig_: ?Pos = null;
            const dest = Pos.from_notation(buffer[0], buffer[1]);
            const legal = board.get_legal_moves();
            for(0..legal.len) |i| {
                const move = legal.data[i];
                // print("{s}\n", .{move.notation()});
                if (move.dest.index != dest.index) continue;
                orig_ = move.orig;
                break;
            }
            if (orig_) |orig| {
                prev_board = board;
                board = board.fork_with_move(Move{.orig=orig, .dest=dest});
                highlight.reset();
                highlight.add(orig);
                highlight.add(dest);
                has_selected = false;
                try clear();
                print_board(&board, &highlight);
                print("{s}>{s} {s}{s}\n", .{green, reset, orig.notation(), dest.notation()});
            } else {
                print("notation error\n", .{});
            }
            continue;
        }

        print("command not found\n", .{});
    }
}



