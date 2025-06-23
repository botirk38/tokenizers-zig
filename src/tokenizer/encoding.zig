const std = @import("std");

pub const Offsets = [2]u32;

pub const PaddingDirection = enum {
    Left,
    Right,
};

pub const TruncationDirection = enum {
    Left,
    Right,
};

fn fillList(comptime T: type, value: T, count: usize, allocator: std.mem.Allocator) !std.ArrayList(T) {
    var list = std.ArrayList(T).init(allocator);
    try list.resize(count);
    for (list.items) |*item| item.* = value;
    return list;
}

pub const Encoding = struct {
    ids: std.ArrayList(u32),
    type_ids: std.ArrayList(u32),
    tokens: std.ArrayList([]const u8),
    words: std.ArrayList(?u32),
    attention_mask: std.ArrayList(u32),
    special_tokens_mask: std.ArrayList(u32),
    offsets: std.ArrayList(Offsets),

    pub fn init(
        allocator: std.mem.Allocator,
        ids: []const u32,
        type_ids: []const u32,
        tokens: []const []const u8,
        words: []const ?u32,
        attention_mask: []const u32,
        special_tokens_mask: []const u32,
        offsets: []const Offsets,
    ) !Encoding {
        var encoding = Encoding{
            .ids = try std.ArrayList(u32).initCapacity(allocator, ids.len),
            .type_ids = try std.ArrayList(u32).initCapacity(allocator, type_ids.len),
            .tokens = try std.ArrayList([]const u8).initCapacity(allocator, tokens.len),
            .words = try std.ArrayList(?u32).initCapacity(allocator, words.len),
            .attention_mask = try std.ArrayList(u32).initCapacity(allocator, attention_mask.len),
            .special_tokens_mask = try std.ArrayList(u32).initCapacity(allocator, special_tokens_mask.len),
            .offsets = try std.ArrayList(Offsets).initCapacity(allocator, offsets.len),
        };

        try encoding.appendAll(ids, type_ids, tokens, words, attention_mask, special_tokens_mask, offsets);

        return encoding;
    }

    fn appendAll(
        self: *Encoding,
        ids: []const u32,
        type_ids: []const u32,
        tokens: []const []const u8,
        words: []const ?u32,
        attention_mask: []const u32,
        special_tokens_mask: []const u32,
        offsets: []const Offsets,
    ) !void {
        try self.ids.appendSlice(ids);
        try self.type_ids.appendSlice(type_ids);
        try self.tokens.appendSlice(tokens);
        try self.words.appendSlice(words);
        try self.attention_mask.appendSlice(attention_mask);
        try self.special_tokens_mask.appendSlice(special_tokens_mask);
        try self.offsets.appendSlice(offsets);
    }

    pub fn deinit(self: *Encoding) void {
        self.ids.deinit();
        self.type_ids.deinit();
        self.tokens.deinit();
        self.words.deinit();
        self.attention_mask.deinit();
        self.special_tokens_mask.deinit();
        self.offsets.deinit();
    }

    pub fn len(self: *const Encoding) usize {
        return self.ids.items.len;
    }

    pub fn isEmpty(self: *const Encoding) bool {
        return self.len() == 0;
    }

    pub fn merge(
        self: *Encoding,
        other: Encoding,
        growing_offsets: bool,
    ) !void {
        try self.ids.appendSlice(other.ids.items);
        try self.type_ids.appendSlice(other.type_ids.items);
        try self.tokens.appendSlice(other.tokens.items);
        try self.words.appendSlice(other.words.items);
        try self.attention_mask.appendSlice(other.attention_mask.items);
        try self.special_tokens_mask.appendSlice(other.special_tokens_mask.items);

        if (growing_offsets and self.offsets.items.len > 0) {
            const last_offset = self.offsets.items[self.offsets.items.len - 1][1];
            for (other.offsets.items) |off| {
                try self.offsets.append(.{ off[0] + last_offset, off[1] + last_offset });
            }
        } else {
            try self.offsets.appendSlice(other.offsets.items);
        }
    }

    pub fn pad(
        self: *Encoding,
        length: usize,
        pad_id: u32,
        pad_type_id: u32,
        pad_token: []const u8,
        direction: PaddingDirection,
        allocator: std.mem.Allocator,
    ) !void {
        const current_len = self.len();
        if (current_len >= length) return;

        const pad_count = length - current_len;
        const ids_pad = try fillList(u32, pad_id, pad_count, allocator);
        const type_ids_pad = try fillList(u32, pad_type_id, pad_count, allocator);
        const tokens_pad = try fillList([]const u8, pad_token, pad_count, allocator);
        const words_pad = try fillList(?u32, null, pad_count, allocator);
        const attn_mask_pad = try fillList(u32, 0, pad_count, allocator);
        const special_pad = try fillList(u32, 1, pad_count, allocator);
        const offsets_pad = try fillList(Offsets, .{ 0, 0 }, pad_count, allocator);

        defer {
            ids_pad.deinit();
            type_ids_pad.deinit();
            tokens_pad.deinit();
            words_pad.deinit();
            attn_mask_pad.deinit();
            special_pad.deinit();
            offsets_pad.deinit();
        }

        switch (direction) {
            .Left => {
                try self.ids.insertSlice(0, ids_pad.items);
                try self.type_ids.insertSlice(0, type_ids_pad.items);
                try self.tokens.insertSlice(0, tokens_pad.items);
                try self.words.insertSlice(0, words_pad.items);
                try self.attention_mask.insertSlice(0, attn_mask_pad.items);
                try self.special_tokens_mask.insertSlice(0, special_pad.items);
                try self.offsets.insertSlice(0, offsets_pad.items);
            },
            .Right => {
                try self.ids.appendSlice(ids_pad.items);
                try self.type_ids.appendSlice(type_ids_pad.items);
                try self.tokens.appendSlice(tokens_pad.items);
                try self.words.appendSlice(words_pad.items);
                try self.attention_mask.appendSlice(attn_mask_pad.items);
                try self.special_tokens_mask.appendSlice(special_pad.items);
                try self.offsets.appendSlice(offsets_pad.items);
            },
        }
    }

    pub fn truncate(
        self: *Encoding,
        length: usize,
        direction: TruncationDirection,
    ) void {
        const current_len = self.len();
        if (current_len <= length) return;

        const start = switch (direction) {
            .Right => 0,
            .Left => current_len - length,
        };

        self.ids.items = self.ids.items[start .. start + length];
        self.type_ids.items = self.type_ids.items[start .. start + length];
        self.tokens.items = self.tokens.items[start .. start + length];
        self.words.items = self.words.items[start .. start + length];
        self.attention_mask.items = self.attention_mask.items[start .. start + length];
        self.special_tokens_mask.items = self.special_tokens_mask.items[start .. start + length];
        self.offsets.items = self.offsets.items[start .. start + length];
    }
};

test "merge encodings" {
    const gpa = std.testing.allocator;
    var a = try Encoding.init(gpa, &[_]u32{1}, &[_]u32{0}, &[_][]const u8{"Hello "}, &[_]?u32{0}, &[_]u32{1}, &[_]u32{0}, &[_]Offsets{.{ 0, 6 }});
    var b = try Encoding.init(gpa, &[_]u32{2}, &[_]u32{1}, &[_][]const u8{"World!"}, &[_]?u32{0}, &[_]u32{1}, &[_]u32{0}, &[_]Offsets{.{ 0, 6 }});
    defer a.deinit();
    defer b.deinit();

    try a.merge(b, true);

    try std.testing.expectEqualSlices(u32, a.ids.items, &[_]u32{ 1, 2 });
    try std.testing.expectEqualSlices([]const u8, a.tokens.items, &[_][]const u8{ "Hello ", "World!" });
    try std.testing.expectEqualSlices(Offsets, a.offsets.items, &[_]Offsets{ .{ 0, 6 }, .{ 6, 12 } });
}

test "truncate right" {
    const gpa = std.testing.allocator;
    var a = try Encoding.init(gpa, &[_]u32{ 1, 2, 3 }, &[_]u32{ 0, 0, 0 }, &[_][]const u8{ "Hello", "World", "!" }, &[_]?u32{ 0, 1, 2 }, &[_]u32{ 1, 1, 1 }, &[_]u32{ 0, 0, 0 }, &[_]Offsets{ .{ 0, 5 }, .{ 6, 11 }, .{ 11, 12 } });
    defer a.deinit();

    a.truncate(2, .Right);

    try std.testing.expectEqualSlices(u32, a.ids.items, &[_]u32{ 1, 2 });
    try std.testing.expectEqualSlices([]const u8, a.tokens.items, &[_][]const u8{ "Hello", "World" });
    try std.testing.expectEqualSlices(Offsets, a.offsets.items, &[_]Offsets{ .{ 0, 5 }, .{ 6, 11 } });
}

test "pad left" {
    const gpa = std.testing.allocator;
    var a = try Encoding.init(gpa, &[_]u32{1}, &[_]u32{0}, &[_][]const u8{"Hello "}, &[_]?u32{0}, &[_]u32{1}, &[_]u32{0}, &[_]Offsets{.{ 0, 6 }});
    defer a.deinit();

    try a.pad(2, 99, 0, "[PAD]", .Left, gpa);
    try std.testing.expectEqualSlices(u32, a.ids.items, &[_]u32{ 99, 1 });
    try std.testing.expectEqualSlices([]const u8, a.tokens.items, &[_][]const u8{ "[PAD]", "Hello " });
}
