const std = @import("std");
const print = std.debug.print;
const Board = @import("board.zig").Board;
const Player = @import("board.zig").Player;
const _pos = @import("pos.zig");
const Pos = _pos.Pos;
const Move = _pos.Move;
const MoveList = _pos.MoveList;
const MoveListShort = _pos.MoveListShort;
const MoveAndScore = _pos.MoveAndScore;
const Cache = @import("cache.zig").Cache;
const CacheEntry = @import("cache.zig").CacheEntry;
const terminal = @import("terminal.zig");

pub const Stats = struct {
    total: u32 = 0,
    evals: [16]u32 = .{0} ** 16,
    prune: [16]u32 = .{0} ** 16,

    pub fn reset(
        self: *Stats,
    ) void {
        self.total = 0;
        self.evals = .{0} ** 16;
        self.prune = .{0} ** 16;
    }
};

pub fn minmax(
    board: *Board,
    stats: *Stats,
) MoveAndScore {
    // var cache = Cache{};
    // cache.reset();
    var path = MoveListShort{};
    // const nmoves = board.count_legal_moves();
    const npieces = board.n_pieces;
    var boost: u4 = 0;
    if (npieces <= 6) boost += 1;
    if (npieces <= 4) boost += 1;
    return minmax_node(board, 0, boost, 32000, -32000, stats, &path);
}

// pub fn minmax_dynamic(
//     board: *Board,
//     stats: *Stats,
// ) MoveAndScore {
//     var result: MoveAndScore = MoveAndScore{.score=0, .move=null};
//     // Half.
//     const depth_half = @divTrunc(DEPTH[3], 2);
//     result = minmax_node(board, 0, depth_half, 32000, -32000, stats, result.path);
//     // Full.
//     stats.*.reset();
//     result = minmax_node(board, 0, DEPTH[3], 32000, -32000, stats, result.path);
//     return result;
// }

pub fn minmax_node(
    board: *Board,
    depth: u4,
    boost: u4,
    // depth_max: u4,
    best_min: i16,
    best_max: i16,
    stats: *Stats,
    path: *MoveListShort,
    // cache: *Cache,
) MoveAndScore {

    // const cache_entry_ = cache.*.get(board.hash, board.turn==Player.PLAYER2);
    // if (cache_entry_) |cache_entry| {
    //     if (cache_entry.best.depth >= depth) {
    //         // terminal.indent(depth);
    //         // std.debug.print("{x} ", .{cache_entry.hash});
    //         // std.debug.print("{any}-", .{depth});
    //         // std.debug.print("{any} ", .{cache_entry.best.depth});
    //         // std.debug.print("{s} ", .{cache_entry.best.move.?.notation()});
    //         // std.debug.print("{any}", .{cache_entry.best.score});
    //         // std.debug.print("\n", .{});
    //         stats.*.evals[15] += 1;
    //         return cache_entry.best;
    //     }
    // }

    // const is_leaf = (
    //     (depth == DEPTH[3]+boost) or                        // Max.
    //     (depth >= DEPTH[2]+boost and board.heat < 3) or     // Not heat 3.
    //     (depth >= DEPTH[1]+boost and board.heat < 2) or     // Not heat 2.
    //     (depth >= DEPTH[0]+boost and board.heat < 1)  // Not heat 1.
    // );

    const extend = (
        (depth < DEPTH[0]+boost) or
        (depth < DEPTH[1]+boost and board.heat >= 1) or
        (depth < DEPTH[2]+boost and board.heat >= 2) or
        (depth < DEPTH[3]+boost and board.heat >= 3)
    );
    if (!extend) {
        const score = board.get_score();
        stats.*.total += 1;
        stats.*.evals[depth] += 1;
        // terminal.indent(depth);
        // print("{d} ({d})\n", .{score, depth});
        const best = MoveAndScore{.move=null, .score=score};
        // cache.*.set(CacheEntry{.hash=board.hash, .best=best}, board.turn==Player.PLAYER2);
        return best;
    }

    // If not leaf, process node.
    var init_score: i16 = @as(i16, -32000) + depth;
    if (board.turn==Player.PLAYER2) init_score = -init_score;
    var best: MoveAndScore = MoveAndScore{.move=null, .score=init_score};
    var new_best_min = best_min;
    var new_best_max = best_max;
    var legal = board.get_legal_moves();
    // Draw by stalemate.
    if (legal.len == 0 and !board.is_check_on_own()) {
        best.score = 0;
        return best;
    }
    // Draw by repetition.
    if (depth > 0 and board.hashlist.last_was_duplicated) {
        best.score = 0;
        return best;
    }
    // Iterate moves.
    legal.sort();
    // legal.sort_with_priority(path.data[depth]);
    for (0..legal.len) |i| {
        const move = legal.data[i];
        // path.data[depth] = move;

        // Prune.
        if (best_min <= best_max) {
            best.score = if (board.turn==Player.PLAYER1) best_max-1 else best_min+1;
            stats.*.total += 1;
            stats.*.prune[depth] += 1;
            break;
        }
        // Go deeper.
        var fork = board.fork_with_move(move);
        const candidate = minmax_node(
            &fork,
            depth+1,
            boost,
            // depth_max,
            new_best_min,
            new_best_max,
            stats,
            path,
        );
        // Debug path.
        // if (is_debug_path(depth, path)) {
        //     terminal.indent(depth+1);
        //     const c = if (board.turn==Player.PLAYER1) "P1" else "P2";
        //     print("{s} {s} ({d})\n", .{c, move.notation(), candidate.score});
        // }
        // Compare scores.
        if (
            (!best.score_defined) or
            (board.turn == Player.PLAYER1 and candidate.score > best.score) or
            (board.turn == Player.PLAYER2 and candidate.score < best.score)
        ) {
            best.move = move;
            best.score = candidate.score;
            best.score_defined = true;
            best.path = candidate.path;
            best.path.add(move);
            if (board.turn == Player.PLAYER1) {
                new_best_max = candidate.score;
            } else {
                new_best_min = candidate.score;
            }
        }
    }
    // cache.*.set(
    //     CacheEntry{.hash=board.hash, .best=best},
    //     board.turn==Player.PLAYER2
    // );
    if (depth == 0) best.path.reverse();
    return best;
}

fn is_debug_path(
    depth: u4,
    path: *MoveListShort,
) bool {
    var path_debug = MoveListShort{};
    path_debug.add(Move.from_notation("f7f6"));
    path_debug.add(Move.from_notation("d5e4"));
    path_debug.add(Move.from_notation("d8d2"));
    path_debug.add(Move.from_notation("g6h7"));
    for (0..depth) |d| {
        const move = path_debug.data[d];
        if (!path.*.data[d].eq(&move)) return false;
    }
    return true;
}


// const DEPTH = .{4, 5, 5, 8};  // 1200+
// const DEPTH = .{4, 6, 6, 8};  // 1400+ 1500-
// const DEPTH = .{4, 6, 7, 9};  // 1700-P20
// const DEPTH = .{5, 6, 7, 9}; // 1500+P11   too slow
// const DEPTH = .{4, 6, 6, 10};  // 1600+P2  1600-P1  1700-P4
// const DEPTH = .{4, 6, 7, 10};
// const DEPTH = .{5, 5, 5, 7};  // 1600+P1
// const DEPTH = .{5, 5, 5, 9};  // 1700=P2  1700-P4
// const DEPTH = .{5, 7, 7, 7};  // 1700-P15
// const DEPTH = .{5, 5, 7, 9};  //1600+P12

// MID
const DEPTH = .{4, 6, 6, 10};  // 1500+++ 1600+=++  1700---  P2 P8

// const DEPTH = .{4, 7, 7, 10};
