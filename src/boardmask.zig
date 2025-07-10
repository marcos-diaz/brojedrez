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

    pub fn flip(
        self: *BoardMask,
    ) void {
        self.mask = @bitReverse(self.mask);  // TODO: Real flip instead of rotation.
    }
};
