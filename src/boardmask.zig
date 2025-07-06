pub const BoardMask = struct {
    mask: u64 = 0,

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
        self.mask = self.mask & ~other_mask.mask;
    }

    pub fn flip(
        self: *BoardMask,
    ) void {
        self.mask = @bitReverse(self.mask);  // TODO: Real flip instead of rotation.
    }
};
