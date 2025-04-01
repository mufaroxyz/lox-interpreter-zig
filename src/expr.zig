const std = @import("std");
const Token = @import("token.zig").Token;

pub const Expr = union(enum) {
    literal: LiteralExpr,
    grouping: *Expr,
    unary: UnaryExpr,
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
    literal: []const u8,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .boolean => |b| try std.fmt.format(writer, "{}", .{b}),
            .nil => |_| try std.fmt.format(writer, "nil", .{}),
            .literal => |l| try std.fmt.format(writer, "{s}", .{l}),
        }
    }
};
