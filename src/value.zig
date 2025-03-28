const std = @import("std");

pub const Value = union(enum) {
    number: f64,
    string: []const u8,

    pub fn toString(self: Value, allocator: std.mem.Allocator) ![]const u8 {
        switch (self) {
            .string => |s| return s,
            .number => |n| {
                const buf = try allocator.alloc(u8, 32);
                const isInteger = @floor(n) == n;

                if (isInteger) {
                    const newMem = try std.fmt.bufPrintZ(buf, "{d}.0", .{n});
                    return allocator.realloc(buf, newMem.len);
                } else {
                    const newMem = try std.fmt.bufPrintZ(buf, "{d}", .{n});
                    return allocator.realloc(buf, newMem.len);
                }
            },
        }
    }

    pub fn fromNumber(value: f64) Value {
        return Value{ .number = value };
    }

    pub fn fromString(value: []const u8) Value {
        return Value{ .string = value };
    }
};
