const std = @import("std");
const Token = @import("token.zig").Token;

pub const Expr = union(enum) {
    literal: LiteralExpr,
    grouping: *Expr,
    unary: UnaryExpr,
    binary: BinaryExpr,
};

pub const BinaryExpr = struct {
    left: *Expr,
    operator: Token,
    right: *Expr,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try std.fmt.format(writer, "{s}", .{self.operator.lexeme});
    }
};

pub const UnaryExpr = struct {
    operator: Token,
    right: *Expr,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try std.fmt.format(writer, "{s}", .{self.operator.lexeme});
    }
};

pub const LiteralExpr = union(enum) {
    boolean: bool,
    nil: void,
    string: []const u8,
    number: f64,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .boolean => |b| try std.fmt.format(writer, "{}", .{b}),
            .nil => |_| try std.fmt.format(writer, "nil", .{}),
            .string => |s| try std.fmt.format(writer, "{s}", .{s}),
            .number => |n| {
                if (@floor(n) == n) { // if has dec part
                    try std.fmt.format(writer, "{d}.0", .{n});
                } else {
                    try std.fmt.format(writer, "{d}", .{n});
                }
            },
        }
    }
};
