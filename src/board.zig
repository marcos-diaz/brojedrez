const std = @import("std");
const BoardMask = @import("boardmask.zig").BoardMask;
const tables = @import("tables.zig");
const terminal = @import("terminal.zig");

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
    turn: Player = Player.PLAYER1,
    p1_pawns: BoardMask = BoardMask{},
    p1_rooks: BoardMask = BoardMask{},
    p1_knigs: BoardMask = BoardMask{},
    p1_bishs: BoardMask = BoardMask{},
    p1_quens: BoardMask = BoardMask{},
    p1_kings: BoardMask = BoardMask{},
    p2_pawns: BoardMask = BoardMask{},
    p2_rooks: BoardMask = BoardMask{},
    p2_knigs: BoardMask = BoardMask{},
    p2_bishs: BoardMask = BoardMask{},
    p2_quens: BoardMask = BoardMask{},
    p2_kings: BoardMask = BoardMask{},

    pub fn init() Board {
        var board = Board{};
        board.reset();
        return board;
    }

    pub fn reset(
        self: *Board,
    ) void {
        self.turn = Player.PLAYER1;
        self.p1_pawns = BoardMask{.mask=0b11111111 << 8};
        self.p1_rooks = BoardMask{.mask=0b10000001};
        self.p1_knigs = BoardMask{.mask=0b01000010};
        self.p1_bishs = BoardMask{.mask=0b00100100};
        self.p1_quens = BoardMask{.mask=0b00010000};
        self.p1_kings = BoardMask{.mask=0b00001000};
        self.p2_pawns = BoardMask{.mask=0b11111111 << 48};
        self.p2_rooks = BoardMask{.mask=0b10000001 << 56};
        self.p2_knigs = BoardMask{.mask=0b01000010 << 56};
        self.p2_bishs = BoardMask{.mask=0b00100100 << 56};
        self.p2_quens = BoardMask{.mask=0b00010000 << 56};
        self.p2_kings = BoardMask{.mask=0b00001000 << 56};
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

    pub fn get_p2_mask(
        self: *Board,
    ) BoardMask {
        const mask = (
            self.p2_pawns.mask |
            self.p2_rooks.mask |
            self.p2_knigs.mask |
            self.p2_bishs.mask |
            self.p2_quens.mask |
            self.p2_kings.mask
        );
        return BoardMask{.mask=mask};
    }

    pub fn get_legal_moves(
        self: *Board,
        pos: u6,
    ) BoardMask {
        const piece = self.get(pos);
        switch (piece) {
            Piece.PAWN1 => return self.get_legal_moves_pawn(pos, false),
            Piece.PAWN2 => return self.get_legal_moves_pawn(pos, true),
            Piece.KING1 => return self.get_legal_moves_king(pos, false),
            Piece.KING2 => return self.get_legal_moves_king(pos, true),
            Piece.KNIG1 => return self.get_legal_moves_knight(pos, false),
            Piece.KNIG2 => return self.get_legal_moves_knight(pos, true),
            Piece.ROOK1 => return self.get_legal_moves_rook(pos, false),
            Piece.ROOK2 => return self.get_legal_moves_rook(pos, true),
            Piece.BISH1 => return self.get_legal_moves_bishop(pos, false),
            Piece.BISH2 => return self.get_legal_moves_bishop(pos, true),
            Piece.NONE => return BoardMask{},
            else => unreachable,
        }
    }

    pub fn get_legal_moves_pawn(
        self: *Board,
        pos: u6,
        flip: bool,
    ) BoardMask {
        const move_table = if (flip) tables.pawn_moves_p2 else tables.pawn_moves_p1;
        var moves = move_table[pos];
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        moves.remove_mask(&own_mask);
        return moves;
    }

    pub fn get_legal_moves_king(
        self: *Board,
        pos: u6,
        flip: bool,
    ) BoardMask {
        var moves = tables.king_moves[pos];
        terminal.print_boardmask(&moves);
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        moves.remove_mask(&own_mask);
        return moves;
    }

    pub fn get_legal_moves_knight(
        self: *Board,
        pos: u6,
        flip: bool,
    ) BoardMask {
        var moves = tables.knight_moves[pos];
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        moves.remove_mask(&own_mask);
        return moves;
    }

    pub fn get_legal_moves_rook(
        self: *Board,
        pos: u6,
        flip: bool,
    ) BoardMask {
        var moves = BoardMask{};
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        var opp_mask = if (flip) self.get_p1_mask() else self.get_p2_mask();
        const row: u3 = @intCast(pos / 8);
        const col: u3 = @intCast(pos % 8);
        const own_row = own_mask.get_row(row);
        const opp_row = opp_mask.get_row(row);
        const own_col = own_mask.get_col(col);
        const opp_col = opp_mask.get_col(col);
        const all_row = own_row | opp_row;
        const all_col = own_col | opp_col;
        var row_moves = tables.slides[col][all_row];
        var col_moves = tables.slides[row][all_col];
        row_moves &= ~own_row;
        col_moves &= ~own_col;
        moves.set_row(row, row_moves);
        moves.set_col(col, col_moves);
        return moves;
    }

    pub fn get_legal_moves_bishop(
        self: *Board,
        pos: u6,
        flip: bool,
    ) BoardMask {
        const row: u3 = @intCast(pos / 8);
        const col: u3 = @intCast(pos % 8);
        var moves = BoardMask{};
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        var opp_mask = if (flip) self.get_p1_mask() else self.get_p2_mask();
        // Diagonal down.
        const list_down = tables.diagonal_down_pos[pos];
        const own_diagonal_down = own_mask.get_from_pos_list(list_down);
        const opp_diagonal_down = opp_mask.get_from_pos_list(list_down);
        const all_diagonal_down = own_diagonal_down | opp_diagonal_down;
        const index_down = @min(row, col);
        var diagonal_down_moves = tables.slides[index_down][all_diagonal_down];
        diagonal_down_moves &= ~own_diagonal_down;
        moves.set_from_pos_list(list_down, diagonal_down_moves);
        // Diagonal up.
        const list_up = tables.diagonal_up_pos[pos];
        const own_diagonal_up = own_mask.get_from_pos_list(list_up);
        const opp_diagonal_up = opp_mask.get_from_pos_list(list_up);
        const all_diagonal_up = own_diagonal_up | opp_diagonal_up;
        const index_up = @min(row, 7-col);
        var diagonal_up_moves = tables.slides[index_up][all_diagonal_up];
        diagonal_up_moves &= ~own_diagonal_up;
        moves.set_from_pos_list(list_up, diagonal_up_moves);
        // Return.
        return moves;
    }
};
