//! Raw mmio registers
pub const cpu = @import("regs/cpu.zig");
pub const flash = @import("regs/flash.zig");
pub const gpio = @import("regs/gpio.zig");
pub const Gpio = gpio.Gpio;
pub const pwr = @import("regs/pwr.zig");
pub const rcc = @import("regs/rcc.zig");
pub const tim = @import("regs/tim.zig");
pub const Tim = tim.Tim;
