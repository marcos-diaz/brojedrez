const BoardMask = @import("boardmask.zig").BoardMask;

// Comptime tables.
pub const pawn_moves_p1 = get_moves_pawn_all(false);
pub const pawn_moves_p2 = get_moves_pawn_all(true);
pub const knight_moves = get_moves_knight_all();

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

fn get_moves_knight_all(
) [64]BoardMask {
    @setEvalBranchQuota(10_000);
    var moves: [64]BoardMask = undefined;
    for (0..64) |_pos| {
        const pos: u6 = @intCast(_pos);
        moves[pos] = get_moves_knight_at_pos(@intCast(pos));
    }
    return moves;
}

fn get_moves_pawn_at_pos(
    pos: u6,
    flip: bool,
) BoardMask {
    var moves = BoardMask{};
    // If block has to use 'pos' instead of 'col' so the compiler detect correct bounds.
    if (pos < 7*8) {  // Exclude last row.
        moves.add(pos + 8);
        if (pos >= 8 and pos < 16) moves.add(pos + 16);  // Double move.
    }
    if (flip) moves.flip();
    return moves;
}

fn get_moves_knight_at_pos(
    pos: u6,
) BoardMask {
    var moves = BoardMask{};
    const row: u6 = pos / 8;
    const col: u6 = pos % 8;
    for (0..64) |ipos| {
        const irow: u6 = @intCast(ipos / 8);
        const icol: u6 = @intCast(ipos % 8);
        const row_gap = if (row >= irow) (row-irow) else (irow-row);
        const col_gap = if (col >= icol) (col-icol) else (icol-col);
        if ((row_gap==2 and col_gap==1) or (row_gap==1 and col_gap==2)) {
            moves.add(@intCast(ipos));
        }
    }
    return moves;
}
