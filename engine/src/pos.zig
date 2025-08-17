const std = @import("std");

// Position.
pub const Pos = struct{
    index: u6 = undefined,

    pub fn from_int(index: u6) Pos {
        return Pos{.index = index};
    }

    pub fn from_row_col(
        irow: u3,
        icol: u3,
    ) Pos {
        const index: u6 = (@as(u6, irow) * 8) + icol;
        return Pos.from_int(index);
    }

    pub fn from_notation(
        letter: u8,
        number: u8,
    ) Pos {
        const icol: u3 = @truncate(letter - 97);
        const irow: u3 = @truncate(number - 49);
        return Pos.from_row_col(irow, 7-icol);
    }

    pub fn row(
        self: *const Pos,
    ) u3 {
        return @intCast(self.index / 8);
    }

    pub fn col(
        self: *const Pos,
    ) u3 {
        return @intCast(self.index % 8);
    }

    pub fn move(
        self: *const Pos,
        rows: i8,
        cols: i8,
    ) Pos {
        const new_row: u3 = @intCast(std.math.clamp(rows + self.row(), 0, 7));
        const new_col: u3 = @intCast(std.math.clamp(cols + self.col(), 0, 7));
        return Pos.from_row_col(new_row, new_col);
    }

    pub fn reverse(
        self: *const Pos,
    ) Pos {
        return Pos.from_int(63 - self.index);
    }

    pub fn notation(
        self: *const Pos,
    ) [2]u8 {
        const letters = "hgfedcba";
        const numbers = "12345678";
        var string = [_]u8{0, 0};
        string[0] = letters[self.col()];
        string[1] = numbers[self.row()];
        return string;
    }
};

pub const Move = struct {
    orig: Pos,
    dest: Pos,
    capture_score: u6 = 0,

    pub fn from_notation(
        string: *const [4]u8,
    ) Move {
        return Move{
            .orig = Pos.from_notation(string[0], string[1]),
            .dest = Pos.from_notation(string[2], string[3]),
        };
    }

    pub fn notation(
        self: *const Move,
    ) [4]u8 {
        return self.orig.notation() ++ self.dest.notation();
    }

    pub fn eq(
        self: *const Move,
        other: *const Move,
    ) bool {
        return self.orig.index == other.orig.index and self.dest.index == other.dest.index;
    }
};

pub fn MoveListType(comptime size: usize) type {
    return struct {
        const Self = @This();
        len: u8 = 0,
        data: [size]Move = undefined,

        pub fn add(
            self: *Self,
            move: Move,
        ) void {
            self.data[self.len] = move;
            self.len += 1;
        }

        pub fn reverse(
            self: *Self)
        void {
            var i: usize = 0;
            var j: usize = self.len - 1;
            while (i < j) {
                const temp = self.data[i];
                self.data[i] = self.data[j];
                self.data[j] = temp;
                i += 1;
                j -= 1;
            }
        }

        pub fn sort(
            self: *Self,
        ) void {
            const slice = self.data[0..self.len];
            const compare = struct {
                fn compare(_: void, a: Move, b: Move) bool {
                    return a.capture_score > b.capture_score;
                }
            }.compare;
            std.mem.sort(Move, slice, {}, compare);
        }

        pub fn sort_with_priority(
            self: *Self,
            priority: Move,
        ) void {
            const slice = self.data[0..self.len];
            const compare = struct {
                fn compare(priority_move: *const Move, a: Move, b: Move) bool {
                    if (a.eq(priority_move)) return true;
                    if (b.eq(priority_move)) return false;
                    return a.capture_score > b.capture_score;
                }
            }.compare;
            std.mem.sort(Move, slice, &priority, compare);
        }
    };
}

pub const MoveListLong = MoveListType(256);
pub const MoveListShort = MoveListType(10);

pub const MoveAndScore = struct {
    move: ?Move,
    score: i16,
    score_defined: bool = false,
    path: MoveListShort = MoveListShort{},
};

