const Expr = @import("expr.zig").Expr;
const std = @import("std");

pub const AstPrinter = struct {
    pub fn print(writer: anytype, expression: *Expr) anyerror!void {
        try switch (expression.*) {
            .literal => |literal| std.fmt.format(writer, "{}", .{literal}),
            .grouping => |grouping| parenthesize(writer, "group", &[_]*Expr{grouping}),
        };
    }

    pub fn parenthesize(
        writer: anytype,
        name: []const u8,
        expressions: []const *Expr,
    ) !void {
        try std.fmt.format(writer, "({s}", .{name});

        for (expressions) |expr| {
            try std.fmt.format(writer, " ", .{});
            try AstPrinter.print(writer, expr);
        }

        try std.fmt.format(writer, ")", .{});
    }
};
