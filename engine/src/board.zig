const std = @import("std");
const print = std.debug.print;
const BoardMask = @import("boardmask.zig").BoardMask;
const tables = @import("tables.zig");
const terminal = @import("terminal.zig");
const Pos = @import("pos.zig").Pos;
const Move = @import("pos.zig").Move;
const MoveList = @import("pos.zig").MoveList;
const MoveAndScore = @import("pos.zig").MoveAndScore;
const HashList = @import("hashlist.zig").HashList;

pub const Player = enum {
    PLAYER1,
    PLAYER2,
};

pub const Piece = enum {
    NONE,
    PAWN1, ROOK1, KNIG1, BISH1, QUEN1, KING1,
    PAWN2, ROOK2, KNIG2, BISH2, QUEN2, KING2,
};

pub const PieceValue = enum(i16) {
    PAWN =     100,
    KNIGHT =   350,
    BISHOP =   400,
    ROOK =     600,
    QUEEN =   1100,
};

pub const Board = struct {
    hash: u64 = 0,
    hashlist: HashList = HashList{},
    turn: Player = Player.PLAYER1,
    n_pieces: u8 = 32,
    heat: u4 = 3,
    p1_king_moved: bool = false,
    p2_king_moved: bool = false,
    p1_rook_short_moved: bool = false,
    p2_rook_short_moved: bool = false,
    p1_rook_long_moved: bool = false,
    p2_rook_long_moved: bool = false,
    p1_castled: bool = false,
    p2_castled: bool = false,
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
        board.start();
        return board;
    }

    pub fn load_from_string(
        self: *Board,
        str: *const [64]u8,
    ) void {
        self.reset();
        for(0..64) |i| {
            const pos = Pos.from_int(@intCast(i)).reverse();
            const char = str[i];
            const piece = switch(char) {
                'p' => Piece.PAWN1,
                'r' => Piece.ROOK1,
                'n' => Piece.KNIG1,
                'b' => Piece.BISH1,
                'q' => Piece.QUEN1,
                'k' => Piece.KING1,
                'P' => Piece.PAWN2,
                'R' => Piece.ROOK2,
                'N' => Piece.KNIG2,
                'B' => Piece.BISH2,
                'Q' => Piece.QUEN2,
                'K' => Piece.KING2,
                else => Piece.NONE,
            };
            self.add(pos, piece);
        }
        self.update_n_pieces();
        self.generate_hash();
    }

    pub fn save_to_string(
        self: *Board,
    ) [64]u8 {
        var str: [64]u8 = undefined;
        for(0..64) |i| {
            const pos = Pos.from_int(@intCast(i)).reverse();
            const piece = self.get(pos);
            str[i] = switch(piece) {
                Piece.PAWN1 => 'p',
                Piece.ROOK1 => 'r',
                Piece.KNIG1 => 'n',
                Piece.BISH1 => 'b',
                Piece.QUEN1 => 'q',
                Piece.KING1 => 'k',
                Piece.PAWN2 => 'P',
                Piece.ROOK2 => 'R',
                Piece.KNIG2 => 'N',
                Piece.BISH2 => 'B',
                Piece.QUEN2 => 'Q',
                Piece.KING2 => 'K',
                Piece.NONE  => '-',
            };
        }
        return str;
    }

    pub fn clone(
        self: *Board,
    ) Board {
        const board = Board{
            .hash = self.hash,
            .hashlist = self.hashlist,
            .turn = self.turn,
            .n_pieces = self.n_pieces,
            .heat = self.heat,
            .p1_pawns = self.p1_pawns,
            .p1_rooks = self.p1_rooks,
            .p1_knigs = self.p1_knigs,
            .p1_bishs = self.p1_bishs,
            .p1_quens = self.p1_quens,
            .p1_kings = self.p1_kings,
            .p2_pawns = self.p2_pawns,
            .p2_rooks = self.p2_rooks,
            .p2_knigs = self.p2_knigs,
            .p2_bishs = self.p2_bishs,
            .p2_quens = self.p2_quens,
            .p2_kings = self.p2_kings,
            .p1_king_moved = self.p1_king_moved,
            .p2_king_moved = self.p2_king_moved,
            .p1_rook_short_moved = self.p1_rook_short_moved,
            .p2_rook_short_moved = self.p2_rook_short_moved,
            .p1_rook_long_moved = self.p1_rook_long_moved,
            .p2_rook_long_moved = self.p2_rook_long_moved,
            .p1_castled = self.p1_castled,
            .p2_castled = self.p2_castled,
        };
        return board;
    }

    pub fn reset(
        self: *Board,
    ) void {
        self.turn = Player.PLAYER1;
        self.n_pieces = 32;
        self.heat=self.heat;
        self.p1_pawns = BoardMask{};
        self.p1_rooks = BoardMask{};
        self.p1_knigs = BoardMask{};
        self.p1_bishs = BoardMask{};
        self.p1_quens = BoardMask{};
        self.p1_kings = BoardMask{};
        self.p2_pawns = BoardMask{};
        self.p2_rooks = BoardMask{};
        self.p2_knigs = BoardMask{};
        self.p2_bishs = BoardMask{};
        self.p2_quens = BoardMask{};
        self.p2_kings = BoardMask{};
    }

    pub fn start(
        self: *Board,
    ) void {
        self.load_from_string(
            "RNBQKBNR" ++
            "PPPPPPPP" ++
            "--------" ++
            "--------" ++
            "--------" ++
            "--------" ++
            "pppppppp" ++
            "rnbqkbnr"
        );
    }

    pub fn setup(
        self: *Board,
    ) void {
        self.load_from_string(
            "R--Q-R--" ++
            "PP---P--" ++
            "--N----K" ++
            "--Pb-qP-" ++
            "------pP" ++
            "p---p---" ++
            "-p-b---p" ++
            "-----rk-"
        );
    }

    // pub fn setup(
    //     self: *Board,
    // ) void {
    //     self.load_from_string(
    //         "RNB-KBNR" ++
    //         "P-P-PPPP" ++
    //         "--------" ++
    //         "-nQp----" ++
    //         "q-P-----" ++
    //         "----p---" ++
    //         "pp---ppp" ++
    //         "r-b-kbnr"
    //     );
    // }

    // pub fn setup(
    //     self: *Board,
    // ) void {
    //     self.load_from_string(
    //         "R--QKBHR" ++
    //         "P-P-P-PP" ++
    //         "--------" ++
    //         "qh--h---" ++
    //         "--BpP---" ++
    //         "--------" ++
    //         "pp---ppp" ++
    //         "H-bk---r"
    //     );
    // }

    // pub fn setup(
    //     self: *Board,
    // ) void {
    //     self.load_from_string(
    //         "----K--R" ++
    //         "R--Q--P-" ++
    //         "Pb-B-H--" ++
    //         "--P-P--P" ++
    //         "--pPBP--" ++
    //         "-p---h-p" ++
    //         "pk-qppp-" ++
    //         "---r-b-r"
    //     );
    //     self.update_n_pieces();
    // }

    pub fn update_n_pieces(
        self: *Board,
    ) void {
        var mask = self.get_all_mask();
        self.n_pieces = mask.count();
    }

    pub fn get(
        self: *Board,
        pos: Pos,
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
        pos: Pos,
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
            Piece.NONE => {},
        }
        if (piece != Piece.NONE) {
            const diff = tables.piece_hash[@intFromEnum(piece)][pos.index];
            self.hash ^= diff;
        }
    }

    pub fn remove(
        self: *Board,
        pos: Pos,
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
        if (piece != Piece.NONE) {
            const diff = tables.piece_hash[@intFromEnum(piece)][pos.index];
            self.hash ^= diff;
        }
    }

    pub fn move_to(
        self: *Board,
        move: Move,
    ) void {
        const piece = self.get(move.orig);
        var opp_mask = self.get_opp_mask();
        // Is hot.
        const captured = opp_mask.has(move.dest);
        if (captured) self.n_pieces -= 1;
        const pawn_walk = self.n_pieces < 12 and (piece==Piece.PAWN1 or piece==Piece.PAWN2);
        // const is_king = (piece == Piece.KING1) or (piece == Piece.KING2);
        const is_hot = captured or pawn_walk or self.is_check_on_opp();
        if (!is_hot and self.heat > 0) self.heat -= 1;
        if (is_hot and self.heat < 3) self.heat += 1;
        // Castling status.
        if (piece == Piece.KING1) self.p1_king_moved = true;
        if (piece == Piece.KING2) self.p2_king_moved = true;
        if (piece == Piece.ROOK1 and move.orig.index == 0) self.p1_rook_short_moved = true;
        if (piece == Piece.ROOK1 and move.orig.index == 7) self.p1_rook_long_moved = true;
        if (piece == Piece.ROOK2 and move.orig.index == 56) self.p2_rook_short_moved = true;
        if (piece == Piece.ROOK2 and move.orig.index == 63) self.p2_rook_long_moved = true;
        // Casting process.
        if (piece == Piece.KING1 and move.orig.index==3 and move.dest.index == 1) {
            self.remove(Pos.from_int(0));
            self.add(Pos.from_int(2), Piece.ROOK1);
            self.p1_castled = true;
        }
        if (piece == Piece.KING1 and move.orig.index==3 and move.dest.index == 5) {
            self.remove(Pos.from_int(7));
            self.add(Pos.from_int(4), Piece.ROOK1);
            self.p1_castled = true;
        }
        if (piece == Piece.KING2 and move.orig.index==59 and move.dest.index == 57) {
            self.remove(Pos.from_int(56));
            self.add(Pos.from_int(58), Piece.ROOK2);
            self.p2_castled = true;
        }
        if (piece == Piece.KING2 and move.orig.index==59 and move.dest.index == 61) {
            self.remove(Pos.from_int(63));
            self.add(Pos.from_int(60), Piece.ROOK2);
            self.p2_castled = true;
        }
        // Piece exchange.
        self.remove(move.orig);
        self.remove(move.dest);
        self.add(move.dest, piece);
        if (piece == Piece.PAWN1 and move.dest.row() == 7) {
            self.remove(move.dest);
            self.add(move.dest, Piece.QUEN1);
        }
        if (piece == Piece.PAWN2 and move.dest.row() == 0) {
            self.remove(move.dest);
            self.add(move.dest, Piece.QUEN2);
        }
        // After move.
        self.switch_turn();
        self.hashlist.put(self.hash);
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

    pub fn get_own_mask(
        self: *Board,
    ) BoardMask {
        if (self.turn == Player.PLAYER1) return self.get_p1_mask();
        return self.get_p2_mask();
    }

    pub fn get_opp_mask(
        self: *Board,
    ) BoardMask {
        if (self.turn == Player.PLAYER1) return self.get_p2_mask();
        return self.get_p1_mask();
    }

    pub fn get_all_mask(
        self: *Board,
    ) BoardMask {
        const mask = self.get_p1_mask().mask | self.get_p2_mask().mask;
        return BoardMask{.mask=mask};
    }

    pub fn get_moves_for_pos(
        self: *Board,
        pos: Pos,
    ) BoardMask {
        const piece = self.get(pos);
        switch (piece) {
            Piece.PAWN1 => return self.get_moves_pawn(pos, false),
            Piece.PAWN2 => return self.get_moves_pawn(pos, true),
            Piece.KNIG1 => return self.get_moves_knight(pos, false),
            Piece.KNIG2 => return self.get_moves_knight(pos, true),
            Piece.ROOK1 => return self.get_moves_rook(pos, false),
            Piece.ROOK2 => return self.get_moves_rook(pos, true),
            Piece.BISH1 => return self.get_moves_bishop(pos, false),
            Piece.BISH2 => return self.get_moves_bishop(pos, true),
            Piece.QUEN1 => return self.get_moves_queen(pos, false),
            Piece.QUEN2 => return self.get_moves_queen(pos, true),
            Piece.KING1 => return self.get_moves_king(pos, false, true),
            Piece.KING2 => return self.get_moves_king(pos, true, true),
            Piece.NONE => return BoardMask{},
        }
    }

    pub fn get_moves_pawn(
        self: *Board,
        pos: Pos,
        flip: bool,
    ) BoardMask {
        // Advance.
        const advance_table = if (flip) tables.pawn_moves_p2 else tables.pawn_moves_p1;
        var moves = advance_table[pos.index];
        var all_mask = self.get_all_mask();
        all_mask.remove(pos);
        var all_mask_shadow = (
            if (flip) BoardMask{.mask=((all_mask.mask << 16 ) >> 24)}
            else BoardMask{.mask=((all_mask.mask >> 16 ) << 24)}
        );
        all_mask.add_mask(&all_mask_shadow);  // Prevent jump on double move.
        moves.remove_mask(&all_mask);
        // Capture.
        const capture_table = if (flip) tables.pawn_captures_p2 else tables.pawn_captures_p1;
        var captures = capture_table[pos.index];
        var opp_mask = if (flip) self.get_p1_mask() else self.get_p2_mask();
        captures.intersect_mask(&opp_mask);
        moves.add_mask(&captures);
        // Result.
        return moves;
    }

    pub fn get_moves_king(
        self: *Board,
        pos: Pos,
        flip: bool,
        castle: bool,
    ) BoardMask {
        var moves = tables.king_moves[pos.index];
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        moves.remove_mask(&own_mask);
        // Castling.
        const p1 = self.turn == Player.PLAYER1;
        if (castle) {
            if (p1) {
                if (self.can_castle(false, false)) moves.add(Pos.from_int(1)); // Short.
                if (self.can_castle(false, true)) moves.add(Pos.from_int(5));  // Long.
            } else {
                if (self.can_castle(true, false)) moves.add(Pos.from_int(57)); // Short.
                if (self.can_castle(true, true)) moves.add(Pos.from_int(61));  // Long.
            }
        }
        return moves;
    }

    pub fn get_moves_knight(
        self: *Board,
        pos: Pos,
        flip: bool,
    ) BoardMask {
        var moves = tables.knight_moves[pos.index];
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        moves.remove_mask(&own_mask);
        return moves;
    }

    pub fn get_moves_rook(
        self: *Board,
        pos: Pos,
        flip: bool,
    ) BoardMask {
        var moves = BoardMask{};
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        var opp_mask = if (flip) self.get_p1_mask() else self.get_p2_mask();
        const row: u3 = pos.row();
        const col: u3 = pos.col();
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

    pub fn get_moves_bishop(
        self: *Board,
        pos: Pos,
        flip: bool,
    ) BoardMask {
        const row: u3 = pos.row();
        const col: u3 = pos.col();
        var moves = BoardMask{};
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        var opp_mask = if (flip) self.get_p1_mask() else self.get_p2_mask();
        // Diagonal down.
        const line_sink = tables.line_sink[pos.index];
        const own_sink = own_mask.get_line(line_sink);
        const opp_sink = opp_mask.get_line(line_sink);
        const all_sink = own_sink | opp_sink;
        const index_sink = @min(row, col);
        var moves_sink = tables.slides[index_sink][all_sink];
        moves_sink &= ~own_sink;
        moves.set_line(line_sink, moves_sink);
        // Diagonal up.
        const line_rise = tables.line_rise[pos.index];
        const own_rise = own_mask.get_line(line_rise);
        const opp_rise = opp_mask.get_line(line_rise);
        const all_rise = own_rise | opp_rise;
        const index_rise = @min(row, 7-col);
        var moves_rise = tables.slides[index_rise][all_rise];
        moves_rise &= ~own_rise;
        moves.set_line(line_rise, moves_rise);
        // Return.
        return moves;
    }

    pub fn get_moves_queen(
        self: *Board,
        pos: Pos,
        flip: bool,
    ) BoardMask {
        const cardinal = self.get_moves_rook(pos, flip);
        const diagonal = self.get_moves_bishop(pos, flip);
        return BoardMask{.mask=cardinal.mask | diagonal.mask};
    }

    pub fn get_legal_moves(
        self: *Board,
    ) MoveList {
        var movelist = MoveList{};
        var own_mask = self.get_own_mask();
        for(0..own_mask.count()) |_| {
            const orig = own_mask.next();
            var moves = self.get_moves_for_pos(orig);
            for(0..moves.count()) |_| {
                const dest = moves.next();
                var move = Move{.orig=orig, .dest=dest};
                // Exclude moves exposing own king.
                var fork = self.fork_with_move(move);
                if (fork.is_check_on_opp()) continue;
                // const is_check_move = fork.is_check_on_own();
                // Capture score.
                const piece_dest = self.get(move.dest);
                if (piece_dest != Piece.NONE) {
                    const piece_orig = self.get(move.orig);
                    move.capture_score = tables.capture_score[@intFromEnum(piece_orig)][@intFromEnum(piece_dest)];
                    // if (is_check_move) move.capture_score += 10;
                }
                movelist.add(move);
            }
        }
        return movelist;
    }

    pub fn can_castle(
        self: *Board,
        p2: bool,
        long: bool,
    ) bool {
        if (!p2) {
            if (!long) {
                return (
                    // P1 short.
                    !self.p1_king_moved and
                    !self.p1_rook_short_moved and
                    self.get(Pos.from_int(0)) == Piece.ROOK1 and
                    self.get(Pos.from_int(1)) == Piece.NONE and
                    self.get(Pos.from_int(2)) == Piece.NONE and
                    self.get(Pos.from_int(3)) == Piece.KING1 and
                    !self.is_attacked(Pos.from_int(1), false) and
                    !self.is_attacked(Pos.from_int(2), false) and
                    !self.is_attacked(Pos.from_int(3), false)
                );
            } else {
                return (
                    // P1 long.
                    !self.p1_king_moved and
                    !self.p1_rook_long_moved and
                    self.get(Pos.from_int(3)) == Piece.KING1 and
                    self.get(Pos.from_int(4)) == Piece.NONE and
                    self.get(Pos.from_int(5)) == Piece.NONE and
                    self.get(Pos.from_int(6)) == Piece.NONE and
                    self.get(Pos.from_int(7)) == Piece.ROOK1 and
                    !self.is_attacked(Pos.from_int(3), false) and
                    !self.is_attacked(Pos.from_int(4), false) and
                    !self.is_attacked(Pos.from_int(5), false)
                );
            }
        } else {
            if (!long) {
                return (
                    // P2 short.
                    !self.p2_king_moved and
                    !self.p2_rook_short_moved and
                    self.get(Pos.from_int(56)) == Piece.ROOK2 and
                    self.get(Pos.from_int(57)) == Piece.NONE and
                    self.get(Pos.from_int(58)) == Piece.NONE and
                    self.get(Pos.from_int(59)) == Piece.KING2 and
                    !self.is_attacked(Pos.from_int(57), true) and
                    !self.is_attacked(Pos.from_int(58), true) and
                    !self.is_attacked(Pos.from_int(59), true)
                );
            } else {
                return (
                    // P2 long.
                    !self.p2_king_moved and
                    !self.p2_rook_long_moved and
                    self.get(Pos.from_int(59)) == Piece.KING2 and
                    self.get(Pos.from_int(60)) == Piece.NONE and
                    self.get(Pos.from_int(61)) == Piece.NONE and
                    self.get(Pos.from_int(62)) == Piece.NONE and
                    self.get(Pos.from_int(63)) == Piece.ROOK2 and
                    !self.is_attacked(Pos.from_int(59), true) and
                    !self.is_attacked(Pos.from_int(60), true) and
                    !self.is_attacked(Pos.from_int(61), true)
                );
            }
        }
    }

    pub fn fork_with_move(
        self: *Board,
        move: Move,
    ) Board {
        var board = self.clone();
        board.move_to(move);
        return board;
    }

    pub fn switch_turn(
        self: *Board,
    ) void {
        self.turn = (
            if (self.turn == Player.PLAYER1) Player.PLAYER2
            else Player.PLAYER1
        );
    }

    pub fn is_attacked(
        self: *Board,
        pos: Pos,
        p2: bool,
    ) bool {
        // Attacked by knight.
        const moves_h = tables.knight_moves[pos.index];
        const location_h = if (p2) self.p1_knigs else self.p2_knigs;
        if (moves_h.mask & location_h.mask > 0) return true;
        // Attacked by queen.
        const moves_q = self.get_moves_queen(pos, p2);
        const location_q = if (p2) self.p1_quens else self.p2_quens;
        if (moves_q.mask & location_q.mask > 0) return true;
        // Attacked by bishop.
        const moves_b = self.get_moves_bishop(pos, p2);
        const location_b = if (p2) self.p1_bishs else self.p2_bishs;
        if (moves_b.mask & location_b.mask > 0) return true;
        // Attacked by rook.
        const moves_r = self.get_moves_rook(pos, p2);
        const location_r = if (p2) self.p1_rooks else self.p2_rooks;
        if (moves_r.mask & location_r.mask > 0) return true;
        // Attacked by pawn.
        const moves_p = (
            if (p2) tables.pawn_captures_p2[pos.index]
            else tables.pawn_captures_p1[pos.index]
        );
        const location_p = if (p2) self.p1_pawns else self.p2_pawns;
        if (moves_p.mask & location_p.mask > 0) return true;
        // Attacked by king.
        const moves_k = self.get_moves_king(pos, p2, false);
        const location_k = if (p2) self.p1_kings else self.p2_kings;
        if (moves_k.mask & location_k.mask > 0) return true;
        // Not attacked.
        return false;
    }

    pub fn is_check(
        self: *Board,
        p2: bool,
    ) bool {
        const king_pos = self.get_king_pos(p2);
        return self.is_attacked(king_pos, p2);
    }

    pub fn is_check_on_own(
        self: *Board,
    ) bool {
        const p2 = self.turn == Player.PLAYER2;
        return self.is_check(p2);
    }

    pub fn is_check_on_opp(
        self: *Board,
    ) bool {
        const p2 = self.turn == Player.PLAYER2;
        return self.is_check(!p2);
    }

    pub fn get_king_pos(
        self: *Board,
        p2: bool,
    ) Pos {
        const mask = if (p2) self.p2_kings else self.p1_kings;
        const index: u6 = @truncate(@ctz(mask.mask));
        return Pos{.index=index};
    }

    pub fn get_score(
        self: *Board,
    ) i16 {
        var score: i16 = 0;
        // Piece value + position.
        for (0..64) |index| {
            const pos = Pos.from_int(@intCast(index));
            const piece = self.get(pos);
            switch (piece) {
                Piece.NONE => {},
                Piece.PAWN1 => score += @intFromEnum(PieceValue.PAWN)   + tables.pawn_score[pos.reverse().index],
                Piece.KNIG1 => score += @intFromEnum(PieceValue.KNIGHT) + tables.piece_score[pos.reverse().index],
                Piece.BISH1 => score += @intFromEnum(PieceValue.BISHOP) + tables.piece_score[pos.reverse().index],
                Piece.ROOK1 => score += @intFromEnum(PieceValue.ROOK)   + tables.piece_score[pos.reverse().index],
                Piece.QUEN1 => score += @intFromEnum(PieceValue.QUEEN)  + tables.piece_score[pos.reverse().index],
                Piece.KING1 => {},
                Piece.PAWN2 => score -= @intFromEnum(PieceValue.PAWN)   + tables.pawn_score[pos.index],
                Piece.KNIG2 => score -= @intFromEnum(PieceValue.KNIGHT) + tables.piece_score[pos.index],
                Piece.BISH2 => score -= @intFromEnum(PieceValue.BISHOP) + tables.piece_score[pos.index],
                Piece.ROOK2 => score -= @intFromEnum(PieceValue.ROOK)   + tables.piece_score[pos.index],
                Piece.QUEN2 => score -= @intFromEnum(PieceValue.QUEEN)  + tables.piece_score[pos.index],
                Piece.KING2 => {},
            }
        }
        // Pawn defense.
        for (0..self.p1_pawns.count()) |_| {
            const pawn_pos = self.p1_pawns.next();
            const pawn_back = tables.pawn_defense[pawn_pos.index];
            score += 25 * @popCount(self.p1_pawns.mask & pawn_back);
        }
        for (0..self.p2_pawns.count()) |_| {
            const pawn_pos = self.p2_pawns.next();
            const pawn_back = tables.pawn_defense[pawn_pos.reverse().index];
            score -= 25 * @popCount(self.p2_pawns.mask & pawn_back);
        }
        // Castling potential,
        if (!self.p1_king_moved and !self.p1_rook_short_moved) score += 50;
        if (!self.p1_king_moved and !self.p1_rook_long_moved) score += 50;
        if (!self.p2_king_moved and !self.p2_rook_short_moved) score -= 50;
        if (!self.p2_king_moved and !self.p2_rook_long_moved) score -= 50;
        if (self.p1_castled) score += 200;
        if (self.p2_castled) score -= 200;
        // Result.
        return score;
    }

    pub fn generate_hash(
        self: *Board,
    ) void {
        self.hash = 0;
        for (0..64) |index| {
            const pos = Pos.from_int(@intCast(index));
            const piece = self.get(pos);
            if (piece == Piece.NONE) continue;
            self.hash ^= tables.piece_hash[@intFromEnum(piece)][pos.index];
        }
        self.hashlist.put(self.hash);
    }

    pub fn count_legal_moves(
        self: *Board,
        // TODO: Depth parameter.
    ) u16 {
        var total: u16 = 0;
        const legal = self.get_legal_moves();
        for (0..legal.len) |i| {
            const move = legal.data[i];
            var subboard = self.fork_with_move(move);
            total += subboard.get_legal_moves().len;
        }
        return total;
    }
};


