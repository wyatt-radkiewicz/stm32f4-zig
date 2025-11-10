//! Potentiometer controlling led via pwm
const std = @import("std");

const hal = @import("hal");

/// Query handler for interrupts
pub fn isr(comptime irq: hal.int.Irq) ?hal.int.Isr {
    return switch (irq) {
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
    {}

    // Run main loop
    while (true) {}
}
