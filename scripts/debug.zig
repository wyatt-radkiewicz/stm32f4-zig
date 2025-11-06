//! Small debugger script
const std = @import("std");

/// Prints usage message
fn usage(stdout: *std.io.Writer, program: []const u8) !void {
    try stdout.print(
        \\usage:
        \\\t{s} <path to openocd> <arm eabi compatible gdb> <elf file>
    , .{program});
}

/// Trys to debug the device
fn debug(
    allocator: std.mem.Allocator,
    stdout: *std.io.Writer,
    prg_name: []const u8,
    args: *std.process.ArgIterator,
) !void {
    // Main settings and config
    const openocd_path = args.next() orelse {
        try usage(stdout, prg_name);
        return error.InvalidArgs;
    };
    const gdb_path = args.next() orelse {
        try usage(stdout, prg_name);
        return error.InvalidArgs;
    };
    const elf_path = args.next() orelse {
        try usage(stdout, prg_name);
        return error.InvalidArgs;
    };

    // Start up openocd server, halting first
    var openocd = std.process.Child.init(&.{
        openocd_path,
        "-f",
        "interface/stlink.cfg",
        "-f",
        "board/stm32f4discovery.cfg",
        "-c",
        "init; reset halt",
    }, allocator);
    openocd.stdout_behavior = .Ignore;
    openocd.stdin_behavior = .Ignore;
    openocd.stderr_behavior = .Ignore;
    try openocd.spawn();

    // Start up gdb
    var gdb = std.process.Child.init(&.{
        gdb_path,
        elf_path,
        "-ex",
        "target remote localhost:3333",
    }, allocator);
    gdb.stdout_behavior = .Inherit;
    gdb.stdin_behavior = .Inherit;
    gdb.stderr_behavior = .Inherit;
    _ = try gdb.spawnAndWait();

    // Shutdown openocd server
    _ = try openocd.kill();
}

/// Runs openocd in the background, runs the debugger in the foreground
pub fn main() !void {
    // Get our allocator and stdout
    const allocator = std.heap.smp_allocator;
    var buffer: [128]u8 = undefined;
    const writer = std.fs.File.stdout().writer(&buffer);
    var stdout = writer.interface;

    // Read in our argument list and figure out what to do
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    const prg_name = args.next() orelse @panic("Expected program name as first argument!");

    // Run the debug code
    try debug(allocator, &stdout, prg_name, &args);
}
