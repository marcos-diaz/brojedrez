pub const Piece = enum {
    NONE,
    PAWN1, ROOK1, KNIG1, BISH1, QUEN1, KING1,
    PAWN2, ROOK2, KNIG2, BISH2, QUEN2, KING2,
};

pub const PieceSet = struct {
    mask: u64,

    pub fn has(
        self: *PieceSet,
        pos: u6,
    ) bool {
        return (((self.mask >> pos) & 1) != 0);
    }

    pub fn remove(
        self: *PieceSet,
        pos: u6)
    void {
        const target: u64 = 1;
        self.mask &= ~(target << pos);
    }
};
