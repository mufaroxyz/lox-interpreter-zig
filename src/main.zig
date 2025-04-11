const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const Parser = @import("parse.zig").Parser;
const AstPrinter = @import("ast.zig").AstPrinter;
const printToken = @import("token.zig").printToken;
const Util = @import("util.zig");
const Interpreter = @import("interpreter.zig").Interpreter;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    if (!std.mem.eql(u8, command, "tokenize") and !std.mem.eql(u8, command, "parse") and !std.mem.eql(u8, command, "evaluate") and !std.mem.eql(u8, command, "run")) {
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
    }

    if (scanner.hadError) {
        std.process.exit(65);
    }

    if (std.mem.eql(u8, command, "parse")) {
        var parser = Parser.init(resolvedTokens, allocator);
        defer parser.deinit();
        const expr = parser.parseExpression() catch |err| {
            std.debug.print("Error during parsing: {s}\n", .{@errorName(err)});
            std.process.exit(65);
        };
        // defer expr.deinit();

        // std.debug.print("Successfully parsed {} statements\n", .{statements.items.len});
        try AstPrinter.print(writer, expr);
    }

    if (std.mem.eql(u8, command, "evaluate")) {
        var parser = Parser.init(resolvedTokens, allocator);
        defer parser.deinit();

        const expr = parser.parseExpression() catch |err| {
            std.debug.print("Error during expression parsing: {s}\n", .{@errorName(err)});
            std.process.exit(70);
        };

        var interpreter = Interpreter.init();
        const result = interpreter.evaluate(expr);

        if (interpreter.hadError()) {
            std.process.exit(70);
        }

        try result.format("", .{}, writer);
        try writer.writeByte('\n');
    }

    if (std.mem.eql(u8, command, "run")) {
        var parser = Parser.init(resolvedTokens, allocator);
        defer parser.deinit();
        const statements = parser.parse() catch |err| {
            std.debug.print("Error during parsing: {s}\n", .{@errorName(err)});
            std.process.exit(65);
        };
        defer statements.deinit();

        var interpreter = Interpreter.init();
        try interpreter.interpret(statements);

        if (interpreter.hadError()) {
            std.process.exit(70);
        }
    }
}
