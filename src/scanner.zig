const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const std = @import("std");
const ArrayList = std.ArrayList;
const ScanError = @import("error.zig").ScanError;
const Value = @import("value.zig").Value;

pub const Scanner = struct {
    source: []const u8,
    tokens: ArrayList(Token),
    start: usize,
    current: usize,
    line: usize,
    hadError: bool,

    pub fn init(source: []const u8, allocator: std.mem.Allocator) Scanner {
        return Scanner{ .source = source, .start = 0, .current = 0, .line = 1, .tokens = ArrayList(Token).init(allocator), .hadError = false };
    }

    pub fn deinit(self: *Scanner) void {
        self.tokens.deinit();
    }

    fn match(self: *Scanner, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;

        self.current += 1;
        return true;
    }

    pub fn advance(self: *Scanner) u8 {
        self.current += 1;
        return self.source[self.current - 1]; // same as current++
    }

    pub fn peek(self: *Scanner) u8 {
        if (self.isAtEnd()) {
            return 0; // EOF
        }
        return self.source[self.current];
    }

    // used when needed to look at the character that was used after advancing the current position (off by one)
    // to remember: when advance() is called, current is incremented by 1 but the character used is the one before the increment
    pub fn peekBack(self: *Scanner) u8 {
        if (self.current == 0) {
            return 0; // EOF
        }
        return self.source[self.current - 1];
    }

    pub fn peekNext(self: *Scanner) u8 {
        if (self.current + 1 >= self.source.len) {
            return 0; // EOF
        }
        return self.source[self.current + 1];
    }

    pub fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    pub fn scanTokens(self: *Scanner) !void {
        while (!self.isAtEnd()) {
            self.start = self.current; // put at beginning of next lexeme.
            self.scanToken() catch |err| {
                // std.debug.print("scanToken#catch: {c}\n", .{self.peekBack()});

                if (err == ScanError.UnexpectedCharacter) {
                    self.hadError = true;
                    var buf: [1024]u8 = undefined;
                    const len = try std.fmt.bufPrint(&buf, "[line {d}] Error: Unexpected character: {c}\n", .{ self.line, self.peekBack() });
                    std.debug.print("{s}", .{len});
                } else if (err == ScanError.UnterminatedString) {
                    self.hadError = true;
                    var buf: [1024]u8 = undefined;
                    const len = try std.fmt.bufPrint(&buf, "[line {d}] Error: Unterminated string.\n", .{self.line});
                    std.debug.print("{s}", .{len});
                } else {
                    return err;
                }
            };
        }

        try self.tokens.append(Token.init(.EOF, "", null, self.line));
    }

    fn scanToken(self: *Scanner) !void {
        const c = self.advance();
        // std.debug.print("scanToken: {c}, current: {d}\n", .{ c, self.current });
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
            '*' => try self.addToken(.STAR),
            '=' => try self.addToken(
                if (self.match('=')) .EQUAL_EQUAL else .EQUAL,
            ),
            '!' => {
                try self.addToken(
                    if (self.match('=')) .BANG_EQUAL else .BANG,
                );
            },
            '<' => try self.addToken(
                if (self.match('=')) .LESS_EQUAL else .LESS,
            ),
            '>' => try self.addToken(
                if (self.match('=')) .GREATER_EQUAL else .GREATER,
            ),
            '/' => {
                if (self.match('/')) {
                    while (self.peek() != '\n' and !self.isAtEnd()) {
                        _ = self.advance();
                    }
                } else {
                    try self.addToken(.SLASH);
                }
            },
            '"' => try self.string(),

            ' ', '\r', '\t' => {},
            '\n' => {
                self.line += 1;
            },
            0 => try self.addToken(.EOF),
            else => {
                if (isDigit(c)) {
                    try self.number();
                    return;
                }

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

    fn addTokenWithLiteral(self: *Scanner, token_type: TokenType, literal: anytype) !void {
        const lexeme = self.source[self.start..self.current];
        try self.tokens.append(Token.init(
            token_type,
            lexeme,
            literal,
            self.line,
        ));
    }

    fn string(self: *Scanner) !void {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            return ScanError.UnterminatedString;
        }

        _ = self.advance();

        const value = self.source[self.start + 1 .. self.current - 1];
        const literalValue = Value.fromString(value);
        try self.addTokenWithLiteral(.STRING, literalValue);
    }

    fn number(self: *Scanner) !void {
        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();

            while (isDigit(self.peek())) {
                _ = self.advance();
            }
        }

        const value = self.source[self.start..self.current];
        const floatPtr = try std.fmt.parseFloat(f64, value);
        const literalValue = Value.fromNumber(floatPtr);
        try self.addTokenWithLiteral(.NUMBER, literalValue);
    }
};

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}
