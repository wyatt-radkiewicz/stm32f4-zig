//! Main application code
const std = @import("std");

const hal = @import("hal.zig");

var ticks: u32 = 0;
var update_pins: bool = false;

/// Query handler for interrupts
pub fn isr(irq: hal.Irq) ?hal.Isr {
    return switch (irq) {
        .systick => struct {
            pub fn handler() callconv(.{ .arm_interrupt = .{} }) void {
                ticks += 1;
                if (ticks >= 100 and update_pins) {
                    hal.regs.gpio(.d).odr.pins +%= 1;
                    ticks = 0;
                }
            }
        }.handler,
        else => null,
    };
}

/// Main loop
pub fn main() void {
    // Enable sane defaults
    hal.config.system();
    hal.config.systick();
    hal.config.systemclock(8 * 1000 * 1000);

    // Initialize application
    hal.regs.rcc.ahb1enr.gpioden = true;
    hal.regs.gpio(.a).moder.setMany(0, &([1]hal.regs.Gpio.Moder.Mode{.output} ** 16));
    update_pins = true;

    // Run main loop
    while (true) {}
}
