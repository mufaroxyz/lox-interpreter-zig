const std = @import("std");

const Errors = error {
    TokenNotFound
};

pub const TokenType = enum {
    LEFT_PAREN, RIGHT_PAREN,
    EOF
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
    try std.io.getStdOut().writer().print("{s} {s} {any}\n", .{@tagName(token.type), token.lexeme, token.literal});
}
