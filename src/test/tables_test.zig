const expect = @import("std").testing.expect;
const warn = @import("std").log.warn;
const tables = @import("../tables.zig");

test "tables" {
    var diagonal = tables.diagonal_down_pos[0];
    var list = tables.PosList{.len=8, .data=.{0,9,18,27,36,45,54,63}};
    try expect(diagonal.equal(&list));

    diagonal = tables.diagonal_down_pos[1];
    list = tables.PosList{ .len=7, .data=.{1,10,19,28,37,46,55,0}};
    try expect(diagonal.equal(&list));

    diagonal = tables.diagonal_down_pos[6];
    list = tables.PosList{ .len=2, .data=.{6,15,0,0,0,0,0,0}};
    try expect(diagonal.equal(&list));

    diagonal = tables.diagonal_down_pos[7];
    list = tables.PosList{ .len=1, .data=.{7,0,0,0,0,0,0,0}};
    try expect(diagonal.equal(&list));

    diagonal = tables.diagonal_down_pos[50];
    list = tables.PosList{ .len=4, .data=.{32,41,50,59,0,0,0,0}};
    try expect(diagonal.equal(&list));
}
