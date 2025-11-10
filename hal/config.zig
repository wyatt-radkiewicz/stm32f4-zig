//! Initialize things to sane defaults
const int = @import("int.zig");
const regs = @import("regs.zig");

/// Initialize the system to a sane default
pub fn system() void {
    // Enable flash caching
    regs.flash.acr.icen = true; // Enable instruction cache
    regs.flash.acr.dcen = true; // Enable data cache
    regs.flash.acr.prften = true; // Enable prefetching

    // Initialize interrupts by splitting group and sub priorities to gggg.pppp
    regs.cpu.aircr.prigroup = int.priogrp;
}

/// Initialize systick to 1ms
pub fn systick(comptime system_clock: usize) void {
    regs.cpu.systick.rvr.set(system_clock / 1000);
    regs.cpu.systick.cvr.current = 0;
    regs.cpu.systick.csr.* = regs.cpu.systick.Csr{
        .enable = true,
        .tickint = true,
        .clksource = .internal,
    };

    const prio = int.Irq.systick.prio(int.priogrp) orelse unreachable;
    prio.* = int.Irq.Priority(int.priogrp){ .group = 0, .subprio = 0 };
}

/// Default systemclock config with hse being the hse frequency
pub fn systemclock(comptime hse: u32) void {
    // Enable the peripherial 1 block clock
    regs.rcc.apb1enr.pwren = true;
    _ = regs.rcc.apb1enr.pwren;

    // Set voltage scale for components
    regs.pwr.cr.vos = .scale1mode;

    // Configure pll to run from hse and run at 168mHz
    regs.rcc.pllcfgr.* = regs.rcc.PllCfgr{
        .pllm = @intCast(@divExact(
            336 * hse,
            168 * 1000 * 1000 * regs.rcc.PllCfgr.DivisionFactor.@"2".factor(),
        )),
        .plln = 336,
        .pllp = .@"2",
        .pllsrc = .hse,
        .pllq = 7,
    };

    // Turn on hse, and pll occilators
    regs.rcc.cr.hsion = false;
    regs.rcc.cr.hseon = true;
    regs.rcc.cr.pllon = true;

    // Configure hardware clocks to run at hclk=168mHz, apb1=42mHz, apb2=84mHz
    regs.rcc.cfgr.* = regs.rcc.Cfgr{
        .sw = .pll,
        .hpre = .not_divided,
        .ppre1 = .@"4",
        .ppre2 = .@"2",
    };

    // Calibrate new flash latency
    regs.flash.acr.latency = 5;
}
