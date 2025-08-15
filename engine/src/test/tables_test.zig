const expect = @import("std").testing.expect;
const warn = @import("std").log.warn;
const tables = @import("../tables.zig");
const BoardMask = @import("../boardmask.zig").BoardMask;
const terminal = @import("../terminal.zig");

test "tables" {
    var diagonal = tables.line_sink[0];
    var list = tables.Line{.len=8, .data=.{0,9,18,27,36,45,54,63}};
    try expect(diagonal.equal(&list));

    diagonal = tables.line_sink[1];
    list = tables.Line{ .len=7, .data=.{1,10,19,28,37,46,55,0}};
    try expect(diagonal.equal(&list));

    diagonal = tables.line_sink[6];
    list = tables.Line{ .len=2, .data=.{6,15,0,0,0,0,0,0}};
    try expect(diagonal.equal(&list));

    diagonal = tables.line_sink[7];
    list = tables.Line{ .len=1, .data=.{7,0,0,0,0,0,0,0}};
    try expect(diagonal.equal(&list));

    diagonal = tables.line_sink[50];
    list = tables.Line{ .len=4, .data=.{32,41,50,59,0,0,0,0}};
    try expect(diagonal.equal(&list));
}

test "pawn defense" {
    var front = tables.pawn_defense[16];
    var back = BoardMask.from_string(
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000010" ++
        "00000000"
    );
    try expect(front == back.mask);

    front = tables.pawn_defense[23];
    back = BoardMask.from_string(
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "01000000" ++
        "00000000"
    );
    try expect(front == back.mask);

    front = tables.pawn_defense[17];
    back = BoardMask.from_string(
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000101" ++
        "00000000"
    );
    try expect(front == back.mask);

    front = tables.pawn_defense[30];
    back = BoardMask.from_string(
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "10100000" ++
        "00000000" ++
        "00000000"
    );
    try expect(front == back.mask);

    front = tables.pawn_defense[44];
    back = BoardMask.from_string(
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00101000" ++
        "00000000" ++
        "00000000" ++
        "00000000" ++
        "00000000"
    );
    try expect(front == back.mask);
}
