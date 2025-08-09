const std = @import("std");
const Board = @import("board.zig").Board;
const Piece = @import("board.zig").Piece;
const Pos = @import("pos.zig").Pos;
const Move = @import("pos.zig").Move;
const minmax = @import("minmax.zig").minmax;
const Stats = @import("minmax.zig").Stats;

var board: Board = undefined;
var board_prev: Board = undefined;
var highlight_orig: i32 = -1;
var highlight_dest: i32 = -1;

pub export fn init() void {
    board = Board.init();
}

pub export fn get(index: i32) i32 {
    const pos = Pos.from_int(@intCast(index));
    const result: i32 = @intFromEnum(board.get(pos));
    return result;
}

pub export fn move_legal(index0: i32, index1: i32) i32 {
    const orig = Pos.from_int(@intCast(index0));
    const dest = Pos.from_int(@intCast(index1));
    const move = Move{.orig=orig, .dest=dest};
    const legal = board.get_legal_moves();
    var is_legal = false;
    for(0..legal.len) |i| {
        const allowed_move = legal.data[i];
        if (move.eq(&allowed_move)) is_legal = true;
    }
    if (is_legal) {
        board_prev = board;
        board.move_to(move);
        return 0;
    }
    return 1;
}

pub export fn autoplay() void {
    // const start = std.time.nanoTimestamp();
    var stats = Stats{};
    const mm = minmax(&board, &stats);
    // const end = std.time.nanoTimestamp();
    // const elapsed = @divFloor(end-start, 1_000_000_000);
    // const total_evals: i64 = @intCast(stats.evals[ 0]);
    // const per_eval = @divFloor(end-start, total_evals);
    const move = mm.move orelse unreachable;
    // const score = minmax.score;
    // prev_board = board;
    board = board.fork_with_move(move);
    highlight_orig = move.orig.index;
    highlight_dest = move.dest.index;
}

pub export fn get_highlight_orig() i32 {
    return highlight_orig;
}

pub export fn get_highlight_dest() i32 {
    return highlight_dest;
}

pub export fn undo() void {
    board = board_prev;
}
