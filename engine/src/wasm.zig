const std = @import("std");
const Board = @import("board.zig").Board;
const Piece = @import("board.zig").Piece;
const Stats = @import("board.zig").Stats;
const Pos = @import("pos.zig").Pos;
const Move = @import("pos.zig").Move;

var board: Board = undefined;

pub export fn init() void {
    board = Board.init();
}

pub export fn get(index: i32) i32 {
    const pos = Pos.from_int(@intCast(index));
    const result: i32 = @intFromEnum(board.get(pos));
    return result;
}

pub export fn legal_move(index0: i32, index1: i32) i32 {
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
        board.move_to(move);
        return 0;
    }
    return 1;
}

pub export fn autoplay() void {
    var stats = Stats{};
    // const start = std.time.nanoTimestamp();
    const minmax = board.minmax(0, 32000, -32000, &stats);
    // const end = std.time.nanoTimestamp();
    // const elapsed = @divFloor(end-start, 1_000_000_000);
    // const total_evals: i64 = @intCast(stats.evals[ 0]);
    // const per_eval = @divFloor(end-start, total_evals);
    const move = minmax.move orelse unreachable;
    // const score = minmax.score;
    // prev_board = board;
    board = board.fork_with_move(move);
}
