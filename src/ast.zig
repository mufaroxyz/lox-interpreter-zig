const Expr = @import("expr.zig").Expr;
const std = @import("std");

pub const AstPrinter = struct {
    pub fn print(writer: anytype, expression: *Expr) anyerror!void {
        try switch (expression.*) {
            .literal => |literal| std.fmt.format(writer, "{}", .{literal}),
            .grouping => |grouping| {
                var expressions = [_]*Expr{grouping};
                try parenthesize(writer, "group", &expressions);
            },
            .unary => |unary| {
                var expressions = [_]*Expr{unary.right};
                try parenthesize(writer, unary.operator.lexeme, &expressions);
            },
        };
    }

    pub fn parenthesize(
        writer: anytype,
        name: []const u8,
        expressions: []*Expr,
    ) !void {
        try std.fmt.format(writer, "({s}", .{name});

        for (expressions) |expr| {
            try std.fmt.format(writer, " ", .{});
            try AstPrinter.print(writer, expr);
        }

        try std.fmt.format(writer, ")", .{});
    }
};
