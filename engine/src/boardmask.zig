const std = @import("std");
const tables = @import("tables.zig");
const Pos = @import("pos.zig").Pos;

pub const BoardMask = struct {
    mask: u64 = 0,
    next_index: u7 = 0,

    pub fn reset(
        self: *BoardMask,
    ) void {
        self.mask = 0;
    }

    pub fn has(
        self: *BoardMask,
        pos: Pos,
    ) bool {
        return (((self.mask >> pos.index) & 1) != 0);
    }

    pub fn remove(
        self: *BoardMask,
        pos: Pos,
    ) void {
        const target: u64 = 1;
        self.mask &= ~(target << pos.index);
    }

    pub fn add(
        self: *BoardMask,
        pos: Pos,
    ) void {
        const target: u64 = 1;
        self.mask |= target << pos.index;
    }

    pub fn add_mask(
        self: *BoardMask,
        other: *BoardMask,
    ) void {
        self.mask |= other.mask;
    }

    pub fn remove_mask(
        self: *BoardMask,
        other: *BoardMask,
    ) void {
        self.mask &= ~other.mask;
    }

    pub fn intersect_mask(
        self: *BoardMask,
        other: *BoardMask,
    ) void {
        self.mask &= other.mask;
    }

    pub fn flip(
        self: *BoardMask,
    ) void {
        self.mask = @bitReverse(self.mask);  // TODO: Mirror instead of reverse.
    }

    pub fn count(
        self: *BoardMask,
    ) u6 {
        return @truncate(@popCount(self.mask));
    }

    pub fn next(
        self: *BoardMask,
    ) Pos {
        const index = @ctz(self.mask >> @truncate(self.next_index));
        self.next_index += @intCast(index);
        self.next_index += 1;
        return Pos.from_int(@truncate(self.next_index - 1));
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
        data: u8,
    ) void {
        const index: u6 = @intCast(row_index);
        self.mask |= @as(u64, data) << (index * 8);
    }

    pub fn get_col(
        self: *BoardMask,
        col: u3,
    ) u8 {
        var result: u8 = 0;
        for (0..8) |_i| {
            const i: u3 = @intCast(_i);
            const pos = Pos.from_row_col(i, col);
            const bit: u8 = @intFromBool(self.has(pos));
            result |= bit << i;
        }
        return result;
    }

    pub fn set_col(
        self: *BoardMask,
        col_index: u3,
        data: u8,
    ) void {
        const col: u6 = @intCast(col_index);
        for (0..8) |_i| {
            const i: u3 = @intCast(_i);
            const bit: u64 = (data >> i) & 1;
            const shift: u6 = col + (8 * @as(u6, i));
            self.mask |= bit << shift;
            // TODO: It should clear bits too?
        }
    }

    pub fn get_line(
        self: *BoardMask,
        list: tables.Line,
    ) u8 {
        var result: u8 = 0;
        for (0..list.len) |_i| {
            const i: u3 = @intCast(_i);
            const pos = Pos.from_int(list.data[i]);
            const bit: u8 = @intFromBool(self.has(pos));
            result |= bit << i;
        }
        for (list.len..8) |_i| {
            const i: u3 = @intCast(_i);
            result |= @as(u8, 1) << i;
        }
        return result;
    }

    pub fn set_line(
        self: *BoardMask,
        list: tables.Line,
        data: u8,
    ) void {
        for (0..list.len) |_i| {
            const i: u3 = @intCast(_i);
            const bit: u64 = (data >> i) & 1;
            self.mask |= bit << list.data[i];
            // TODO: It should clear bits too?
        }
    }
};
