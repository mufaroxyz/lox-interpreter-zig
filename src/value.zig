const std = @import("std");

pub const Value = union(enum) {
    number: f64,
    string: []const u8,
    boolean: bool,
    nil: void,

    pub fn toString(self: Value, allocator: std.mem.Allocator) ![]const u8 {
        switch (self) {
            .string => |s| return s,
            .number => |n| {
                std.debug.print("Value::toString: number: {}\n", .{n});
                const buf = try allocator.alloc(u8, 32);
                const newMem = try std.fmt.bufPrint(buf, "{d}", .{n});

                if (std.mem.indexOfScalar(u8, buf, '.') == null) {
                    const _newMem = try std.fmt.bufPrint(buf, "{d}.0", .{n});
                    return allocator.realloc(buf, _newMem.len);
                } else {
                    return allocator.realloc(buf, newMem.len);
                }
            },
            .boolean => |b| {
                const buf = try allocator.alloc(u8, 5);
                const newMem = try std.fmt.bufPrint(buf, "{}", .{b});
                return allocator.realloc(buf, newMem.len);
            },
            .nil => {
                const buf = try allocator.alloc(u8, 3);
                _ = try std.fmt.bufPrint(buf, "nil", .{});
                return buf;
            },
        }
    }

    pub fn format(self: Value, writer: anytype) !void {
        switch (self) {
            .number => |n| try std.fmt.format(writer, "{d}", .{n}),
            .string => |s| try std.fmt.format(writer, "{s}", .{s}),
            .boolean => |b| try std.fmt.format(writer, "{}", .{b}),
            .nil => try std.fmt.format(writer, "nil", .{}),
        }
    }

    pub fn fromNumber(value: f64) Value {
        return Value{ .number = value };
    }

    pub fn fromString(value: []const u8) Value {
        return Value{ .string = value };
    }

    pub fn fromBoolean(value: bool) Value {
        return Value{ .boolean = value };
    }

    pub fn _nil() Value {
        return Value{ .nil = {} };
    }

    pub fn fromLiteralExpr(literal: @import("expr.zig").LiteralExpr) Value {
        return switch (literal) {
            .boolean => |b| Value{ .boolean = b },
            .nil => Value{ .nil = {} },
            .string => |s| Value{ .string = s },
            .number => |n| Value{ .number = n },
        };
    }
};
