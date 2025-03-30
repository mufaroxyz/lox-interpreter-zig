const std = @import("std");

pub const Expr = union(enum) {
    literal: LiteralExpr,
};

pub const LiteralExpr = union(enum) {
    boolean: bool,
    nil: void,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .boolean => |b| try std.fmt.format(writer, "{}", .{b}),
            .nil => |_| try std.fmt.format(writer, "nil", .{}),
        }
    }
};
