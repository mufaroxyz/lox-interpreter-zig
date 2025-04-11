const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Expr = @import("expr.zig").Expr;
const Stmt = @import("stmt.zig").Stmt;
const std = @import("std");

const DEBUG_LOGS = false;

pub const ParserError = error{ UnexpectedToken, OutOfMemory, LiteralToStringParse };

pub const Parser = struct {
    tokens: []const Token,
    allocator: std.mem.Allocator,
    current: usize = 0,
    allocated_expressions: std.ArrayList(*Expr),

    pub fn init(tokens: []const Token, allocator: std.mem.Allocator) Parser {
        return Parser{ .tokens = tokens, .allocator = allocator, .current = 0, .allocated_expressions = std.ArrayList(*Expr).init(allocator) };
    }

    pub fn deinit(self: *Parser) void {
        var freed = std.AutoHashMap(*Expr, void).init(self.allocator); // tracking set to avoid double free
        defer freed.deinit();

        for (self.allocated_expressions.items) |expr| {
            self.freeExpression(expr, &freed);
        }
        self.allocated_expressions.deinit();
    }

    fn freeExpression(self: *Parser, expr: *Expr, freed: *std.AutoHashMap(*Expr, void)) void {
        if (freed.contains(expr)) {
            return;
        }

        freed.put(expr, {}) catch {
            if (DEBUG_LOGS) std.debug.print("Failed to track freed expression\n", .{});
        };

        switch (expr.*) {
            .binary => |binary| {
                self.freeExpression(binary.left, freed);
                self.freeExpression(binary.right, freed);
            },
            .unary => |unaryexpr| {
                self.freeExpression(unaryexpr.right, freed);
            },
            .grouping => |grouping| {
                // free contained
                self.freeExpression(grouping, freed);
            },
            .literal => {},
        }
        // free itself
        self.allocator.destroy(expr);
    }

    pub fn parse(self: *Parser) ParserError!std.ArrayList(Stmt) {
        var statements = std.ArrayList(Stmt).init(self.allocator);
        errdefer {
            statements.deinit();
        }

        while (!self.isAtEnd()) {
            if (DEBUG_LOGS) {
                std.debug.print("Parse loop: current token type: {s}\n", .{@tagName(self.peek().type)});
            }
            if (self.peek().type == .EOF) break;

            try statements.append(try self.statement());
        }

        return statements;
    }

    fn statement(self: *Parser) ParserError!Stmt {
        if (try self.match(.PRINT)) return self.printStatement();

        return self.expressionStatement();
    }

    fn printStatement(self: *Parser) ParserError!Stmt {
        if (DEBUG_LOGS) std.debug.print("print statement\n", .{});
        const value = try self.expression();
        if (DEBUG_LOGS) std.debug.print("After print expression, current token: {s}\n", .{@tagName(self.peek().type)});
        _ = try self.consume(.SEMICOLON, "Expect ';' after value.\n");
        return Stmt{ .print = .{ .expression = value } };
    }

    fn expressionStatement(self: *Parser) ParserError!Stmt {
        if (DEBUG_LOGS) std.debug.print("expression statement peek: {s}\n", .{self.peek().lexeme});
        const expr = try self.expression();
        if (DEBUG_LOGS) std.debug.print("After expression, current token: {s}\n", .{@tagName(self.peek().type)});
        _ = try self.consume(.SEMICOLON, "Expect ';' after expression.\n");
        return Stmt{ .expression = .{ .expression = expr } };
    }

    fn expression(self: *Parser) ParserError!*Expr {
        return try self.eql();
    }

    fn eql(self: *Parser) ParserError!*Expr {
        var expr = try self.comparison();

        while (try self.match(.BANG_EQUAL) or try self.match(.EQUAL_EQUAL)) {
            const operatorToken = self.previous();
            const rightExpr = try self.comparison();
            expr = try self.createExpression(.{ .binary = .{ .left = expr, .operator = operatorToken, .right = rightExpr } });
        }

        return expr;
    }

    fn comparison(self: *Parser) ParserError!*Expr {
        var expr = try self.term();

        while (try self.match(.GREATER) or try self.match(.GREATER_EQUAL) or try self.match(.LESS) or try self.match(.LESS_EQUAL)) {
            const operatorToken = self.previous();
            const rightExpr = try self.term();
            expr = try self.createExpression(.{ .binary = .{ .left = expr, .operator = operatorToken, .right = rightExpr } });
        }

        return expr;
    }

    fn term(self: *Parser) ParserError!*Expr {
        var expr = try self.factor();

        while (try self.match(.PLUS) or try self.match(.MINUS)) {
            const operatorToken = self.previous();
            const rightExpr = try self.factor();
            expr = try self.createExpression(.{ .binary = .{ .left = expr, .operator = operatorToken, .right = rightExpr } });
        }

        return expr;
    }

    fn factor(self: *Parser) ParserError!*Expr {
        var expr = try self.unary();

        while (try self.match(.SLASH) or try self.match(.STAR)) {
            const operatorToken = self.previous();
            const rightExpr = try self.unary();
            expr = try self.createExpression(.{ .binary = .{ .left = expr, .operator = operatorToken, .right = rightExpr } });
        }

        return expr;
    }

    fn unary(self: *Parser) ParserError!*Expr {
        if (try self.match(.BANG) or try self.match(.MINUS)) {
            const operatorToken = self.previous();
            const rightExpr = try self.unary();
            return try self.createExpression(.{ .unary = .{ .operator = operatorToken, .right = rightExpr } });
        }

        return try self.primary();
    }
    fn primary(self: *Parser) ParserError!*Expr {
        if (DEBUG_LOGS) std.debug.print("primary: current token type: {s}\n", .{@tagName(self.peek().type)});

        if (try self.match(.TRUE)) return try self.createExpression(.{ .literal = .{ .boolean = true } });
        if (try self.match(.FALSE)) return try self.createExpression(.{ .literal = .{ .boolean = false } });
        if (try self.match(.NIL)) return try self.createExpression(.{ .literal = .{ .nil = {} } });

        if (try self.match(.NUMBER)) {
            const token = self.previous();
            if (DEBUG_LOGS) std.debug.print("Found NUMBER: {any}\n", .{token});
            if (token.literal) |literal| {
                if (literal == .number) {
                    return try self.createExpression(.{ .literal = .{ .number = literal.number } });
                }
            }
            return ParserError.LiteralToStringParse;
        }

        if (try self.match(.STRING)) {
            const token = self.previous();
            if (DEBUG_LOGS) std.debug.print("Found STRING: {s}\n", .{token.lexeme});
            if (token.literal) |literal| {
                if (DEBUG_LOGS) std.debug.print("Literal type: {s}\n", .{@tagName(literal)});
                if (literal == .string) {
                    return try self.createExpression(.{ .literal = .{ .string = literal.string } });
                }
            } else {
                if (DEBUG_LOGS) std.debug.print("No literal value in token\n", .{});
            }
            // Return a meaningful default instead of error
            return try self.createExpression(.{ .literal = .{ .string = token.lexeme } });
        }

        if (try self.match(.LEFT_PAREN)) {
            const expr = try self.expression();
            _ = try self.consume(.RIGHT_PAREN, "Expect ')' after expression.\n");
            return try self.createExpression(.{ .grouping = expr });
        }

        const writer = std.io.getStdErr().writer();
        const reportToken = self.peek();
        std.fmt.format(writer, "[line {d}] Error at '{s}': Expect expression\n", .{ reportToken.line, reportToken.lexeme }) catch {};

        return ParserError.UnexpectedToken;
    }

    fn consume(self: *Parser, @"type": TokenType, errorMessage: []const u8) ParserError!Token {
        if (DEBUG_LOGS) std.debug.print("consume: expecting {s}, got {s}\n", .{ @tagName(@"type"), @tagName(self.peek().type) });
        if (self.check(@"type")) return try self.advance();

        const writer = std.io.getStdErr().writer();
        std.fmt.format(writer, "[line {d}] Error: {s}", .{ self.peek().line, errorMessage }) catch {};

        return ParserError.UnexpectedToken;
    }

    fn createExpression(self: *Parser, value: Expr) ParserError!*Expr {
        const expr = try self.allocator.create(Expr);
        errdefer self.allocator.destroy(expr);
        expr.* = value;
        try self.allocated_expressions.append(expr);
        return expr;
    }

    fn previous(self: *Parser) Token {
        return self.tokens[self.current - 1];
    }

    fn isAtEnd(self: *Parser) bool {
        return self.current >= self.tokens.len;
    }

    fn check(self: *Parser, type_: TokenType) bool {
        if (self.isAtEnd()) return false;
        return self.peek().type == type_;
    }

    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }

    fn advance(self: *Parser) ParserError!Token {
        if (!self.isAtEnd()) {
            self.current += 1;
        }
        return self.previous();
    }

    fn match(self: *Parser, type_: TokenType) ParserError!bool {
        if (self.check(type_)) {
            _ = try self.advance();
            return true;
        }

        return false;
    }

    pub fn parseExpression(self: *Parser) ParserError!*Expr {
        return try self.expression();
    }
};
