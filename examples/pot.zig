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

    // Initialize led pins
    const port = hal.regs.Gpio.d.regs();
    port.moder.set(13, .alternate);
    port.moder.set(14, .alternate);
    port.moder.set(15, .alternate);
    port.afr.set(13, .tim3_5);
    port.afr.set(14, .tim3_5);
    port.afr.set(15, .tim3_5);

    // Initialize timer
    const tim = hal.regs.Tim.tim4.regs();
    tim.cr1.apre = true;
    tim.ccmr2.mode = .splat(.{ .output = .{
        .ccs = .output,
        .ocpe = true,
        .ocm = .pwm1,
    } });
    tim.ccmr1.mode.set(1, .{ .output = .{
        .ccs = .output,
        .ocpe = true,
        .ocm = .pwm1,
    } });
    

    // Run main loop
    while (true) {}
}
