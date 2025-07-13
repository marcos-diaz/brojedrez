const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;

// Comptime tables.
pub const pawn_moves_p1 = get_moves_pawn_all(false);
pub const pawn_moves_p2 = get_moves_pawn_all(true);
pub const king_moves = get_moves_king_all();
pub const knight_moves = get_moves_knight_all();
pub const slides = get_moves_slide();
pub const diagonal_down_pos = get_diagonal_down_positions();
pub const diagonal_up_pos = get_diagonal_up_positions();

fn get_moves_pawn_all(
    flip: bool,
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos: u6 = @intCast(_pos);
        const index = if (flip) (63-pos) else pos;
        moves[index] = get_moves_pawn_at_pos(@intCast(pos), flip);
    }
    return moves;
}

fn get_moves_king_all(
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos: u6 = @intCast(_pos);
        moves[pos] = get_moves_king_at_pos(pos);
    }
    return moves;
}

fn get_moves_knight_all(
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos: u6 = @intCast(_pos);
        moves[pos] = get_moves_knight_at_pos(pos);
    }
    return moves;
}

fn get_moves_pawn_at_pos(
    pos: u6,
    flip: bool,
) BoardMask {
    var moves = BoardMask{};
    const row: u6 = pos / 8;
    const col: u6 = pos % 8;
    for (0..64) |_ipos| {
        const ipos: u6 = @intCast(_ipos);
        const irow: u6 = ipos / 8;
        const icol: u6 = ipos % 8;
        if (col == icol) {
            if ((irow == row+1)) {
                moves.add(ipos);
            }
            // Double move.
            if (irow == 3 and row == 1) {
                moves.add(ipos);
            }
        }
    }
    if (flip) moves.flip();
    return moves;
}

fn get_moves_king_at_pos(
    pos: u6,
) BoardMask {
    var moves = BoardMask{};
    const row: u6 = pos / 8;
    const col: u6 = pos % 8;
    for (0..64) |_ipos| {
        const ipos: u6 = @intCast(_ipos);
        const irow: u6 = ipos / 8;
        const icol: u6 = ipos % 8;
        const row_gap = if (row >= irow) (row-irow) else (irow-row);
        const col_gap = if (col >= icol) (col-icol) else (icol-col);
        if ((row_gap==1 and col_gap<2) or (row_gap<2 and col_gap==1)) {
            moves.add(ipos);
        }
    }
    return moves;
}

fn get_moves_knight_at_pos(
    pos: u6,
) BoardMask {
    var moves = BoardMask{};
    const row: u6 = pos / 8;
    const col: u6 = pos % 8;
    for (0..64) |_ipos| {
        const ipos: u6 = @intCast(_ipos);
        const irow: u6 = ipos / 8;
        const icol: u6 = ipos % 8;
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

pub const PosList = struct {
    len: u4 = 0,
    data: [8]u6 = [_]u6{0} ** 8,

    pub fn add(
        self: *PosList,
        pos: u6,
    ) void {
        if (self.len == 8) return;
        self.data[self.len] = pos;
        if (self.len < 8) self.len += 1;
    }

    pub fn sort(
        self: *PosList,
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
        self: *PosList,
        other: *PosList,
    ) bool {
        if (self.len != other.len) return false;
        return std.mem.eql(u6, self.data[0..8], other.data[0..8]);
    }
};

fn get_diagonal_down_positions(
) [64]PosList {
    @setEvalBranchQuota(10_000);
    var lists: [64]PosList = undefined;
    for (0..64) |_pos| {
        const pos: u6 = @intCast(_pos);
        const row: i8 = pos / 8;
        const col: i8 = pos % 8;
        var list = PosList{};
        list.add(pos);
        for (1..8) |_walk| {
            const walk: i8 = @intCast(_walk);
            if (row+walk <= 7 and col+walk <= 7) {
                const new_pos_left = col+walk + ((row+walk) * 8);
                list.add(@intCast(new_pos_left));
            }
            if (row-walk >= 0 and col-walk >= 0) {
                const new_pos_right = col-walk + ((row-walk) * 8);
                list.add(@intCast(new_pos_right));
            }
        }
        list.sort();
        lists[pos] = list;
    }
    return lists;
}

fn get_diagonal_up_positions(
) [64]PosList {
    @setEvalBranchQuota(10_000);
    var lists: [64]PosList = undefined;
    for (0..64) |_pos| {
        const pos: u6 = @intCast(_pos);
        const row: i8 = pos / 8;
        const col: i8 = pos % 8;
        var list = PosList{};
        list.add(pos);
        for (1..8) |_walk| {
            const walk: i8 = @intCast(_walk);
            if (row-walk >= 0 and col+walk <= 7) {
                const new_pos_left = col+walk + ((row-walk) * 8);
                list.add(@intCast(new_pos_left));
            }
            if (row+walk <= 7 and col-walk >= 0) {
                const new_pos_right = col-walk + ((row+walk) * 8);
                list.add(@intCast(new_pos_right));
            }
        }
        list.sort();
        lists[pos] = list;
    }
    return lists;
}
