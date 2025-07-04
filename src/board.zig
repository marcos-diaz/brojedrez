const std = @import("std");
const term = @import("common.zig").term;

const stdout = std.io.getStdOut().writer();

const Player = enum {
    PLAYER1,
    PLAYER2,
};

const Piece = enum {
    NONE,
    PAWN1, ROOK1, KNIG1, BISH1, QUEN1, KING1,
    PAWN2, ROOK2, KNIG2, BISH2, QUEN2, KING2,
};

const PieceSet = struct {
    mask: u64,

    fn hasPos(
        self: *const PieceSet,
        pos: u64
    ) bool {
        return (((self.mask >> @intCast(pos)) & 1) != 0);
    }
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

    pub fn getPieceAtPos(
        self: *const Board,
        pos: u8
    ) Piece {
        if (self.p1_pawns.hasPos(pos)) return Piece.PAWN1;
        if (self.p1_rooks.hasPos(pos)) return Piece.ROOK1;
        if (self.p1_knigs.hasPos(pos)) return Piece.KNIG1;
        if (self.p1_bishs.hasPos(pos)) return Piece.BISH1;
        if (self.p1_quens.hasPos(pos)) return Piece.QUEN1;
        if (self.p1_kings.hasPos(pos)) return Piece.KING1;
        if (self.p2_pawns.hasPos(pos)) return Piece.PAWN2;
        if (self.p2_rooks.hasPos(pos)) return Piece.ROOK2;
        if (self.p2_knigs.hasPos(pos)) return Piece.KNIG2;
        if (self.p2_bishs.hasPos(pos)) return Piece.BISH2;
        if (self.p2_quens.hasPos(pos)) return Piece.QUEN2;
        if (self.p2_kings.hasPos(pos)) return Piece.KING2;
        return Piece.NONE;
    }

    pub fn displayClear(
        self: *const Board
    ) !void {
        _ = self;
        try stdout.writeAll(term.clear);
    }

    pub fn display(
        self: *const Board
    ) void {
        std.debug.print("\n    A B C D E F G H\n\n", .{});
        for (0..8) |row| {
            std.debug.print("{d}   ", .{8-row});
            for (0..8) |col| {
                const pos: u8 = @intCast((row * 8) + col);
                const piece = self.getPieceAtPos(63 - pos);
                switch (piece) {
                    Piece.NONE  => std.debug.print("{s}- {s}", .{term.grey, term.reset}),
                    Piece.PAWN1 => std.debug.print("{s}o {s}", .{term.blue, term.reset}),
                    Piece.ROOK1 => std.debug.print("{s}+ {s}", .{term.blue, term.reset}),
                    Piece.KNIG1 => std.debug.print("{s}L {s}", .{term.blue, term.reset}),
                    Piece.BISH1 => std.debug.print("{s}x {s}", .{term.blue, term.reset}),
                    Piece.QUEN1 => std.debug.print("{s}Q {s}", .{term.blue2, term.reset}),
                    Piece.KING1 => std.debug.print("{s}K {s}", .{term.blue2, term.reset}),
                    Piece.PAWN2 => std.debug.print("{s}o {s}", .{term.red, term.reset}),
                    Piece.ROOK2 => std.debug.print("{s}+ {s}", .{term.red, term.reset}),
                    Piece.KNIG2 => std.debug.print("{s}L {s}", .{term.red, term.reset}),
                    Piece.BISH2 => std.debug.print("{s}x {s}", .{term.red, term.reset}),
                    Piece.QUEN2 => std.debug.print("{s}Q {s}", .{term.red2, term.reset}),
                    Piece.KING2 => std.debug.print("{s}K {s}", .{term.red2, term.reset}),
                }
            }
            std.debug.print("  {d}", .{8-row});
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
        std.debug.print("    A B C D E F G H\n\n", .{});
    }
};
