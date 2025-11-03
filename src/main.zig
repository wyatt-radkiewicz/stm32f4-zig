//! Main application code
const std = @import("std");

const hal = @import("hal.zig");

/// Query handler for interrupts
pub fn isr(irq: hal.Irq) ?hal.Isr {
    return switch (irq) {
        .systick => struct {
            pub fn handler() callconv(.{ .arm_interrupt = .{} }) void {}
        }.handler,
        else => null,
    };
}

/// Main loop
pub fn main() void {
    while (true) {}
}
