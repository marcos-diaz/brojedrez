const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;
const Pos = @import("pos.zig").Pos;

// Comptime tables.
pub const pawn_moves_p1 = get_moves_pawn_all(false);
pub const pawn_moves_p2 = get_moves_pawn_all(true);
pub const king_moves = get_moves_king_all();
pub const knight_moves = get_moves_knight_all();
pub const slides = get_moves_slide();
pub const line_sink = get_line_sink();
pub const line_rise = get_line_rise();

fn get_moves_pawn_all(
    flip: bool,
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        var pos = Pos.from_int(_pos);
        pos = if (flip) (pos.reverse()) else pos;
        moves[pos.index] = get_moves_pawn_at_pos(pos, flip);
    }
    return moves;
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
    moves.add(pos.move(0, 1));
    if (pos.row() == 1) {
        moves.add(pos.move(0, 2));
    }
    if (flip) moves.flip();
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
