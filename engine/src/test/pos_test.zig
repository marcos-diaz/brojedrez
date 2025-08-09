const expect = @import("std").testing.expect;
const warn = @import("std").log.warn;
const pos = @import("../pos.zig");
const Pos = pos.Pos;
const Move = pos.Move;
const MoveList = pos.MoveList;

test "sort" {
    var list = MoveList{};
    list.add(Move{.orig=Pos.from_int(0), .dest=Pos.from_int(10), .capture_score = 5});
    list.add(Move{.orig=Pos.from_int(1), .dest=Pos.from_int(11), .capture_score = 15});
    list.add(Move{.orig=Pos.from_int(2), .dest=Pos.from_int(20), .capture_score = 20});
    list.add(Move{.orig=Pos.from_int(3), .dest=Pos.from_int(30), .capture_score = 10});
    list.sort();
    try expect(list.data[0].capture_score == 20 and list.data[0].orig.index == 2);
    try expect(list.data[1].capture_score == 15 and list.data[1].orig.index == 1);
    try expect(list.data[2].capture_score == 10 and list.data[2].orig.index == 3);
    try expect(list.data[3].capture_score ==  5 and list.data[3].orig.index == 0);
}
