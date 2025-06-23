const std = @import("std");

pub const Token = struct {
    id: u32,
    value: []const u8,
    offsets: [2]u32,
    word: ?u32,
    type_id: u32,
    special: bool,
};
