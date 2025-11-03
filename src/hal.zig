//! Hardware abstraction layer
const std = @import("std");

/// Interrupt service routine function type
pub const Isr = fn () callconv(.{ .arm_interrupt = .{} }) void;

/// Interrupt service request
pub const Irq = enum(u9) {
    stack,
    reset,
    nmi,
    hard_fault,
    mem_manage,
    bus_fault,
    usage_fault,
    svc = 11,
    debug_mon,
    pend_sv = 14,
    systick,
    wwdg,
    pvd,
    tamp_stamp,
    rtc_wkup,
    flash,
    rcc,
    exti0,
    exti1,
    exti2,
    exti3,
    exti4,
    dma1_stream0,
    dma1_stream1,
    dma1_stream2,
    dma1_stream3,
    dma1_stream4,
    dma1_stream5,
    dma1_stream6,
    adc,
    can1_tx,
    can1_rx0,
    can1_rx1,
    can1_sce,
    exti9_5,
    tim1_brk_tim9,
    tim1_up_tim10,
    tim1_trg_com_tim11,
    tim1_cc,
    tim2,
    tim3,
    tim4,
    i2c1_ev,
    i2c1_er,
    i2c2_ev,
    i2c2_er,
    spi1,
    spi2,
    usart1,
    usart2,
    usart3,
    exti15_10,
    rtc_alarm,
    otg_fs_wkup,
    tim8_brk_tim12,
    tim8_up_tim13,
    tim8_trg_com_tim14,
    tim8_cc,
    dma1_stream7,
    fsmc,
    sdio,
    tim5,
    spi3,
    uart4,
    uart5,
    tim6_dac,
    tim7,
    dma2_stream0,
    dma2_stream1,
    dma2_stream2,
    dma2_stream3,
    dma2_stream4,
    eth,
    eth_wkup,
    can2_tx,
    can2_rx0,
    can2_rx1,
    can2_sce,
    otg_fs,
    dma2_stream5,
    dma2_stream6,
    dma2_stream7,
    usart6,
    i2c3_ev,
    i2c3_er,
    otg_hs_ep1_out,
    otg_hs_ep1_in,
    otg_hs_wkup,
    otg_hs,
    dcmi,
    cryp,
    hash_rng,
    fpu,
    _,

    /// Get a pointer to the priority of the instruction
    pub fn prio(this: @This(), comptime bits: u3) ?*volatile Priority(bits) {
        return switch (@intFromEnum(this)) {
            0...3 => null,
            4...15 => |n| @ptrCast(&regs.cpu.shpr[n - 4]),
            16...239 => |n| @ptrCast(&regs.cpu.nvic.ipr[n - 16]),
            else => null,
        };
    }

    /// Irq priority - bits specifies how many bits should be allocated to the group
    pub fn Priority(comptime bits: u3) type {
        return packed struct(u8) {
            subgroup: std.meta.Int(.unsigned, 7 - bits) = 0,
            group: std.meta.Int(.unsigned, bits + 1) = 0,
        };
    }
};

/// Initialize the system to a sane default
pub fn default() void {
    // Enable flash caching
    regs.flash.acr.* = .{
        .icen = true, // Enable instruction cache
        .dcen = true, // Enable data cache
        .prften = true, // Enable prefetching
    };

    // Initialize interrupts
    regs.cpu.scb.aircr.prigroup = 3; // Split priorities and sub priorities to xxxx.yyyy

    // Initialize systick
    regs.cpu.systick.rvr.set(16000); // 16mhz, but we want it to be khz
    (Irq.systick.prio(3) orelse unreachable) = .{ .group = 0, .subgroup = 0 };
    regs.cpu.systick.cvr.current = 0;
    regs.cpu.systick.csr.* = .{
        .enable = true,
        .tickint = true,
        .clksource = .internal,
    };
}

/// Raw mmio registers
pub const regs = struct {
    /// Flash interface registers
    pub const flash = struct {
        /// Access control register
        pub const acr: *volatile packed struct(u32) {
            latency: u3 = 0,
            reserved7_3: u5 = 0,
            prften: bool = false,
            icen: bool = false,
            dcen: bool = false,
            icrst: bool = false,
            dcrst: bool = false,
            reserved31_13: u19 = 0,
        } = @ptrFromInt(0x4002_3C00);
    };

    /// Arm cortex-m4 registers
    pub const cpu = struct {
        /// Systick registers
        pub const systick = struct {
            /// Control and status register
            pub const csr: *volatile packed struct(u32) {
                enable: bool = true,
                tickint: bool = false,
                clksource: Source,
                reserved15_3: u13 = 0,
                countflag: bool = false,
                reserved31_17: u15 = 0,

                /// Clock source
                pub const Source = enum(u1) { external, internal };
            } = @ptrFromInt(0xe000_e010);

            /// Reload register
            pub const rvr: *volatile packed struct(u32) {
                reload: u24 = 0,
                reserved31_24: u8 = 0,

                /// Set the reload to occur on a set period of cycles
                pub fn set(this: *@This(), n: u24) void {
                    this.reload = n - 1;
                }
            } = @ptrFromInt(0xe000_e014);

            /// Current value register
            pub const cvr: *volatile packed struct(u32) {
                current: u24 = 0,
                reserved31_24: u8 = 0,
            } = @ptrFromInt(0xe000_e018);

            /// Calibration register
            pub const calib: *volatile packed struct(u32) {
                tenms: u24,
                reserved29_24: u6 = 0,
                skew: bool = false,
                noref: bool = false,
            } = @ptrFromInt(0xe000_e01c);
        };

        /// Application interrupt and reset control register
        pub const aircr: *volatile packed struct(u32) {
            vectreset: bool = false,
            vectclractive: bool = false,
            sysresetreq: bool = false,
            reserved7_3: u5 = 0,
            prigroup: u3 = 0,
            reserved14_11: u4 = 0,
            endianness: Endian = .little,
            vectkey: u16 = 0xfa05,

            /// Hardware endianess
            pub const Endian = enum(u1) {
                little,
                big,
            };
        } = @ptrFromInt(0xe000_ed0c);

        /// System handler priority registers
        pub const shpr: *volatile [12]u8 = @ptrFromInt(0xe000_ed18);

        /// Coprocessor access register
        pub const cpacr: *volatile packed struct(u32) {
            reserved19_0: u20 = 0,
            cp10: Access = .denied,
            cp11: Access = .denied,
            reserved31_24: u8 = 0,

            /// Access privilege level
            pub const Access = enum(u2) {
                denied,
                privileged,
                reserved,
                full,
            };
        } = @ptrFromInt(0xe000_ed88);

        /// NVIC specific registers
        pub const nvic = struct {
            /// Interrupt set enable bits
            pub const iser: *volatile std.bit_set.ArrayBitSet(u32, 8) = @ptrFromInt(0xe000_e100);

            /// Interrupt clear enable bits
            pub const icer: *volatile std.bit_set.ArrayBitSet(u32, 8) = @ptrFromInt(0xe000_e180);

            /// Interrupt set pending enable bits
            pub const ispr: *volatile std.bit_set.ArrayBitSet(u32, 8) = @ptrFromInt(0xe000_e200);

            /// Interrupt clear pending enable bits
            pub const icpr: *volatile std.bit_set.ArrayBitSet(u32, 8) = @ptrFromInt(0xe000_e280);

            /// Interrupt active bits
            pub const iabr: *volatile std.bit_set.ArrayBitSet(u32, 8) = @ptrFromInt(0xe000_e300);

            /// Interrupt priority registers
            pub const ipr: *volatile [256]u8 = @ptrFromInt(0xe000_e400);

            /// Software trigger interrupt register
            pub const stir: *volatile packed struct(u32) {
                intid: u8 = 0,
                reserved31_9: u24 = 0,
            } = @ptrFromInt(0xe000_ef00);
        };
    };
};
