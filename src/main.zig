const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const Parser = @import("parse.zig").Parser;
const AstPrinter = @import("ast.zig").AstPrinter;
const printToken = @import("token.zig").printToken;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    if (!std.mem.eql(u8, command, "tokenize") and !std.mem.eql(u8, command, "parse")) {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.process.exit(1);
    }

    const file_contents = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, std.math.maxInt(usize));
    defer std.heap.page_allocator.free(file_contents);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var scanner = Scanner.init(file_contents, allocator);
    defer scanner.deinit();

    try scanner.scanTokens();

    const resolvedTokens = scanner.tokens.items;
    const writer = std.io.getStdOut().writer();

    if (std.mem.eql(u8, command, "tokenize")) {
        for (resolvedTokens) |token| {
            try printToken(token, allocator);
        }

        if (scanner.hadError) {
            std.process.exit(65);
        }
    }

    if (std.mem.eql(u8, command, "parse")) {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        var parser = Parser.init(resolvedTokens, arena.allocator());
        const expr = try parser.parse();

        try AstPrinter.print(writer, expr.?);
    }
}
