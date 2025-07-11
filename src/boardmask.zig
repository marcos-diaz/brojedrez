const std = @import("std");

pub const BoardMask = struct {
    mask: u64 = 0,

    pub fn reset(
        self: *BoardMask,
    ) void {
        self.mask = 0;
    }

    pub fn has(
        self: *BoardMask,
        pos: u6,
    ) bool {
        return (((self.mask >> pos) & 1) != 0);
    }

    pub fn remove(
        self: *BoardMask,
        pos: u6,
    ) void {
        const target: u64 = 1;
        self.mask &= ~(target << pos);
    }

    pub fn add(
        self: *BoardMask,
        pos: u6,
    ) void {
        const target: u64 = 1;
        self.mask |= target << pos;
    }

    pub fn remove_mask(
        self: *BoardMask,
        other_mask: *BoardMask,
    ) void {
        self.mask &= ~other_mask.mask;
    }

    pub fn flip(
        self: *BoardMask,
    ) void {
        self.mask = @bitReverse(self.mask);  // TODO: Mirror instead of reverse.
    }

    pub fn get_row(
        self: *BoardMask,
        row_index: u3,
    ) u8 {
        const index: u6 = @intCast(row_index);
        return @intCast((self.mask >> (index * 8)) & 0b11111111);
    }

    pub fn set_row(
        self: *BoardMask,
        row_index: u3,
        row_data: u8,
    ) void {
        const index: u6 = @intCast(row_index);
        self.mask |= @as(u64, row_data) << (index * 8);
    }

    pub fn get_col(
        self: *BoardMask,
        col_index: u3,
    ) u8 {
        const col: u6 = @intCast(col_index);
        var result: u8 = 0;
        for (0..8) |_i| {
            const i: u3 = @intCast(_i);
            const pos: u6 = col + (8 * @as(u6, i));
            const bit: u8 = @intFromBool(self.has(pos));
            result |= bit << i;
        }
        return result;
    }

    pub fn set_col(
        self: *BoardMask,
        col_index: u3,
        col_data: u8,
    ) void {
        const col: u6 = @intCast(col_index);
        for (0..8) |_i| {
            const i: u3 = @intCast(_i);
            const bit: u64 = (col_data >> i) & 1;
            const shift: u6 = col + (8 * @as(u6, i));
            self.mask |= bit << shift;
            // TODO: It should clear bits too?
        }
    }
};
