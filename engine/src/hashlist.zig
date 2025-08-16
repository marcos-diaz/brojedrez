pub const HashList = struct {
    hashes: [8]u64 = .{0} ** 8,
    index: u3 = 0,
    last_was_duplicated: bool = false,

    pub fn put (
        self: *HashList,
        hash: u64,
    ) void {
        self.last_was_duplicated = self.has(hash);
        self.hashes[self.index] = hash;
        self.index +%= 1;
    }

    pub fn has (
        self: *HashList,
        hash: u64,
    ) bool {
        for (0..8) |i| {
            if (self.hashes[i] == hash) return true;
        }
        return false;
    }

    pub fn threefold (
        self: *HashList,
    ) bool {
        for (0..8) |a| {
            const hash_a = self.hashes[a];
            if (hash_a == 0) continue;
            var occurrences: u3 = 0;
            for (0..8) |b| {
                if (hash_a == self.hashes[b]) occurrences += 1;
                if (occurrences == 3) return true;
            }
        }
        return false;
    }
};
