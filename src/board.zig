const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;

const Player = enum {
    PLAYER1,
    PLAYER2,
};

pub const Piece = enum {
    NONE,
    PAWN1, ROOK1, KNIG1, BISH1, QUEN1, KING1,
    PAWN2, ROOK2, KNIG2, BISH2, QUEN2, KING2,
};

pub const Board = struct {
    turn: Player,
    p1_pawns: BoardMask,
    p1_rooks: BoardMask,
    p1_knigs: BoardMask,
    p1_bishs: BoardMask,
    p1_quens: BoardMask,
    p1_kings: BoardMask,
    p2_pawns: BoardMask,
    p2_rooks: BoardMask,
    p2_knigs: BoardMask,
    p2_bishs: BoardMask,
    p2_quens: BoardMask,
    p2_kings: BoardMask,

    pub fn init() Board {
        return Board{
            .turn = Player.PLAYER1,
            .p1_pawns = BoardMask{.mask=0b11111111 << 8},
            .p1_rooks = BoardMask{.mask=0b10000001},
            .p1_knigs = BoardMask{.mask=0b01000010},
            .p1_bishs = BoardMask{.mask=0b00100100},
            .p1_quens = BoardMask{.mask=0b00010000},
            .p1_kings = BoardMask{.mask=0b00001000},
            .p2_pawns = BoardMask{.mask=0b11111111 << 48},
            .p2_rooks = BoardMask{.mask=0b10000001 << 56},
            .p2_knigs = BoardMask{.mask=0b01000010 << 56},
            .p2_bishs = BoardMask{.mask=0b00100100 << 56},
            .p2_quens = BoardMask{.mask=0b00010000 << 56},
            .p2_kings = BoardMask{.mask=0b00001000 << 56},
        };
    }

    pub fn get(
        self: *Board,
        pos: u6,
    ) Piece {
        if (self.p1_pawns.has(pos)) return Piece.PAWN1;
        if (self.p1_rooks.has(pos)) return Piece.ROOK1;
        if (self.p1_knigs.has(pos)) return Piece.KNIG1;
        if (self.p1_bishs.has(pos)) return Piece.BISH1;
        if (self.p1_quens.has(pos)) return Piece.QUEN1;
        if (self.p1_kings.has(pos)) return Piece.KING1;
        if (self.p2_pawns.has(pos)) return Piece.PAWN2;
        if (self.p2_rooks.has(pos)) return Piece.ROOK2;
        if (self.p2_knigs.has(pos)) return Piece.KNIG2;
        if (self.p2_bishs.has(pos)) return Piece.BISH2;
        if (self.p2_quens.has(pos)) return Piece.QUEN2;
        if (self.p2_kings.has(pos)) return Piece.KING2;
        return Piece.NONE;
    }

    pub fn add(
        self: *Board,
        pos: u6,
        piece: Piece,
    ) void {
        switch(piece) {
            Piece.PAWN1 => self.p1_pawns.add(pos),
            Piece.ROOK1 => self.p1_rooks.add(pos),
            Piece.KNIG1 => self.p1_knigs.add(pos),
            Piece.BISH1 => self.p1_bishs.add(pos),
            Piece.QUEN1 => self.p1_quens.add(pos),
            Piece.KING1 => self.p1_kings.add(pos),
            Piece.PAWN2 => self.p2_pawns.add(pos),
            Piece.ROOK2 => self.p2_rooks.add(pos),
            Piece.KNIG2 => self.p2_knigs.add(pos),
            Piece.BISH2 => self.p2_bishs.add(pos),
            Piece.QUEN2 => self.p2_quens.add(pos),
            Piece.KING2 => self.p2_kings.add(pos),
            Piece.NONE => return,
        }
    }

    pub fn remove(
        self: *Board,
        pos: u6,
    ) void {
        const piece = self.get(pos);
        switch (piece) {
            Piece.PAWN1 => self.p1_pawns.remove(pos),
            Piece.ROOK1 => self.p1_rooks.remove(pos),
            Piece.KNIG1 => self.p1_knigs.remove(pos),
            Piece.BISH1 => self.p1_bishs.remove(pos),
            Piece.QUEN1 => self.p1_quens.remove(pos),
            Piece.KING1 => self.p1_kings.remove(pos),
            Piece.PAWN2 => self.p2_pawns.remove(pos),
            Piece.ROOK2 => self.p2_rooks.remove(pos),
            Piece.KNIG2 => self.p2_knigs.remove(pos),
            Piece.BISH2 => self.p2_bishs.remove(pos),
            Piece.QUEN2 => self.p2_quens.remove(pos),
            Piece.KING2 => self.p2_kings.remove(pos),
            Piece.NONE => {}
        }
    }

    pub fn get_p1_mask(
        self: *Board,
    ) BoardMask {
        const mask = (
            self.p1_pawns.mask |
            self.p1_rooks.mask |
            self.p1_knigs.mask |
            self.p1_bishs.mask |
            self.p1_quens.mask |
            self.p1_kings.mask
        );
        return BoardMask{.mask=mask};
    }

    pub fn get_legal_moves(
        self: *Board,
        pos: u6,
    ) BoardMask {
        const piece = self.get(pos);
        switch (piece) {
            Piece.KNIG1 => return self.get_legal_moves_p1_knig(pos),
            else => unreachable,
        }
    }

    pub fn get_legal_moves_p1_knig(
        self: *Board,
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
        var p1mask = self.get_p1_mask();
        moves.remove_mask(&p1mask);
        return moves;
    }
};
