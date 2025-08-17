const std = @import("std");
const print = std.debug.print;
const Board = @import("board.zig").Board;
const minmax = @import("minmax.zig");
const _pos = @import("pos.zig");
const Pos = _pos.Pos;
const Move = _pos.Move;
const MoveList = _pos.MoveList;

pub const Game = struct {
    boards: [256]Board = undefined,
    index: u8 = 0,
    len: u8 = 0,
    highlight_orig: i32 = -1,
    highlight_dest: i32 = -1,
    // moves: MoveListLong,

    pub fn init(
        self: *Game,
    ) void {
        self.index = 0;
        self.len = 0;
        self.clear();
    }

    pub fn clear(
        self: *Game,
    ) void {
        self.highlight_orig = -1;
        self.highlight_dest = -1;
    }

    pub fn start(
        self: *Game,
    ) void {
        self.init();
        self.current().*.start();
    }

    pub fn setup(
        self: *Game,
    ) void {
        self.current().*.setup();
    }

    pub fn current(
        self: *Game,
    ) *Board {
        return &self.boards[self.index];
    }

    pub fn get(
        self: *Game,
        index: i32
    ) i32 {
        const board: *Board = self.current();
        const pos = Pos.from_int(@intCast(index));
        const result: i32 = @intFromEnum(board.*.get(pos));
        return result;
    }

    pub fn move_legal(
        self: *Game,
        move: Move,
    ) i32 {
        const board: *Board = self.current();
        const legal = board.*.get_legal_moves();
        var is_legal = false;
        for(0..legal.len) |i| {
            const allowed_move = legal.data[i];
            if (move.eq(&allowed_move)) is_legal = true;
        }
        if (is_legal) {
            self.move_game(move);
            return 1;
        }
        return 0;
    }

    pub fn move_bot(
        self: *Game,
    ) void {
        // const start = std.time.nanoTimestamp();
        var stats = minmax.Stats{};
        const mm = minmax.minmax(self.current(), &stats);
        // const end = std.time.nanoTimestamp();
        // const elapsed = @divFloor(end-start, 1_000_000_000);
        // const total_evals: i64 = @intCast(stats.evals[ 0]);
        // const per_eval = @divFloor(end-start, total_evals);
        const move = mm.move orelse unreachable;
        // const score = minmax.score;
        // prev_board = board;
        self.move_game(move);
        self.highlight_orig = move.orig.index;
        self.highlight_dest = move.dest.index;
    }

    pub fn move_game(
        self: *Game,
        move: Move,
    ) void {
        const board: *Board = self.current();
        self.boards[self.index+1] = board.*.fork_with_move(move);
        self.index += 1;
        self.len = self.index;
    }

    pub fn undo(
        self: *Game,
    ) void {
        if (self.index == 0) return;
        self.index -= 1;
        self.clear();
    }

    pub fn redo(
        self: *Game,
    ) void {
        if (self.index == self.len) return;
        self.index += 1;
        self.clear();
    }
};
