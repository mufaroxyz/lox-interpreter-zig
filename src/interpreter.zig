const Expressions = @import("expr.zig");
const std = @import("std");
const Value = @import("value.zig").Value;
const Util = @import("util.zig");
const Report = @import("report.zig").Report;

pub const InterpreterError = error{
    TypeMismatch,
    InvalidOperation,
    DivisionByZero,
};

pub const Interpreter = struct {
    had_error: bool,

    pub fn init() Interpreter {
        return Interpreter{
            .had_error = false,
        };
    }

    pub fn interpret(self: *Interpreter, expr: *Expressions.Expr, writer: anytype) !void {
        self.had_error = false;
        const value = self.evaluate(expr);

        if (self.had_error) return;

        try value.format(writer);
        try writer.writeByte('\n');
    }

    pub fn hadError(self: *const Interpreter) bool {
        return self.had_error;
    }

    fn reportError(self: *Interpreter, comptime fmt: []const u8, args: anytype) Value {
        self.had_error = true;
        Report.errln(fmt, args);
        return Value._nil();
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
                error.TypeMismatch => return self.reportError("Cannot add values of different types", .{}),
                error.InvalidOperation => return self.reportError("Cannot add values of these types", .{}),
                else => return self.reportError("Error during addition operation", .{}),
            },
            .MINUS => left.subtract(right) catch |err| switch (err) {
                error.TypeMismatch => return self.reportError("Cannot subtract a non-number from a value", .{}),
                error.InvalidOperation => return self.reportError("Cannot subtract from a non-number value", .{}),
            },
            .STAR => left.multiply(right) catch |err| switch (err) {
                error.TypeMismatch => return self.reportError("Cannot multiply a non-number with a value", .{}),
                error.InvalidOperation => return self.reportError("Cannot multiply a non-number value", .{}),
            },
            .SLASH => left.divide(right) catch |err| switch (err) {
                error.TypeMismatch => return self.reportError("Cannot divide a non-number by a value", .{}),
                error.InvalidOperation => return self.reportError("Cannot divide a non-number value", .{}),
                error.DivisionByZero => return self.reportError("Division by zero", .{}),
            },
            .GREATER => left.greaterThan(right, false) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => return self.reportError("Cannot compare non-numbers with > operator", .{}),
            },
            .GREATER_EQUAL => left.greaterThan(right, true) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => return self.reportError("Cannot compare non-numbers with >= operator", .{}),
            },
            .LESS => left.lessThan(right, false) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => return self.reportError("Cannot compare non-numbers with < operator", .{}),
            },
            .LESS_EQUAL => left.lessThan(right, true) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => return self.reportError("Cannot compare non-numbers with <= operator", .{}),
            },
            .EQUAL_EQUAL => left.eql(right, false) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => return self.reportError("Cannot compare these types with == operator", .{}),
            },
            .BANG_EQUAL => left.eql(right, true) catch |err| switch (err) {
                error.TypeMismatch, error.InvalidOperation => return self.reportError("Cannot compare these types with != operator", .{}),
            },
            else => return self.reportError("Unsupported binary operator: {s}", .{@tagName(binary.operator.type)}),
        };
    }

    fn evaluateUnary(self: *Interpreter, unary: Expressions.UnaryExpr) Value {
        const right = self.evaluate(unary.right);
        return switch (unary.operator.type) {
            .MINUS => switch (right) {
                .number => Value.fromNumber(-right.number),
                else => return self.reportError("Operand must be a number.", .{}),
            },
            .BANG => Value.fromBoolean(switch (right) {
                .number => right.number == 0,
                .string => right.string.len == 0,
                .boolean => !right.boolean,
                .nil => true,
            }),
            else => return self.reportError("Unsupported unary operator: {s}", .{@tagName(unary.operator.type)}),
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
