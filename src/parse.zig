const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Expr = @import("expr.zig").Expr;
const std = @import("std");

pub const ParserError = error{ UnexpectedToken, OutOfMemory, LiteralToStringParse };

pub const Parser = struct {
    tokens: []const Token,
    allocator: std.mem.Allocator,
    current: usize = 0,

    pub fn init(tokens: []const Token, allocator: std.mem.Allocator) Parser {
        return Parser{ .tokens = tokens, .allocator = allocator };
    }

    pub fn parse(self: *Parser) ParserError!*Expr {
        return try self.expression();
    }

    fn expression(self: *Parser) ParserError!*Expr {
        return try self.factor();
    }

    fn term(self: *Parser) ParserError!*Expr {}

    fn factor(self: *Parser) ParserError!*Expr {
        var expr = try self.unary();

        while (try self.match(.SLASH) or try self.match(.STAR)) {
            const operatorToken = self.previous();
            const rightExpr = try self.unary();
            std.debug.print("L: {any} , R: {any} \n", .{ expr, rightExpr });
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
        if (try self.match(.TRUE)) return try self.createExpression(.{ .literal = .{ .boolean = true } });
        if (try self.match(.FALSE)) return try self.createExpression(.{ .literal = .{ .boolean = false } });
        if (try self.match(.NIL)) return try self.createExpression(.{ .literal = .{ .nil = {} } });

        if (try self.match(.NUMBER) or try self.match(.STRING)) {
            const value = self.previous().literal.?.toString(self.allocator) catch {
                return ParserError.LiteralToStringParse;
            };
            return try self.createExpression(.{ .literal = .{ .literal = value } });
        }

        if (try self.match(.LEFT_PAREN)) {
            const expr = try self.expression();
            _ = try self.consume(.RIGHT_PAREN, "Expect ')' after expression.");
            return try self.createExpression(.{ .grouping = expr });
        }

        return ParserError.UnexpectedToken;
    }

    fn printError(_: *Parser, token: Token, message: []const u8) !Token {
        const writer = std.io.getStdOut().writer();
        std.fmt.format(writer, "[line {d}] Error: {s}\n", .{ token.line, message }) catch {
            return ParserError.UnexpectedToken;
        };
        return token;
    }

    fn consume(self: *Parser, @"type": TokenType, errorMessage: []const u8) ParserError!Token {
        if (self.check(@"type")) return try self.advance();

        return self.printError(self.peek(), errorMessage);
    }

    fn createExpression(self: *Parser, value: Expr) ParserError!*Expr {
        const expr = try self.allocator.create(Expr);
        errdefer self.allocator.destroy(expr);
        expr.* = value;
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
};
