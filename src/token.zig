const std = @import("std");
const Value = @import("value.zig").Value;

pub const TokenType = enum {
    // stop zls wrap
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,
    EQUAL,
    EQUAL_EQUAL,
    BANG,
    BANG_EQUAL,
    LESS,
    LESS_EQUAL,
    GREATER,
    GREATER_EQUAL,
    STRING,
    NUMBER,
    EOF,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?Value,
    line: usize,

    pub fn init(token_type: TokenType, lexeme: []const u8, literal: ?Value, line: usize) Token {
        return Token{
            .type = token_type,
            .lexeme = lexeme,
            .literal = literal,
            .line = line,
        };
    }
};

pub fn printToken(token: Token, allocator: std.mem.Allocator) !void {
    var literal_str: []const u8 = "null";
    var needs_free = false;

    if (token.literal) |literal| {
        literal_str = try literal.toString(allocator);
        if (literal == .number) needs_free = true;
    }

    std.debug.print("{s} {s} {s}\n", .{ @tagName(token.type), token.lexeme, literal_str });

    if (needs_free) {
        allocator.free(literal_str);
    }
}
