const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;
const Pos = @import("pos.zig").Pos;
const Piece = @import("board.zig").Piece;

// Comptime tables.
pub const pawn_moves_p1 = get_moves_pawn_all(false);
pub const pawn_moves_p2 = get_moves_pawn_all(true);
pub const pawn_captures_p1 = get_pawn_captures(false);
pub const pawn_captures_p2 = get_pawn_captures(true);
pub const king_moves = get_moves_king_all();
pub const knight_moves = get_moves_knight_all();
pub const slides = get_moves_slide();
pub const line_sink = get_line_sink();
pub const line_rise = get_line_rise();
pub const capture_score = get_capture_score();
pub const piece_hash = get_piece_hash();
pub const pawn_defense = get_pawn_defense();

fn get_moves_pawn_all(
    flip: bool,
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var all_moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos = Pos.from_int(_pos);
        const moves = get_moves_pawn_at_pos(pos, flip);
        all_moves[pos.index] = moves;
    }
    return all_moves;
}

fn get_pawn_captures(
    flip: bool,
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var all_moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos = Pos.from_int(_pos);
        var moves = BoardMask{};
        const dir: i8 = if (flip) -1 else 1;
        if (pos.col() > 0) {
            moves.add(pos.move(dir, -1));
        }
        if (pos.col() < 7) {
            moves.add(pos.move(dir, 1));
        }
        all_moves[pos.index] = moves;
    }
    return all_moves;
}

fn get_moves_king_all(
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos = Pos.from_int(_pos);
        moves[pos.index] = get_moves_king_at_pos(pos);
    }
    return moves;
}

fn get_moves_knight_all(
) [64]BoardMask {
    @setEvalBranchQuota(100_000);
    var moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos = Pos.from_int(_pos);
        moves[pos.index] = get_moves_knight_at_pos(pos);
    }
    return moves;
}

fn get_moves_pawn_at_pos(
    pos: Pos,
    flip: bool,
) BoardMask {
    var moves = BoardMask{};
    const dir: i8 = if (flip) -1 else 1;
    const initrow: u3 = if (flip) 6 else 1;
    moves.add(pos.move(dir, 0));
    if (pos.row() == initrow) {
        moves.add(pos.move(dir*2, 0));
    }
    return moves;
}

fn get_moves_king_at_pos(
    pos: Pos,
) BoardMask {
    var moves = BoardMask{};
    moves.add(pos.move(-1, -1));
    moves.add(pos.move(-1,  0));
    moves.add(pos.move(-1,  1));
    moves.add(pos.move( 0, -1));
    moves.add(pos.move( 0,  1));
    moves.add(pos.move( 1, -1));
    moves.add(pos.move( 1,  0));
    moves.add(pos.move( 1,  1));
    return moves;
}

fn get_moves_knight_at_pos(
    pos: Pos,
) BoardMask {
    var moves = BoardMask{};
    const row = pos.row();
    const col = pos.col();
    for (0..64) |_ipos| {
        const ipos = Pos.from_int(_ipos);
        const irow = ipos.row();
        const icol = ipos.col();
        const row_gap = if (row >= irow) (row-irow) else (irow-row);
        const col_gap = if (col >= icol) (col-icol) else (icol-col);
        if ((row_gap==2 and col_gap==1) or (row_gap==1 and col_gap==2)) {
            moves.add(ipos);
        }
    }
    return moves;
}

fn get_bit(
    number: u8,
    index: u3,
) u1 {
    return (number >> index) & 0b1;
}

fn set_bit(
    number: *u8,
    index: u3,
) void {
    number.* |= (0b1 << index);
}

fn get_moves_slide(
) [8][256]u8 {
    @setEvalBranchQuota(100_000);
    var moves: [8][256]u8 = undefined;
    for (0..8) |_index| {
        const index: u3 = @intCast(_index);
        for (0..256) |_mask| {
            const mask: u8 = @intCast(_mask);
            var result: u8 = 0;
            set_bit(&result, index);
            for (index..8) |_rindex| {
                const rindex: u3 = @intCast(_rindex);
                if (index == rindex) continue;
                if (get_bit(mask, rindex) == 1) {
                    set_bit(&result, rindex);
                    break;
                }
                set_bit(&result, rindex);
            }
            for (0..index) |_rindex| {
                const rindex: u3 = @intCast(index-1 - _rindex);
                if (get_bit(mask, rindex) == 1) {
                    set_bit(&result, rindex);
                    break;
                }
                set_bit(&result, rindex);
            }
            moves[index][mask] = result;
        }
    }
    return moves;
}

pub const Line = struct {
    len: u4 = 0,
    data: [8]u6 = [_]u6{0} ** 8,

    pub fn add(
        self: *Line,
        pos: Pos,
    ) void {
        if (self.len == 8) return;
        self.data[self.len] = pos.index;
        if (self.len < 8) self.len += 1;
    }

    pub fn sort(
        self: *Line,
    ) void {
        std.sort.block(u6, self.data[0..self.len], {}, sort_func);
    }

    pub fn sort_func(
        _: void,
        a: u6,
        b: u6,
    ) bool {
        return a < b;
    }

    pub fn equal(
        self: *Line,
        other: *Line,
    ) bool {
        if (self.len != other.len) return false;
        return std.mem.eql(u6, self.data[0..8], other.data[0..8]);
    }
};

fn get_line_sink(
) [64]Line {
    @setEvalBranchQuota(10_000);
    var lines: [64]Line = undefined;
    for (0..64) |_pos| {
        const pos = Pos.from_int(@intCast(_pos));
        const row: i8 = pos.row();
        const col: i8 = pos.col();
        var line = Line{};
        line.add(pos);
        for (1..8) |_walk| {
            const walk: i8 = @intCast(_walk);
            if (row+walk <= 7 and col+walk <= 7) {
                const new_pos_left = pos.move(walk, walk);
                line.add(new_pos_left);
            }
            if (row-walk >= 0 and col-walk >= 0) {
                const new_pos_right = pos.move(-walk, -walk);
                line.add(new_pos_right);
            }
        }
        line.sort();
        lines[pos.index] = line;
    }
    return lines;
}

fn get_line_rise(
) [64]Line {
    @setEvalBranchQuota(10_000);
    var lines: [64]Line = undefined;
    for (0..64) |_pos| {
        const pos = Pos.from_int(_pos);
        const row: i8 = pos.row();
        const col: i8 = pos.col();
        var line = Line{};
        line.add(pos);
        for (1..8) |_walk| {
            const walk: i8 = @intCast(_walk);
            if (row-walk >= 0 and col+walk <= 7) {
                const new_pos_left = pos.move(-walk, walk);
                line.add(new_pos_left);
            }
            if (row+walk <= 7 and col-walk >= 0) {
                const new_pos_right = pos.move(walk, -walk);
                line.add(new_pos_right);
            }
        }
        line.sort();
        lines[pos.index] = line;
    }
    return lines;
}

pub const pawn_score: [64]i16 = .{
      0,   0,   0,   0,   0,   0,   0,   0,
      14, 17,  19,  20,  20,  19,  17,  14,
      8,  13,  16,  18,  18,  16,  13,   8,
      5,   7,  12,  15,  15,  12,   7,   5,
      3,   4,  10,  12,  12,  10,   0,   0,
      2,   3,   3,   5,   5,   3,   3,   2,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0
};

pub const piece_score: [64]i16 = .{
      5,   6,   7,   7,   7,   7,   6,   5,
      6,   7,   8,   8,   8,   8,   7,   6,
      7,   8,  10,  10,  10,  10,   8,   7,
      7,   8,  10,  12,  12,  10,   8,   7,
      7,   8,  10,  12,  12,  10,   8,   7,
      7,   8,  10,  10,  10,  10,   8,   7,
      6,   7,   8,   8,   8,   8,   7,   6,
      0,   1,   2,   4,   4,   2,   1,   0,
};

fn get_capture_score() [14][14]u5 {
    var score: [14][14]u5 = std.mem.zeroes([14][14]u5);
    score[@intFromEnum(Piece.PAWN1)][@intFromEnum(Piece.QUEN2)] = 31;
    score[@intFromEnum(Piece.PAWN1)][@intFromEnum(Piece.ROOK2)] = 30;
    score[@intFromEnum(Piece.PAWN1)][@intFromEnum(Piece.KNIG2)] = 28;
    score[@intFromEnum(Piece.PAWN1)][@intFromEnum(Piece.BISH2)] = 29;
    score[@intFromEnum(Piece.KNIG1)][@intFromEnum(Piece.QUEN2)] = 27;
    score[@intFromEnum(Piece.KNIG1)][@intFromEnum(Piece.ROOK2)] = 26;
    score[@intFromEnum(Piece.KNIG1)][@intFromEnum(Piece.BISH2)] = 25;
    score[@intFromEnum(Piece.BISH1)][@intFromEnum(Piece.ROOK2)] = 23;
    score[@intFromEnum(Piece.BISH1)][@intFromEnum(Piece.QUEN2)] = 24;
    score[@intFromEnum(Piece.ROOK1)][@intFromEnum(Piece.QUEN2)] = 22;
    score[@intFromEnum(Piece.KING1)][@intFromEnum(Piece.QUEN2)] = 21;
    score[@intFromEnum(Piece.KING1)][@intFromEnum(Piece.ROOK2)] = 20;
    score[@intFromEnum(Piece.KING1)][@intFromEnum(Piece.BISH2)] = 19;
    score[@intFromEnum(Piece.KING1)][@intFromEnum(Piece.KNIG2)] = 18;
    score[@intFromEnum(Piece.KING1)][@intFromEnum(Piece.PAWN2)] = 17;
    score[@intFromEnum(Piece.QUEN1)][@intFromEnum(Piece.QUEN2)] = 16;
    score[@intFromEnum(Piece.ROOK1)][@intFromEnum(Piece.ROOK2)] = 15;
    score[@intFromEnum(Piece.BISH1)][@intFromEnum(Piece.BISH2)] = 14;
    score[@intFromEnum(Piece.KNIG1)][@intFromEnum(Piece.KNIG2)] = 13;
    score[@intFromEnum(Piece.PAWN1)][@intFromEnum(Piece.PAWN2)] = 12;
    score[@intFromEnum(Piece.QUEN1)][@intFromEnum(Piece.ROOK2)] = 11;
    score[@intFromEnum(Piece.ROOK1)][@intFromEnum(Piece.BISH2)] = 10;
    score[@intFromEnum(Piece.BISH1)][@intFromEnum(Piece.KNIG2)] = 9;
    score[@intFromEnum(Piece.KNIG1)][@intFromEnum(Piece.PAWN2)] = 8;
    score[@intFromEnum(Piece.QUEN1)][@intFromEnum(Piece.BISH2)] = 7;
    score[@intFromEnum(Piece.ROOK1)][@intFromEnum(Piece.KNIG2)] = 6;
    score[@intFromEnum(Piece.BISH1)][@intFromEnum(Piece.PAWN2)] = 5;
    score[@intFromEnum(Piece.QUEN1)][@intFromEnum(Piece.KNIG2)] = 4;
    score[@intFromEnum(Piece.ROOK1)][@intFromEnum(Piece.PAWN2)] = 3;
    score[@intFromEnum(Piece.QUEN1)][@intFromEnum(Piece.PAWN2)] = 2;

    score[@intFromEnum(Piece.PAWN2)][@intFromEnum(Piece.QUEN1)] = 31;
    score[@intFromEnum(Piece.PAWN2)][@intFromEnum(Piece.ROOK1)] = 30;
    score[@intFromEnum(Piece.PAWN2)][@intFromEnum(Piece.KNIG1)] = 28;
    score[@intFromEnum(Piece.PAWN2)][@intFromEnum(Piece.BISH1)] = 29;
    score[@intFromEnum(Piece.KNIG2)][@intFromEnum(Piece.QUEN1)] = 27;
    score[@intFromEnum(Piece.KNIG2)][@intFromEnum(Piece.ROOK1)] = 26;
    score[@intFromEnum(Piece.KNIG2)][@intFromEnum(Piece.BISH1)] = 25;
    score[@intFromEnum(Piece.BISH2)][@intFromEnum(Piece.ROOK1)] = 23;
    score[@intFromEnum(Piece.BISH2)][@intFromEnum(Piece.QUEN1)] = 24;
    score[@intFromEnum(Piece.ROOK2)][@intFromEnum(Piece.QUEN1)] = 22;
    score[@intFromEnum(Piece.KING2)][@intFromEnum(Piece.QUEN1)] = 21;
    score[@intFromEnum(Piece.KING2)][@intFromEnum(Piece.ROOK1)] = 20;
    score[@intFromEnum(Piece.KING2)][@intFromEnum(Piece.BISH1)] = 19;
    score[@intFromEnum(Piece.KING2)][@intFromEnum(Piece.KNIG1)] = 18;
    score[@intFromEnum(Piece.KING2)][@intFromEnum(Piece.PAWN1)] = 17;
    score[@intFromEnum(Piece.QUEN2)][@intFromEnum(Piece.QUEN1)] = 16;
    score[@intFromEnum(Piece.ROOK2)][@intFromEnum(Piece.ROOK1)] = 15;
    score[@intFromEnum(Piece.BISH2)][@intFromEnum(Piece.BISH1)] = 14;
    score[@intFromEnum(Piece.KNIG2)][@intFromEnum(Piece.KNIG1)] = 13;
    score[@intFromEnum(Piece.PAWN2)][@intFromEnum(Piece.PAWN1)] = 12;
    score[@intFromEnum(Piece.QUEN2)][@intFromEnum(Piece.ROOK1)] = 11;
    score[@intFromEnum(Piece.ROOK2)][@intFromEnum(Piece.BISH1)] = 10;
    score[@intFromEnum(Piece.BISH2)][@intFromEnum(Piece.KNIG1)] = 9;
    score[@intFromEnum(Piece.KNIG2)][@intFromEnum(Piece.PAWN1)] = 8;
    score[@intFromEnum(Piece.QUEN2)][@intFromEnum(Piece.BISH1)] = 7;
    score[@intFromEnum(Piece.ROOK2)][@intFromEnum(Piece.KNIG1)] = 6;
    score[@intFromEnum(Piece.BISH2)][@intFromEnum(Piece.PAWN1)] = 5;
    score[@intFromEnum(Piece.QUEN2)][@intFromEnum(Piece.KNIG1)] = 4;
    score[@intFromEnum(Piece.ROOK2)][@intFromEnum(Piece.PAWN1)] = 3;
    score[@intFromEnum(Piece.QUEN2)][@intFromEnum(Piece.PAWN1)] = 2;
    return score;
}

fn get_piece_hash() [13][64]u64 {
    @setEvalBranchQuota(1_000_000);
    var table = std.mem.zeroes([13][64]u64);
    var rand = std.Random.DefaultPrng.init(0);
    for (0..13) |piece| {
        for (0..64) |pos| {
            table[piece][pos] = rand.random().int(u64);
        }
    }
    return table;
}

fn get_pawn_defense(
) [64]u64 {
    @setEvalBranchQuota(100_000);
    var table: [64]u64 = .{0} ** 64;
    for (0..64) |_pos| {
        var mask: u64 = 0;
        const pos = Pos.from_int(@intCast(_pos));
        for (0..64) |_back| {
            const back = Pos.from_int(@intCast(_back));
            // Left.
            if (pos.col() < 7) {
                if (pos.index >= 7) {
                    if (back.index == pos.index-7) {
                        mask |= 1 << back.index;
                    }
                }
            }
            // Right.
            if (pos.col() > 0) {
                if (pos.index >= 9) {
                    if (back.index == pos.index-9) {
                        mask |= 1 << back.index;
                    }
                }
            }
        }
        table[pos.index] = mask;
    }
    return table;
}
