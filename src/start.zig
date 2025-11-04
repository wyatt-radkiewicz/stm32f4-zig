//! Startup code
const std = @import("std");

const hal = @import("hal.zig");
const main = @import("main.zig");

/// Linker defined symbols
const _data_src: *const u32 = @extern(*const u32, .{ .name = "_data_src" });
const _data_dst: *const u32 = @extern(*const u32, .{ .name = "_data_dst" });
const _data_len: *const u32 = @extern(*const u32, .{ .name = "_data_len" });
const _bss_addr: *const u32 = @extern(*const u32, .{ .name = "_bss_addr" });
const _bss_len: *const u32 = @extern(*const u32, .{ .name = "_bss_len" });

/// Default isr implementation finder
fn unimplemented(comptime irq: hal.Irq) hal.Isr {
    return struct {
        fn handler() callconv(.{ .arm_interrupt = .{} }) void {
            while (switch (irq) {
                .nmi, .hard_fault, .mem_manage, .bus_fault, .usage_fault => true,
                else => false,
            }) {}
        }
    }.handler;
}

/// Vector table
pub export const vectors linksection(".text._vectors") = blk: {
    @setEvalBranchQuota(496 * 1000);
    var pfns = [1]*allowzero const hal.Isr{@ptrFromInt(0x0000_0000)} ** 496;
    pfns[0] = @ptrFromInt(0x2002_0000);
    pfns[1] = @ptrCast(&_start);
    for (2..@min(std.math.maxInt(std.meta.Tag(hal.Irq)) + 1, pfns.len)) |n| {
        const irq: hal.Irq = @enumFromInt(n);
        pfns[n] = &(main.isr(irq) orelse unimplemented(irq));
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
