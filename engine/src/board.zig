const std = @import("std");
const print = std.debug.print;
const BoardMask = @import("boardmask.zig").BoardMask;
const tables = @import("tables.zig");
const terminal = @import("terminal.zig");
const Pos = @import("pos.zig").Pos;
const Move = @import("pos.zig").Move;
const MoveList = @import("pos.zig").MoveList;
const MoveAndScore = @import("pos.zig").MoveAndScore;

pub const Stats = struct {
    evals: [16]u32 = .{0} ** 16,
    history: MoveList = MoveList{},
};

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
    KNIGHT =   400,
    BISHOP =   500,
    ROOK =     800,
    QUEEN =   1500,
};

pub const Board = struct {
    turn: Player = Player.PLAYER1,
    n_pieces: u8 = 32,
    last_p1_move_hot: bool = false,
    last_p2_move_hot: bool = false,
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
                'h' => Piece.KNIG1,
                'b' => Piece.BISH1,
                'q' => Piece.QUEN1,
                'k' => Piece.KING1,
                'P' => Piece.PAWN2,
                'R' => Piece.ROOK2,
                'H' => Piece.KNIG2,
                'B' => Piece.BISH2,
                'Q' => Piece.QUEN2,
                'K' => Piece.KING2,
                else => Piece.NONE,
            };
            self.add(pos, piece);
        }
        self.update_n_pieces();
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
                Piece.KNIG1 => 'h',
                Piece.BISH1 => 'b',
                Piece.QUEN1 => 'q',
                Piece.KING1 => 'k',
                Piece.PAWN2 => 'P',
                Piece.ROOK2 => 'R',
                Piece.KNIG2 => 'H',
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
            .turn=self.turn,
            .n_pieces=self.n_pieces,
            .last_p1_move_hot=self.last_p1_move_hot,
            .last_p2_move_hot=self.last_p2_move_hot,
            .p1_pawns=self.p1_pawns,
            .p1_rooks=self.p1_rooks,
            .p1_knigs=self.p1_knigs,
            .p1_bishs=self.p1_bishs,
            .p1_quens=self.p1_quens,
            .p1_kings=self.p1_kings,
            .p2_pawns=self.p2_pawns,
            .p2_rooks=self.p2_rooks,
            .p2_knigs=self.p2_knigs,
            .p2_bishs=self.p2_bishs,
            .p2_quens=self.p2_quens,
            .p2_kings=self.p2_kings,
        };
        return board;
    }

    pub fn reset(
        self: *Board,
    ) void {
        self.turn = Player.PLAYER1;
        self.n_pieces = 32;
        self.last_p1_move_hot = false;
        self.last_p2_move_hot = false;
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
            "RHBQKBHR" ++
            "PPPPPPPP" ++
            "--------" ++
            "--------" ++
            "--------" ++
            "--------" ++
            "pppppppp" ++
            "rhbqkbhr"
        );
    }

    pub fn setup(
        self: *Board,
    ) void {
        self.load_from_string(
            "RHB-KBHR" ++
            "P-P-PPPP" ++
            "--------" ++
            "-hQp----" ++
            "q-P-----" ++
            "----p---" ++
            "pp---ppp" ++
            "r-b-kbhr"
        );
    }

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
            Piece.NONE => return,
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
        const is_hot = captured or pawn_walk or self.is_check_on_opp();
        if (self.turn == Player.PLAYER1) self.last_p1_move_hot = is_hot;
        if (self.turn == Player.PLAYER2) self.last_p2_move_hot = is_hot;
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
            Piece.KING1 => return self.get_moves_king(pos, false),
            Piece.KING2 => return self.get_moves_king(pos, true),
            Piece.KNIG1 => return self.get_moves_knight(pos, false),
            Piece.KNIG2 => return self.get_moves_knight(pos, true),
            Piece.ROOK1 => return self.get_moves_rook(pos, false),
            Piece.ROOK2 => return self.get_moves_rook(pos, true),
            Piece.BISH1 => return self.get_moves_bishop(pos, false),
            Piece.BISH2 => return self.get_moves_bishop(pos, true),
            Piece.QUEN1 => return self.get_moves_queen(pos, false),
            Piece.QUEN2 => return self.get_moves_queen(pos, true),
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
    ) BoardMask {
        var moves = tables.king_moves[pos.index];
        var own_mask = if (flip) self.get_p2_mask() else self.get_p1_mask();
        moves.remove_mask(&own_mask);
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
                const move = Move{.orig=orig, .dest=dest};
                var fork = self.fork_with_move(move);
                if (fork.is_check_on_opp()) continue; // Exclude moves exposing own king.
                movelist.add(move);
            }
        }
        return movelist;
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

    pub fn is_check(
        self: *Board,
        p2: bool,
    ) bool {
        const king_pos = self.get_king_pos(p2);
        // Check by knight.
        const moves_h = tables.knight_moves[king_pos.index];
        const location_h = if (p2) self.p1_knigs else self.p2_knigs;
        if (moves_h.mask & location_h.mask > 0) return true;
        // Check by queen.
        const moves_q = self.get_moves_queen(king_pos, p2);
        const location_q = if (p2) self.p1_quens else self.p2_quens;
        if (moves_q.mask & location_q.mask > 0) return true;
        // Check by bishop.
        const moves_b = self.get_moves_bishop(king_pos, p2);
        const location_b = if (p2) self.p1_bishs else self.p2_bishs;
        if (moves_b.mask & location_b.mask > 0) return true;
        // Check by rook.
        const moves_r = self.get_moves_rook(king_pos, p2);
        const location_r = if (p2) self.p1_rooks else self.p2_rooks;
        if (moves_r.mask & location_r.mask > 0) return true;
        // Check by pawn.
        const moves_p = (
            if (p2) tables.pawn_captures_p2[king_pos.index]
            else tables.pawn_captures_p1[king_pos.index]
        );
        const location_p = if (p2) self.p1_pawns else self.p2_pawns;
        if (moves_p.mask & location_p.mask > 0) return true;
        // Check by king. (Necessary to filter illegal moves).
        const moves_k = self.get_moves_king(king_pos, p2);
        const location_k = if (p2) self.p1_kings else self.p2_kings;
        if (moves_k.mask & location_k.mask > 0) return true;
        // No check.
        return false;
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
        for (0..self.p1_pawns.count()) |_| {
            const pos = self.p1_pawns.next();
            score += @intFromEnum(PieceValue.PAWN) + tables.pawn_score[pos.reverse().index];
        }
        for (0..self.p2_pawns.count()) |_| {
            const pos = self.p2_pawns.next();
            score -= @intFromEnum(PieceValue.PAWN) + tables.pawn_score[pos.index];
        }
        for (0..self.p1_knigs.count()) |_| {
            const pos = self.p1_knigs.next();
            score += @intFromEnum(PieceValue.KNIGHT) + tables.piece_score[pos.reverse().index];
        }
        for (0..self.p2_knigs.count()) |_| {
            const pos = self.p2_knigs.next();
            score -= @intFromEnum(PieceValue.KNIGHT) + tables.piece_score[pos.index];
        }
        for (0..self.p1_bishs.count()) |_| {
            const pos = self.p1_bishs.next();
            score += @intFromEnum(PieceValue.BISHOP) + tables.piece_score[pos.reverse().index];
        }
        for (0..self.p2_bishs.count()) |_| {
            const pos = self.p2_bishs.next();
            score -= @intFromEnum(PieceValue.BISHOP) + tables.piece_score[pos.index];
        }
        for (0..self.p1_rooks.count()) |_| {
            const pos = self.p1_rooks.next();
            score += @intFromEnum(PieceValue.ROOK) + tables.piece_score[pos.reverse().index];
        }
        for (0..self.p2_rooks.count()) |_| {
            const pos = self.p2_rooks.next();
            score -= @intFromEnum(PieceValue.ROOK) + tables.piece_score[pos.index];
        }
        for (0..self.p1_quens.count()) |_| {
            const pos = self.p1_quens.next();
            score += @intFromEnum(PieceValue.QUEEN) + tables.piece_score[pos.reverse().index];
        }
        for (0..self.p2_quens.count()) |_| {
            const pos = self.p2_quens.next();
            score -= @intFromEnum(PieceValue.QUEEN) + tables.piece_score[pos.index];
        }
        return score;
    }

    pub fn minmax(
        self: *Board,
        depth: u4,
        best_min: i16,
        best_max: i16,
        stats: *Stats,
    ) MoveAndScore {
        const p1 = self.turn == Player.PLAYER1;
        const opp_cold = if (p1) !self.last_p2_move_hot else !self.last_p1_move_hot;
        const all_cold = !self.last_p1_move_hot and !self.last_p2_move_hot;
        const is_leaf = (
            (depth == DEPTH_MAX) or
            (depth >= DEPTH_HOT and opp_cold) or
            (depth >= DEPTH_COLD and all_cold)
        );
        // Calculate score on leafs.
        if (is_leaf) {
            const score = self.get_score();
            stats.*.evals[0] += 1;
            stats.*.evals[depth] += 1;
            // terminal.indent(depth);
            // print("{d}\n", .{score});
            return MoveAndScore{.move=null, .score=score};
        // Explore branches.
        } else {
            var init_score: i16 = @as(i16, -32000) + depth;
            if (self.turn==Player.PLAYER2) init_score = -init_score;
            var best: MoveAndScore = MoveAndScore{.move=null, .score=init_score};
            var new_best_min = best_min;
            var new_best_max = best_max;
            const legal = self.get_legal_moves();
            // Draw by stalemate.
            if (legal.len == 0 and !self.is_check_on_own()) {
                best.score = 0;
                return best;
            }
            // Iterate moves.
            for (0..legal.len) |i| {
                const move = legal.data[i];
                // terminal.indent(depth);
                // print("{s}\n", .{move.notation()});
                // Prune.
                if (best_min <= best_max) {
                    best.score = if (self.turn==Player.PLAYER1) best_max-1 else best_min+1;
                    break;
                }
                // Go deeper.
                var fork = self.fork_with_move(move);
                const candidate = fork.minmax(
                    depth+1,
                    new_best_min,
                    new_best_max,
                    stats,
                );
                // Compare scores.
                if (
                    (!best.score_defined) or
                    (self.turn == Player.PLAYER1 and candidate.score > best.score) or
                    (self.turn == Player.PLAYER2 and candidate.score < best.score)
                ) {
                    best.move = move;
                    best.score = candidate.score;
                    best.score_defined = true;
                    if (self.turn == Player.PLAYER1) {
                        new_best_max = candidate.score;
                    } else {
                        new_best_min = candidate.score;
                    }
                }
            }
            return best;
        }
    }
};

// 1200, 1200, 1300, 1500
const DEPTH_COLD = 5;
const DEPTH_HOT =  6;
const DEPTH_MAX =  6;
