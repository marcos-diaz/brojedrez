const std = @import("std");
const Piece = @import("piece.zig").Piece;
const PieceSet = @import("piece.zig").PieceSet;

const stdout = std.io.getStdOut().writer();

const Player = enum {
    PLAYER1,
    PLAYER2,
};

pub const Board = struct {
    turn: Player,
    p1_pawns: PieceSet,
    p1_rooks: PieceSet,
    p1_knigs: PieceSet,
    p1_bishs: PieceSet,
    p1_quens: PieceSet,
    p1_kings: PieceSet,
    p2_pawns: PieceSet,
    p2_rooks: PieceSet,
    p2_knigs: PieceSet,
    p2_bishs: PieceSet,
    p2_quens: PieceSet,
    p2_kings: PieceSet,

    pub fn init() Board {
        return Board{
            .turn = Player.PLAYER1,
            .p1_pawns = PieceSet{.mask=0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000},
            .p1_rooks = PieceSet{.mask=0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000001},
            .p1_knigs = PieceSet{.mask=0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000010},
            .p1_bishs = PieceSet{.mask=0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00100100},
            .p1_quens = PieceSet{.mask=0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00010000},
            .p1_kings = PieceSet{.mask=0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001000},
            .p2_pawns = PieceSet{.mask=0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000},
            .p2_rooks = PieceSet{.mask=0b10000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000},
            .p2_knigs = PieceSet{.mask=0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000},
            .p2_bishs = PieceSet{.mask=0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_00000000},
            .p2_quens = PieceSet{.mask=0b00010000_00000000_00000000_00000000_00000000_00000000_00000000_00000000},
            .p2_kings = PieceSet{.mask=0b00001000_00000000_00000000_00000000_00000000_00000000_00000000_00000000},
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

    pub fn remove(
        self: *Board,
        pos: u6,
    ) void {
        if (self.p1_pawns.has(pos)) return self.p1_pawns.remove(pos);
        if (self.p1_rooks.has(pos)) return self.p1_rooks.remove(pos);
        if (self.p1_knigs.has(pos)) return self.p1_knigs.remove(pos);
        if (self.p1_bishs.has(pos)) return self.p1_bishs.remove(pos);
        if (self.p1_quens.has(pos)) return self.p1_quens.remove(pos);
        if (self.p1_kings.has(pos)) return self.p1_kings.remove(pos);
        if (self.p2_pawns.has(pos)) return self.p2_pawns.remove(pos);
        if (self.p2_rooks.has(pos)) return self.p2_rooks.remove(pos);
        if (self.p2_knigs.has(pos)) return self.p2_knigs.remove(pos);
        if (self.p2_bishs.has(pos)) return self.p2_bishs.remove(pos);
        if (self.p2_quens.has(pos)) return self.p2_quens.remove(pos);
        if (self.p2_kings.has(pos)) return self.p2_kings.remove(pos);
    }
};
