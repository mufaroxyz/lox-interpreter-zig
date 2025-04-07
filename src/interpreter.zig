const Expressions = @import("expr.zig");
const std = @import("std");
const Value = @import("value.zig").Value;

pub const Interpreter = struct {
    pub fn init() Interpreter {
        return Interpreter{};
    }

    pub fn interpret(self: *Interpreter, expr: *Expressions.Expr, writer: anytype) !void {
        const value = self.evaluate(expr);
        try value.format(writer);
    }

    pub fn evaluate(self: *Interpreter, expr: *Expressions.Expr) Value {
        return switch (expr.*) {
            .literal => |val| Value.fromLiteralExpr(val),
            .grouping => |group_expr| self.evaluate(group_expr),
            else => @panic("Unsupported expression type"),
        };
    }
};
