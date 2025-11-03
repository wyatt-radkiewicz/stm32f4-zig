//! Startup code
const hal = @import("hal.zig");
const main = @import("main.zig");

/// Linker defined symbols
const _initial_sp: *const u32 = @extern(*const u32, .{ .name = "_initial_sp" });
const _data_src: *const u32 = @extern(*const u32, .{ .name = "_data_src" });
const _data_dst: *const u32 = @extern(*const u32, .{ .name = "_data_dst" });
const _data_len: *const u32 = @extern(*const u32, .{ .name = "_data_len" });
const _bss_addr: *const u32 = @extern(*const u32, .{ .name = "_bss_addr" });
const _bss_len: *const u32 = @extern(*const u32, .{ .name = "_bss_len" });

/// Vector table
pub export const _vector_table linksection(".text._vector_table") = blk: {
    var vectors = [2]*const hal.Isr{ @ptrFromInt(_initial_sp), _start } ++
        [1]*const hal.Isr{unimplemented(true)} ** 494;
    for (2..vectors.len) |n| {
        if (main.isr(@enumFromInt(n))) |isr| {
            vectors[n] = isr;
        }
    }
    break :blk vectors;
};

/// Reset handler
pub export fn _start() linksection(".text._start") callconv(.naked) noreturn {
    // Enable access to floating point co-processor
    hal.regs.cpu.scb.cpacr.cp10 = .full;
    hal.regs.cpu.scb.cpacr.cp11 = .full;

    // Copy over data segment
    @memcpy(
        @as([*]u8, @ptrCast(_data_dst.*))[0.._data_len.*],
        @as([*]const u8, @ptrCast(_data_src.*))[0.._data_len.*],
    );

    // Zero out bss
    @memset(@as([*]u8, @ptrCast(_bss_addr.*))[0.._bss_len.*], 0);

    // Call main
    switch (@typeInfo(@typeInfo(@TypeOf(main.main)).@"fn".return_type orelse void)) {
        .error_union => main.main() catch {},
        else => main.main(),
    }
}

/// Unimplemented interrupt handler
fn unimplemented(loop: bool) hal.Isr {
    return struct {
        fn handler() callconv(.{ .arm_interrupt = .{} }) void {
            while (loop) {}
        }
    }.handler;
}
