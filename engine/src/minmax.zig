const std = @import("std");
const print = std.debug.print;
const Board = @import("board.zig").Board;
const Player = @import("board.zig").Player;
const MoveList = @import("pos.zig").MoveList;
const MoveAndScore = @import("pos.zig").MoveAndScore;
const Cache = @import("cache.zig").Cache;
const CacheEntry = @import("cache.zig").CacheEntry;
const terminal = @import("terminal.zig");

pub const Stats = struct {
    evals: [16]u32 = .{0} ** 16,
    history: MoveList = MoveList{},
};

pub fn minmax(
    board: *Board,
    stats: *Stats,
) MoveAndScore {
    var cache = Cache{};
    cache.reset();
    return minmax_node(board, 0, 32000, -32000, stats, &cache);
}

pub fn minmax_node(
    board: *Board,
    depth: u4,
    best_min: i16,
    best_max: i16,
    stats: *Stats,
    cache: *Cache,
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

    const p1 = board.turn == Player.PLAYER1;
    const opp_cold = if (p1) !board.last_p2_move_hot else !board.last_p1_move_hot;
    const all_cold = !board.last_p1_move_hot and !board.last_p2_move_hot;
    // var boost: u4 = 0;
    // if (board.n_pieces <= 10) boost += 2;
    // if (board.n_pieces <= 5) boost += 2;
    const is_leaf = (
        // depth == DEPTH_MAX
        (depth == DEPTH_MAX) or
        (depth >= DEPTH_HOT and opp_cold) or
        (depth >= DEPTH_COLD and all_cold)
    );
    // Calculate score on leafs.
    if (is_leaf) {
        const score = board.get_score();
        stats.*.evals[0] += 1;
        stats.*.evals[depth] += 1;
        // terminal.indent(depth);
        // print("{x} {d}\n", .{board.hash, score});
        const best = MoveAndScore{.move=null, .score=score, .depth=depth};
        // cache.*.set(CacheEntry{.hash=board.hash, .best=best}, board.turn==Player.PLAYER2);
        return best;
    // Explore branches.
    } else {
        var init_score: i16 = @as(i16, -32000) + depth;
        if (board.turn==Player.PLAYER2) init_score = -init_score;

        // var hot_move_exist = false;

        var best: MoveAndScore = MoveAndScore{.move=null, .score=init_score, .depth=depth};
        var new_best_min = best_min;
        var new_best_max = best_max;
        const legal = board.get_legal_moves();
        // Draw by stalemate.
        if (legal.len == 0 and !board.is_check_on_own()) {
            best.score = 0;
            return best;
        }
        // Iterate moves.
        for (0..legal.len) |i| {
            // if (depth == 6 and i == DEPTH6) break;
            // if (depth == 7 and i == DEPTH7) break;
            // if (depth == 8 and i == DEPTH8) break;
            // if (depth == 9 and i == DEPTH9) break;
            // if (depth == 10 and i == DEPTH10) break;
            // if (depth == 11 and i == DEPTH11) break;
            const move = legal.data[i];

            // terminal.indent(depth);
            // print("{s}\n", .{move.notation()});

            // if (depth >= DEPTH_HOT and move.capture_score==0) {
            //     break;
            // } else {
            //     hot_move_exist = true;
            // }

            // Prune.
            if (best_min <= best_max) {
                best.score = if (board.turn==Player.PLAYER1) best_max-1 else best_min+1;
                break;
            }
            // Go deeper.
            var fork = board.fork_with_move(move);
            const candidate = minmax_node(
                &fork,
                depth+1,
                new_best_min,
                new_best_max,
                stats,
                cache,
            );
            // Compare scores.
            if (
                (!best.score_defined) or
                (board.turn == Player.PLAYER1 and candidate.score > best.score) or
                (board.turn == Player.PLAYER2 and candidate.score < best.score)
            ) {
                best.move = move;
                best.depth = candidate.depth;
                best.score = candidate.score;
                best.score_defined = true;
                if (board.turn == Player.PLAYER1) {
                    new_best_max = candidate.score;
                } else {
                    new_best_min = candidate.score;
                }
            }
        }
        // if (depth >= DEPTH_HOT and !hot_move_exist) {
        //     best.score = board.get_score();
        // }

        // cache.*.set(
        //     CacheEntry{.hash=board.hash, .best=best},
        //     board.turn==Player.PLAYER2
        // );

        // if (depth==0) {
        //     const x = cache.*.get(board.hash);
        //     std.debug.print("{any}", .{x});
        // }
        return best;
    }
}

// pub fn dynamic_minmax(
//     board: *Board,
//     depth_max: u4,
// ) MoveAndScore {
//     var stats = Stats{};
//     for (0..depth_max) |depth| {
//         const mm = minmax(board, depth, depth_max, 32000, -32000, &stats);
//     }
// }

const DEPTH_COLD = 6;
const DEPTH_HOT =  6;
const DEPTH_MAX =  8;



    // EASY ???
    // 1200+++ 1300- (very fast)
    // const DEPTH_COLD = 4;
    // const DEPTH_HOT =  4;
    // const DEPTH_MAX =  7;

    // EASY ???
    // 1300+ 1400+ (fast)
    // const DEPTH_COLD = 4;
    // const DEPTH_HOT =  5;
    // const DEPTH_MAX =  7;

    // NORMAL
    // 1500++ 1600-+++ 1700- (fast-mid)
    // const DEPTH_COLD = 4;
    // const DEPTH_HOT =  5;
    // const DEPTH_MAX =  9;

    // HARD
    // 1700+ 1800+ (mid)
    // const DEPTH_COLD = 5;
    // const DEPTH_HOT =  6;
    // const DEPTH_MAX =  8;

// 1800-
// const DEPTH_COLD = 5;
// const DEPTH_HOT =  5;
// const DEPTH_MAX =  9;

// 1800? but slow
// const DEPTH_COLD = 5;
// const DEPTH_HOT =  6;
// const DEPTH_MAX =  9;

// 1800-! 1700-
// const DEPTH_COLD = 4;
// const DEPTH_HOT =  5;
// const DEPTH_MAX =  11;

// const DEPTH_COLD = 5;
// const DEPTH_HOT =  5;
// const DEPTH_MAX =  8;

// 1600+- (mid)
// const DEPTH_COLD = 5;
// const DEPTH_HOT =  5;
// const DEPTH_MAX =  7;

// 1600-
// const DEPTH_COLD = 5;
// const DEPTH_HOT =  5;
// const DEPTH_MAX =  5;

// 1400-+- 1500+ 1600=--
// const DEPTH_COLD = 4;
// const DEPTH_HOT =  6;
// const DEPTH_MAX =  6;

// 1500+(mobile) 1500+(mobile) 1600(browser)  1200-?????
// const DEPTH_COLD = 5;
// const DEPTH_HOT =  6;
// const DEPTH_MAX =  6;

// HARD
// 1600+ 1700+(browser)   safari<=10s
// const DEPTH_COLD = 5;
// const DEPTH_HOT =  7;
// const DEPTH_MAX =  7;

// slow
// const DEPTH_COLD = 5;
// const DEPTH_HOT =  7;
// const DEPTH_MAX =  9;


