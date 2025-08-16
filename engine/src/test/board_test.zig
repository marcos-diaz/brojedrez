const expect = @import("std").testing.expect;
const warn = @import("std").log.warn;
const Board = @import("../board.zig").Board;
const Player = @import("../board.zig").Player;
const _pos = @import("../pos.zig");
const Pos = _pos.Pos;
const Move = _pos.Move;
const terminal = @import("../terminal.zig");

test "check" {
    var board = Board{};
    board.load_from_string(
        "--------" ++
        "--------" ++
        "-----K--" ++
        "--------" ++
        "------n-" ++
        "--------" ++
        "--------" ++
        "----k---"
    );
    try expect(board.is_check(true) == true);
    try expect(board.is_check(false) == false);

    board.load_from_string(
        "--------" ++
        "--------" ++
        "-----k--" ++
        "--------" ++
        "------N-" ++
        "--------" ++
        "--------" ++
        "----K---"
    );
    try expect(board.is_check(true) == false);
    try expect(board.is_check(false) == true);

    board.load_from_string(
        "--------" ++
        "--------" ++
        "-----K--" ++
        "------p-" ++
        "--p-----" ++
        "--------" ++
        "--------" ++
        "--k-----"
    );
    try expect(board.is_check(true) == true);
    try expect(board.is_check(false) == false);

    board.load_from_string(
        "-K------" ++
        "----P---" ++
        "-----k--" ++
        "----p---" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------"
    );
    try expect(board.is_check(true) == false);
    try expect(board.is_check(false) == true);

    board.load_from_string(
        "-K------" ++
        "-----P--" ++
        "-----k--" ++
        "----p---" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------"
    );
    try expect(board.is_check(true) == false);
    try expect(board.is_check(false) == false);

    board.load_from_string(
        "--------" ++
        "--------" ++
        "-K------" ++
        "--------" ++
        "-r------" ++
        "--------" ++
        "---k---R" ++
        "--------"
    );
    try expect(board.is_check(true) == true);
    try expect(board.is_check(false) == true);

    board.load_from_string(
        "--------" ++
        "--------" ++
        "-K------" ++
        "-p------" ++
        "-r------" ++
        "--------" ++
        "---k-p-R" ++
        "--------"
    );
    try expect(board.is_check(true) == false);
    try expect(board.is_check(false) == false);
}

test "checkmate" {
    var board = Board{};
    board.load_from_string(
        "--qr----" ++
        "------P-" ++
        "---K---P" ++
        "P-B--P--" ++
        "---P--Qp" ++
        "p-----p-" ++
        "-RQ--p--" ++
        "----r-k-"
    );
    board.turn = Player.PLAYER2;
    try expect(board.is_check_on_own());
    try expect(board.get_legal_moves().len == 0);
}

test "castling" {
    var board = Board{};
    board.load_from_string(
        "R---K--R" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "r---k--r"
    );
    try expect(board.can_castle(false, false) == true);
    try expect(board.can_castle(false, true) == true);
    try expect(board.can_castle(true, false) == true);
    try expect(board.can_castle(true, true) == true);

    board = Board{};
    board.load_from_string(
        "R---K--R" ++
        "--------" ++
        "-----r--" ++
        "--------" ++
        "--------" ++
        "-----R--" ++
        "--------" ++
        "r---k--r"
    );
    try expect(board.can_castle(false, false) == false);
    try expect(board.can_castle(false, true) == true);
    try expect(board.can_castle(true, false) == false);
    try expect(board.can_castle(true, true) == true);

    board = Board{};
    board.load_from_string(
        "R---K--R" ++
        "--------" ++
        "--r-----" ++
        "--------" ++
        "--------" ++
        "--R-----" ++
        "--------" ++
        "r---k--r"
    );
    try expect(board.can_castle(false, false) == true);
    try expect(board.can_castle(false, true) == false);
    try expect(board.can_castle(true, false) == true);
    try expect(board.can_castle(true, true) == false);
}

test "hash" {
    var board = Board{};
    board.load_from_string(
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "k-------"
    );
    const hash = board.hash;
    board.move_to(Move.from_notation("a1a2"));
    try expect(board.hash != hash);
    board.move_to(Move.from_notation("a2b2"));
    try expect(board.hash != hash);
    board.move_to(Move.from_notation("b2a1"));
    try expect(board.hash == hash);
}

test "repetition" {
    var board = Board{};
    board.load_from_string(
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "--------" ++
        "k------K"
    );
    board.move_to(Move.from_notation("a1a2"));
    board.move_to(Move.from_notation("b1b2"));
    board.move_to(Move.from_notation("a2a1"));
    board.move_to(Move.from_notation("h2h1"));  // 2st rep.
    board.move_to(Move.from_notation("a1a2"));
    board.move_to(Move.from_notation("h1h2"));
    board.move_to(Move.from_notation("a2a1"));
    try expect(board.hashlist.threefold() == false);
    board.move_to(Move.from_notation("h2h1"));  // 3nd rep.
    try expect(board.hashlist.threefold() == true);
}
