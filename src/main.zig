const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const printToken = @import("token.zig").printToken;

const Errors = error{
    LexicalError,
};

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    if (!std.mem.eql(u8, command, "tokenize")) {
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

    scanner.scanTokens() catch |err| {
        if (err == Errors.LexicalError) {
            std.os.exit(65);
        }
    };

    for (scanner.tokens.items) |token| {
        try printToken(token);
    }
}
