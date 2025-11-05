//! Startup code
const std = @import("std");

const hal = @import("hal.zig");
const main = @import("main.zig");

/// Linker defined symbols and other important constants
const _initial_sp: u32 = 0x2002_0000;
const _data_src = @extern([*]const u8, .{ .name = "_data_src" });
const _data_dst = @extern([*]u8, .{ .name = "_data_dst" });
const _data_len = @extern(*allowzero const anyopaque, .{ .name = "_data_len" });
const _bss_addr = @extern([*]u8, .{ .name = "_bss_addr" });
const _bss_len = @extern(*allowzero const anyopaque, .{ .name = "_bss_len" });

/// Default isr implementation finder
fn unimplemented(comptime irq: hal.Irq) hal.Isr {
    return struct {
        fn handler() callconv(.{ .arm_interrupt = .{} }) void {
            while (switch (irq) {
                .svc, .debug_mon, .pend_sv, .systick => false,
                else => true,
            }) {}
        }
    }.handler;
}

/// Vector table
pub export const isr_vector linksection(".isr_vector") = blk: {
    @setEvalBranchQuota(496 * 1000);
    var pfns = [1]*allowzero const hal.Isr{@ptrFromInt(0x0000_0000)} ** 496;
    pfns[0] = @ptrFromInt(_initial_sp);
    pfns[1] = @ptrCast(&_start);
    for (2..@min(std.math.maxInt(std.meta.Tag(hal.Irq)) + 1, pfns.len)) |n| {
        const irq: hal.Irq = @enumFromInt(n);
        const func = main.isr(irq) orelse unimplemented(irq);
        pfns[n] = &func;
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
    @memcpy(_data_dst[0..@intFromPtr(_data_len)], _data_src[0..@intFromPtr(_data_len)]);

    // Zero out bss
    @memset(_bss_addr[0..@intFromPtr(_bss_len)], 0);

    // Call main
    _ = asm volatile (
        \\bl %[main]
        \\bx lr
        :
        : [main] "X" (&main.main),
        : .{
          .r0 = true,
          .r1 = true,
          .r2 = true,
          .r3 = true,
          .r12 = true,
          .r14 = true,
          .memory = true,
        });
}
