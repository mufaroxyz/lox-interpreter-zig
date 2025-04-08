const Expressions = @import("expr.zig");
const std = @import("std");
const Value = @import("value.zig").Value;
const Util = @import("util.zig");

pub const Interpreter = struct {
    pub fn init() Interpreter {
        return Interpreter{};
    }

    pub fn interpret(self: *Interpreter, expr: *Expressions.Expr, writer: anytype) !void {
        const value = self.evaluate(expr);
        try value.format(writer);
        try writer.writeByte('\n');
    }

    pub fn evaluate(self: *Interpreter, expr: *Expressions.Expr) Value {
        return switch (expr.*) {
            .literal => |val| Value.fromLiteralExpr(val),
            .grouping => |group_expr| self.evaluate(group_expr),
            .unary => |unary_expr| self.evaluateUnary(unary_expr),
            .binary => |binary_expr| self.evaluateBinary(binary_expr),
        };
    }

    fn evaluateBinary(self: *Interpreter, binary: Expressions.BinaryExpr) Value {
        const left = self.evaluate(binary.left);
        const right = self.evaluate(binary.right);

        return switch (binary.operator.type) {
            .PLUS => left.add(right, std.heap.page_allocator) catch |err| switch (err) {
                error.TypeMismatch => @panic("Cannot add values of different types"),
                error.InvalidOperation => @panic("Cannot add values of these types"),
                else => @panic("Error during addition operation"),
            },
            .MINUS => left.subtract(right) catch |err| switch (err) {
                error.TypeMismatch => @panic("Cannot subtract a non-number from a value"),
                error.InvalidOperation => @panic("Cannot subtract from a non-number value"),
            },
            .STAR => left.multiply(right) catch |err| switch (err) {
                error.TypeMismatch => @panic("Cannot multiply a non-number with a value"),
                error.InvalidOperation => @panic("Cannot multiply a non-number value"),
            },
            .SLASH => left.divide(right) catch |err| switch (err) {
                error.TypeMismatch => @panic("Cannot divide a non-number by a value"),
                error.InvalidOperation => @panic("Cannot divide a non-number value"),
                error.DivisionByZero => @panic("Division by zero"),
            },
            .GREATER => left.greaterThan(right, false) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => @panic("Cannot compare a non-number"),
            },
            .GREATER_EQUAL => left.greaterThan(right, true) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => @panic("Cannot compare a non-number"),
            },
            .LESS => left.lessThan(right, false) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => @panic("Cannot compare a non-number"),
            },
            .LESS_EQUAL => left.lessThan(right, true) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => @panic("Cannot compare to a non-number"),
            },
            else => unreachable,
        };
    }

    fn evaluateUnary(self: *Interpreter, unary: Expressions.UnaryExpr) Value {
        const right = self.evaluate(unary.right);
        return switch (unary.operator.type) {
            .MINUS => Value.fromNumber(-right.number),
            .BANG => Value.fromBoolean(switch (right) {
                .number => right.number == 0,
                .string => right.string.len == 0,
                .boolean => !right.boolean,
                .nil => true,
            }),
            else => @panic("Unsupported unary operator"),
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
