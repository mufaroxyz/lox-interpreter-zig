const std = @import("std");

pub const Report = struct {
    // Global error state (thread-local)
    var had_error = false;

    pub fn resetError() void {
        had_error = false;
    }

    pub fn hadError() bool {
        return had_error;
    }

    pub fn out(comptime fmt: []const u8, args: anytype) void {
        const stdout = std.io.getStdOut().writer();
        stdout.print(fmt, args) catch |err_out| {
            std.debug.print("Error writing to stdout: {}\n", .{err_out});
        };
    }

    pub fn err(comptime fmt: []const u8, args: anytype) void {
        had_error = true;
        const stderr = std.io.getStdErr().writer();
        stderr.print(fmt, args) catch |err_err| {
            std.debug.print("Error writing to stderr: {}\n", .{err_err});
        };
    }

    pub fn outln(comptime fmt: []const u8, args: anytype) void {
        const stdout = std.io.getStdOut().writer();
        stdout.print(fmt ++ "\n", args) catch |err_outln| {
            std.debug.print("Error writing to stdout: {}\n", .{err_outln});
        };
    }

    pub fn errln(comptime fmt: []const u8, args: anytype) void {
        had_error = true;
        const stderr = std.io.getStdErr().writer();
        stderr.print(fmt ++ "\n", args) catch |err_errln| {
            std.debug.print("Error writing to stderr: {}\n", .{err_errln});
        };
    }

    pub fn runtimeError(line: usize, comptime fmt: []const u8, args: anytype) void {
        had_error = true;
        const stderr = std.io.getStdErr().writer();
        stderr.print("[line {d}] Error: " ++ fmt ++ "\n", .{line} ++ args) catch |err_runtime| {
            std.debug.print("Error writing to stderr: {}\n", .{err_runtime});
        };
    }
};
