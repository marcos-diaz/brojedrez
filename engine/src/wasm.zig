const std = @import("std");
const Game = @import("game.zig").Game;
const _pos = @import("pos.zig");
const Pos = _pos.Pos;
const Move = _pos.Move;

var game = Game{};

pub export fn init() void {
    game.init();
}

pub export fn start(bot_id: i32) void {
    game.start(bot_id);
}

pub export fn get(index: i32) i32 {
    return game.get(index);
}

pub export fn move_legal(index0: i32, index1: i32) i32 {
    const orig = Pos.from_int(@intCast(index0));
    const dest = Pos.from_int(@intCast(index1));
    const move = Move{.orig=orig, .dest=dest};
    return game.move_legal(move);
}

pub export fn move_bot() void {
    game.move_bot();
}

pub export fn get_highlight_orig() i32 {
    return game.highlight_orig;
}

pub export fn get_highlight_dest() i32 {
    return game.highlight_dest;
}

pub export fn undo() void {
    game.undo();
}

pub export fn redo() void {
    game.redo();
}
