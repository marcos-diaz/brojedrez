const BoardMask = @import("boardmask.zig").BoardMask;

// Comptime tables.
pub const pawn_moves_p1 = get_moves_pawn_all(false);
pub const pawn_moves_p2 = get_moves_pawn_all(true);
pub const king_moves = get_moves_king_all();
pub const knight_moves = get_moves_knight_all();
pub const slides = get_moves_slide();

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
) [8][256][256]u8 {
    @setEvalBranchQuota(10_000_000);
    var moves: [8][256][256]u8 = undefined;
    for (0..8) |_index| {
        const index: u3 = @intCast(_index);
        for (0..256) |_own| {
            const own: u8 = @intCast(_own);
            for (0..256) |_opp| {
                const opp: u8 = @intCast(_opp);
                var result: u8 = 0;
                set_bit(&result, index);
                for (index..8) |_rindex| {
                    const rindex: u3 = @intCast(_rindex);
                    if (index == rindex) continue;
                    if (get_bit(own, rindex) == 1) break;
                    if (get_bit(opp, rindex) == 1) {
                        set_bit(&result, rindex);
                        break;
                    }
                    set_bit(&result, rindex);
                }
                for (0..index) |_rindex| {
                    const rindex: u3 = @intCast(index-1 - _rindex);
                    if (get_bit(own, rindex) == 1) break;
                    if (get_bit(opp, rindex) == 1) {
                        set_bit(&result, rindex);
                        break;
                    }
                    set_bit(&result, rindex);
                }
                moves[index][own][opp] = result;
            }
        }
    }
    return moves;
}
