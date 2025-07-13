const expect = @import("std").testing.expect;
const warn = @import("std").log.warn;
const BoardMask = @import("../boardmask.zig").BoardMask;

test "diagonal" {
    // var mask1 = BoardMask{.mask = (
    //     (@as(u64, 0b00000000) << 8*7) |
    //     (@as(u64, 0b00001111) << 8*6) |
    //     (@as(u64, 0b11001100) << 8*5) |
    //     (@as(u64, 0b00110011) << 8*4) |
    //     (@as(u64, 0b11111111) << 8*3) |
    //     (@as(u64, 0b10101010) << 8*2) |
    //     (@as(u64, 0b01010101) << 8*1) |
    //     (@as(u64, 0b00000000) << 8*0)
    // )};
    // try expect(mask1.get_diagonal_down(0) == 0b00011000);
    // try expect(mask1.get_diagonal_down(1) == 0b10111110);
    // try expect(mask1.get_diagonal_down(2) == 0b11101000);
    // try expect(mask1.get_diagonal_down(3) == 0b11101110);
    // try expect(mask1.get_diagonal_down(4) == 0b11111000);
    // try expect(mask1.get_diagonal_down(5) == 0b11111110);
    // try expect(mask1.get_diagonal_down(6) == 0b11111100);
    // try expect(mask1.get_diagonal_down(7) == 0b11111110);
}
