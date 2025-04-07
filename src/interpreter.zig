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

    fn evaluateLiteral(_: *Interpreter, literal: Expressions.LiteralExpr) Value {
        return switch (literal) {
            .boolean => |b| Value{ .boolean = b },
            .nil => Value{ .nil = {} },
            .literal => |l| {
                // Check if the string is a numeric literal
                // If it's a valid number, convert it to a numeric Value
                if (std.fmt.parseFloat(f64, l)) |num| {
                    return Value{ .number = num };
                } else |_| {
                    // If not a number, treat as regular string
                    return Value{ .string = l };
                }
            },
        };
    }
};
