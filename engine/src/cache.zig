const std = @import("std");
const Move = @import("pos.zig").Move;
const MoveAndScore = @import("pos.zig").MoveAndScore;

// var entries: [1_048_576]CacheEntry = std.mem.zeroes([1_048_576]CacheEntry);  // 2^20.
const cache_size = 1 << 24;  // 8M
var entries: [cache_size]CacheEntry = undefined;

pub const CacheType = enum {
    SCORE,
    PASS,
    PRUNE,
};

pub const CacheEntry = struct{
    hash: u64,
    best: MoveAndScore,
    // cache_type: CacheType,
};

pub const Cache = struct {
    // entries: [1_048_576]CacheEntry = std.mem.zeroes([1_048_576]CacheEntry),  // 2^20.

    pub fn reset(
        self: *Cache,
    ) void {
        _ = self;
        @memset(&entries, std.mem.zeroes(CacheEntry));
    }

    pub fn set(
        self: *Cache,
        entry: CacheEntry,
        turn: bool,
    ) void {
        _ = self;
        var index: usize = @intCast(entry.hash & 0xFFFFFF);
        if (turn) index += 1;
        // const current = self.get(index, turn);
        // if (current.?.best.depth >= entry.best.depth) {
        //     return;
        // }
        entries[index] = entry;
    }

    pub fn get(
        self: *Cache,
        hash: u64,
        turn: bool,
    ) ?CacheEntry {
        _ = self;
        var index: usize = @intCast(hash & 0xFFFFFF);
        if (turn) index += 1;
        const entry = entries[index];
        if (entry.hash != hash) return null;
        if (entry.best.depth == 0) return null;
        return entry;
    }
};


