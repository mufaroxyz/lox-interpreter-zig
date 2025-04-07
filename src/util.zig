const std = @import("std");
const Parser = @import("parse.zig").Parser;
const Expr = @import("expr.zig").Expr;
const Token = @import("token.zig").Token;

pub fn parseTokens(tokens: []Token) *Expr {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();

    var parser = Parser.init(tokens, arena.allocator());
    const expr = parser.parse() catch {
        std.process.exit(65);
        return undefined;
    };

    return expr;
}

pub fn isFloat(comptime v: anytype) bool {
    const float: f64 = 0.0;
    return @TypeOf(v, float) == f64;
}
