const Expr = @import("expr.zig").Expr;
const std = @import("std");

pub const AstPrinter = struct {
    pub fn print(writer: anytype, expression: *Expr) !void {
        try switch (expression.*) {
            .literal => |literal| std.fmt.format(writer, "{}", .{literal}),
        };
    }
};
