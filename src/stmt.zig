const std = @import("std");
const Expr = @import("expr.zig").Expr;

pub const Stmt = union(enum) {
    expression: ExpressionStmt,
    print: PrintStmt,
};

pub const ExpressionStmt = struct {
    expression: *Expr,
};

pub const PrintStmt = struct {
    expression: *Expr,
};
