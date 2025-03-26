const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Tokens = @import("token.zig").Tokens;
const Errors = @import("token.zig").Errors;
const std = @import("std");
const ArrayList = std.ArrayList;

pub const ScanError = error{
    UnexpectedCharacter,
};

pub const Scanner = struct {
    source: []const u8,
    tokens: ArrayList(Token),
    start: usize,
    current: usize,
    line: usize,
    hadError: bool,

    pub fn init(source: []const u8, allocator: std.mem.Allocator) Scanner {
        return Scanner{ .source = source, .start = 0, .current = 0, .line = 0, .tokens = ArrayList(Token).init(allocator), .hadError = false };
    }

    pub fn deinit(self: *Scanner) void {
        self.tokens.deinit();
    }

    pub fn advance(self: *Scanner) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    pub fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    pub fn scanTokens(self: *Scanner) !void {
        while (!self.isAtEnd()) {
            self.start = self.current; // put at beginning of next lexeme.
            self.scanToken() catch |err| {
                if (err == ScanError.UnexpectedCharacter) {
                    self.hadError = true;
                    var buf: [1024]u8 = undefined;
                    const len = try std.fmt.bufPrint(&buf, "[line: {d}] Error: Unexpected character '{c}'\n", .{ self.line, self.source[self.current] });
                    std.debug.print("{s}", .{len});
                }
            };
        }

        try self.tokens.append(Token.init(.EOF, "", null, self.line));
    }

    fn scanToken(self: *Scanner) !void {
        const c = self.advance();
        switch (c) {
            '(' => try self.addToken(.LEFT_PAREN),
            ')' => try self.addToken(.RIGHT_PAREN),
            '{' => try self.addToken(.LEFT_BRACE),
            '}' => try self.addToken(.RIGHT_BRACE),
            ',' => try self.addToken(.COMMA),
            '.' => try self.addToken(.DOT),
            '-' => try self.addToken(.MINUS),
            '+' => try self.addToken(.PLUS),
            ';' => try self.addToken(.SEMICOLON),
            '/' => try self.addToken(.SLASH),
            '*' => try self.addToken(.STAR),
            ' ', '\r' => {},
            0 => try self.addToken(.EOF),
            else => {
                return ScanError.UnexpectedCharacter;
            },
        }
    }

    fn addToken(self: *Scanner, token_type: TokenType) !void {
        const lexeme = self.source[self.start..self.current];
        try self.tokens.append(Token.init(
            token_type,
            lexeme,
            null,
            self.line,
        ));
    }
};
