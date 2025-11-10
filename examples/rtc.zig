//! Real time clock with alarm example
const std = @import("std");

const hal = @import("hal");

var ticks: u32 = 0;
var update_pins: bool = false;

/// Query handler for interrupts
pub fn isr(comptime irq: hal.Irq) ?hal.Isr {
    return switch (irq) {
        .systick => struct {
            pub fn systick() callconv(.{ .arm_interrupt = .{} }) void {
                ticks += 1;
                if (ticks >= 25 and update_pins) {
                    hal.regs.gpio(.d).odr.pins +%= 2;
                    ticks = 0;
                }
            }
        }.systick,
        else => null,
    };
}

/// Main loop
pub fn main() void {
    // Enable sane defaults
    hal.config.system();
    hal.config.systick(168 * 1000 * 1000);
    hal.config.systemclock(8 * 1000 * 1000);

    // Initialize application
    hal.regs.rcc.ahb1enr.gpioden = true;
    _ = hal.regs.rcc.ahb1enr.gpioden;
    hal.regs.gpio(.d).moder = .splat(.output);
    update_pins = true;

    // Run main loop
    while (true) {}
}
