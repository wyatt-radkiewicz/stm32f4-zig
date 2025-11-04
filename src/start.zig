//! Startup code
const hal = @import("hal.zig");
const main = @import("main.zig");

/// Linker defined symbols
const _data_src: *const u32 = @extern(*const u32, .{ .name = "_data_src" });
const _data_dst: *const u32 = @extern(*const u32, .{ .name = "_data_dst" });
const _data_len: *const u32 = @extern(*const u32, .{ .name = "_data_len" });
const _bss_addr: *const u32 = @extern(*const u32, .{ .name = "_bss_addr" });
const _bss_len: *const u32 = @extern(*const u32, .{ .name = "_bss_len" });

/// Vector table
pub export const vectors linksection(".text._vectors") = blk: {
    var pfns = [2]*const hal.Isr{ @ptrFromInt(0x2002_0000), @ptrCast(&_start) } ++
        [1]*const hal.Isr{&unimplemented(true)} ** 494;
    for (2..pfns.len) |n| {
        if (main.isr(@enumFromInt(n))) |isr| {
            pfns[n] = &isr;
        }
    }
    const final = pfns;
    break :blk final;
};

/// Reset handler
pub export fn _start() callconv(.naked) noreturn {
    // Since this is as bare metal as it gets, disable runtime checks
    @setRuntimeSafety(false);

    // Enable access to floating point co-processor
    hal.regs.cpu.cpacr.cp10 = .full;
    hal.regs.cpu.cpacr.cp11 = .full;

    // Copy over data segment
    @memcpy(
        @as([*]u8, @ptrFromInt(_data_dst.*))[0.._data_len.*],
        @as([*]const u8, @ptrFromInt(_data_src.*))[0.._data_len.*],
    );

    // Zero out bss
    @memset(@as([*]u8, @ptrFromInt(_bss_addr.*))[0.._bss_len.*], 0);

    // Call main
    const main_pfn = &main.main;
    _ = asm volatile ("bx %[main]"
        :
        : [main] "r" (main_pfn),
        : .{});
}

/// Unimplemented interrupt handler
fn unimplemented(loop: bool) hal.Isr {
    return struct {
        fn handler() callconv(.{ .arm_interrupt = .{} }) void {
            while (loop) {}
        }
    }.handler;
}
