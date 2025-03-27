const std = @import("std");

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
    EOF,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?[]const u8,
    line: usize,

    pub fn init(token_type: TokenType, lexeme: []const u8, literal: ?[]const u8, line: usize) Token {
        return Token{
            .type = token_type,
            .lexeme = lexeme,
            .literal = literal,
            .line = line,
        };
    }
};

pub fn printToken(token: Token) !void {
    const literal_display = if (token.literal) |lit| lit else "null";
    try std.io.getStdOut().writer().print("{s} {s} {s}\n", .{ @tagName(token.type), token.lexeme, literal_display });
}
