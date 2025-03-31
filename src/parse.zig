const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Expr = @import("expr.zig").Expr;
const std = @import("std");

pub const Parser = struct {
    tokens: []const Token,
    allocator: std.mem.Allocator,
    current: usize = 0,

    pub fn init(tokens: []const Token, allocator: std.mem.Allocator) Parser {
        return Parser{ .tokens = tokens, .allocator = allocator };
    }

    pub fn parse(self: *Parser) !?*Expr {
        return try self.primary();
    }

    fn primary(self: *Parser) !*Expr {
        if (self.match(.TRUE)) return try self.createExpression(.{ .literal = .{ .boolean = true } });
        if (self.match(.FALSE)) return try self.createExpression(.{ .literal = .{ .boolean = false } });
        if (self.match(.NIL)) return try self.createExpression(.{ .literal = .{ .nil = {} } });

        if (self.match(.NUMBER) or self.match(.STRING)) {
            const value = self.previous().literal.?.toString(self.allocator) catch |err| {
                return err;
            };
            return try self.createExpression(.{ .literal = .{ .literal = value } });
        }

        if (self.match(.LEFT_PAREN)) {
            const expr = try self.primary();
            _ = try self.consume(.RIGHT_PAREN, "Expect ')' after expression.");
            return try self.createExpression(.{ .grouping = expr });
        }

        unreachable;
    }

    fn printError(_: *Parser, token: Token, message: []const u8) !Token {
        const writer = std.io.getStdOut().writer();
        try std.fmt.format(writer, "[line {d}] Error: {s}\n", .{ token.line, message });
        return token;
    }

    fn consume(self: *Parser, @"type": TokenType, errorMessage: []const u8) !Token {
        if (self.check(@"type")) return try self.advance();

        return self.printError(self.peek(), errorMessage);
    }

    fn createExpression(self: *Parser, value: Expr) !*Expr {
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

    fn advance(self: *Parser) !Token {
        if (!self.isAtEnd()) {
            self.current += 1;
        }
        return self.previous();
    }

    fn match(self: *Parser, type_: TokenType) bool {
        if (self.check(type_)) {
            _ = try self.advance();
            return true;
        }
        return false;
    }
};
