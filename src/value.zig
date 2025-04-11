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

    pub fn format(self: Value, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
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

    pub fn add(self: Value, other: Value, allocator: std.mem.Allocator) !Value {
        return switch (self) {
            .number => |l_num| switch (other) {
                .number => |r_num| Value.fromNumber(l_num + r_num),
                else => error.TypeMismatch,
            },
            .string => |l_str| switch (other) {
                .string => |r_str| {
                    var buffer = std.ArrayList(u8).init(allocator);
                    try buffer.appendSlice(l_str);
                    try buffer.appendSlice(r_str);
                    return Value.fromString(try buffer.toOwnedSlice());
                },
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn subtract(self: Value, other: Value) !Value {
        return switch (self) {
            .number => |l_num| switch (other) {
                .number => |r_num| Value.fromNumber(l_num - r_num),
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn multiply(self: Value, other: Value) !Value {
        return switch (self) {
            .number => |l_num| switch (other) {
                .number => |r_num| Value.fromNumber(l_num * r_num),
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn divide(self: Value, other: Value) !Value {
        return switch (self) {
            .number => |l_num| switch (other) {
                .number => |r_num| {
                    if (r_num == 0) return error.DivisionByZero;
                    return Value.fromNumber(l_num / r_num);
                },
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn lessThan(self: Value, other: Value, eq: ?bool) !Value {
        return switch (self) {
            .number => |l_num| switch (other) {
                .number => |r_num| {
                    return if (eq orelse false) Value.fromBoolean(l_num <= r_num) else Value.fromBoolean(l_num < r_num);
                },
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn greaterThan(self: Value, other: Value, eq: ?bool) !Value {
        return switch (self) {
            .number => |l_num| switch (other) {
                .number => |r_num| {
                    return if (eq orelse false) Value.fromBoolean(l_num >= r_num) else Value.fromBoolean(l_num > r_num);
                },
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn eql(self: Value, other: Value, negation: ?bool) !Value {
        return switch (self) {
            .string => |l_str| switch (other) {
                .string => |r_str| {
                    if (negation orelse false) return Value.fromBoolean(!std.mem.eql(u8, l_str, r_str)) else return Value.fromBoolean(std.mem.eql(u8, l_str, r_str));
                },
                .number => Value.fromBoolean(if (negation orelse false) true else false),
                else => error.TypeMismatch,
            },
            .number => |l_num| switch (other) {
                .number => |r_num| return Value.fromBoolean(if (negation orelse false) l_num != r_num else l_num == r_num),
                .string => Value.fromBoolean(if (negation orelse false) true else false),
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }
};
