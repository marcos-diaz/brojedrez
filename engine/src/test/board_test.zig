const expect = @import("std").testing.expect;
const warn = @import("std").log.warn;
const Board = @import("../board.zig").Board;
const Pos = @import("../pos.zig").Pos;
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
