//! Hardware abstraction layer
const std = @import("std");

/// Interrupt service routine function type
pub const Isr = fn () callconv(.{ .arm_interrupt = .{} }) void;

/// Default priority grouping
pub const priogrp = 3;

/// Interrupt service request
pub const Irq = enum(u8) {
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
            4...15 => |n| @ptrCast(&regs.cpu.shpr[n - 4]),
            16...239 => |n| @ptrCast(&regs.cpu.nvic.ipr[n - 16]),
            else => null,
        };
    }

    /// Irq priority - bits specifies how many bits should be allocated to the group
    pub fn Priority(comptime bits: u3) type {
        return packed struct(u8) {
            subprio: std.meta.Int(.unsigned, 7 - bits) = 0,
            group: std.meta.Int(.unsigned, bits + 1) = 0,
        };
    }
};

/// Subgroup to initialize things to sane defaults
pub const config = struct {
    /// Initialize the system to a sane default
    pub fn system() void {
        // Enable flash caching
        regs.flash.acr.* = .{
            .icen = true, // Enable instruction cache
            .dcen = true, // Enable data cache
            .prften = true, // Enable prefetching
        };

        // Initialize interrupts by splitting group and sub priorities to gggg.pppp
        regs.cpu.aircr.prigroup = priogrp;
    }

    /// Initialize systick to 1ms
    pub fn systick() void {
        regs.cpu.systick.rvr.set(16000); // 16mhz, but we want it to be khz
        (Irq.systick.prio(priogrp) orelse unreachable).* = .{ .group = 0, .subprio = 0 };
        regs.cpu.systick.cvr.current = 0;
        regs.cpu.systick.csr.* = .{
            .enable = true,
            .tickint = true,
            .clksource = .internal,
        };
    }

    /// Default systemclock config with hse being the hse frequency
    pub fn systemclock(comptime hse: u32) void {
        // Enable the peripherial 1 block clock
        regs.rcc.apb1enr.pwren = true;
        _ = regs.rcc.apb1enr.pwren;

        // Set voltage scale for components
        regs.pwr.cr.vos = .scale1mode;

        // Setup rcc occilators
        regs.rcc.cr.hsion = false;
        regs.rcc.cr.hseon = true;
        regs.rcc.cr.pllon = true;
        regs.rcc.pllcfgr.* = .{
            .pllm = @intCast(@divExact(
                336 * hse,
                168 * regs.rcc.PllCfgr.DivisionFactor.@"2".factor(),
            )),
            .plln = 336,
            .pllp = .@"2",
            .pllsrc = .hse,
            .pllq = 7,
        };
        regs.rcc.cfgr.* = .{
            .sw = .hse,
            .hpre = .not_divided,
            .ppre1 = .@"4",
            .ppre2 = .@"2",
        };
        regs.flash.acr.latency = 5;
    }
};

/// Raw mmio registers
pub const regs = struct {
    /// Power controller registers
    pub const pwr = struct {
        /// Power control register
        pub const cr: *volatile Cr = @ptrFromInt(0x4000_7000 + 0x00);
        pub const Cr = packed struct(u32) {
            lpds: bool = false,
            pdds: bool = false,
            cwuf: bool = false,
            csbf: bool = false,
            pvde: bool = false,
            pls: Level = .@"2.0V",
            dbp: bool = false,
            fpds: bool = false,
            reserved13_10: u4 = 0,
            vos: ScaleMode = .scale1mode,
            reserved31_15: u17 = 0,

            /// PVD Level selection
            pub const Level = enum(u3) {
                @"2.0V",
                @"2.1V",
                @"2.3V",
                @"2.5V",
                @"2.6V",
                @"2.7V",
                @"2.8V",
                @"2.9V",
            };

            /// This bit controls the main internal voltage regulator output voltage to achieve a
            /// trade-off between performance and power consumption when the device does not operate
            /// at the maximum frequency
            pub const ScaleMode = enum(u1) { scale2mode, scale1mode };
        };
    };

    /// Gpio registers
    pub inline fn gpio(n: GpioId) *volatile Gpio {
        return @ptrFromInt(0x4002_0000 + @as(u32, @intFromEnum(n)) * 0x400);
    }
    pub const GpioId = enum { a, b, c, d, e, f, g, h, i };
    pub const Gpio = extern struct {
        moder: Moder, // 0x00
        padding0x13_0x04: [10]u8,
        odr: Odr,

        /// Port mode register
        pub const Moder = packed struct(u32) {
            modes: u32,

            /// Port mode
            pub const Mode = enum(u2) { input, output, alternate, analog };

            /// Get a port mode
            pub inline fn get(this: @This(), port: u4) Mode {
                return @enumFromInt(@as(u2, @truncate(this.modes >> @as(u5, port) * 2)));
            }

            /// Set a port mode
            pub inline fn set(this: *volatile @This(), port: u4, mode: Mode) void {
                var reg = this.modes;
                reg &= ~(@as(u32, 0b11) << @as(u5, port) * 2);
                reg |= @as(u32, @intFromEnum(mode)) << @as(u5, port) * 2;
                this.modes = reg;
            }

            /// Set many
            pub inline fn setMany(this: *volatile @This(), port: u4, modes: []const Mode) void {
                const mask: u32 = if (modes.len < 16)
                    (@as(u32, 1) << modes.len * 2) - 1
                else
                    0xffffffff;
                var reg = this.modes;
                reg &= ~(mask << @as(u5, port) * 2);
                for (modes) |mode| {
                    reg |= @as(u32, @intFromEnum(mode)) << @as(u5, port) * 2;
                }
                this.modes = reg;
            }
        };

        /// Output data register
        pub const Odr = packed struct(u32) {
            pins: u16,
            reserved31_16: u16,
        };
    };

    /// Reset and clock control registers
    pub const rcc = struct {
        /// Clock control register
        pub const cr: *volatile Cr = @ptrFromInt(0x4002_3800 + 0x00);
        pub const Cr = packed struct(u32) {
            hsion: bool = true,
            hsirdy: bool = true,
            reserved2: u1 = 0,
            hsitrim: u5 = 16,
            hsical: u8,
            hseon: bool = false,
            hserdy: bool = false,
            hsebyp: bool = false,
            csson: bool = false,
            reserved23_20: u4 = 0,
            pllon: bool = false,
            pllrdy: bool = false,
            plli2son: bool = false,
            plli2srdy: bool = false,
            reserved31_28: u4 = 0,
        };

        /// PLL configuration register
        pub const pllcfgr: *volatile PllCfgr = @ptrFromInt(0x4002_3800 + 0x04);
        pub const PllCfgr = packed struct(u32) {
            pllm: u6 = 16,
            plln: u9 = 192,
            reserved15: u1 = 0,
            pllp: DivisionFactor = .@"2",
            reserved21_18: u4 = 0,
            pllsrc: ClockSource = .hsi,
            reserved23: u1 = 0,
            pllq: u4 = 4,
            reserved31_28: u4 = 0,

            /// Main PLL division factor for main system clock
            pub const DivisionFactor = enum(u2) {
                @"2",
                @"4",
                @"6",
                @"8",

                /// Get the division factor
                pub fn factor(this: @This()) u32 {
                    return @as(u32, @intFromEnum(this)) * 2;
                }
            };

            /// Main PLL(PLL) and audio PLL (PLLI2S) entry clock source
            pub const ClockSource = enum(u1) { hsi, hse };
        };

        /// Clock configuration register
        pub const cfgr: *volatile Cfgr = @ptrFromInt(0x4002_3800 + 0x08);
        pub const Cfgr = packed struct(u32) {
            sw: SystemClockSource = .hsi,
            sws: SystemClockSource = .hsi,
            hpre: AhbPrescaler = .not_divided,
            reserved9_8: u2 = 0,
            ppre1: ApbPrescaler = .not_divided,
            ppre2: ApbPrescaler = .not_divided,
            rtcpre: u5 = 0,
            mco1: McoOutputClock(.@"1") = .hsi,
            i2ssrc: I2sClockSource = .plli2s,
            mco1pre: McoPrescaler = .not_divided,
            mco2pre: McoPrescaler = .not_divided,
            mco2: McoOutputClock(.@"2") = .sysclk,

            /// Set and cleared by software to select the system clock source
            pub const SystemClockSource = enum(u2) { hsi, hse, pll };

            /// Set and cleared by software. This bit allows to select the I2S clock source between
            /// the PLLI2S clock and the external clock
            pub const I2sClockSource = enum(u1) { plli2s, i2s_ckin };

            /// Set and cleared by software to control AHB clock division factor
            pub const AhbPrescaler = enum(u4) {
                not_divided,
                @"2" = 0b1000,
                @"4",
                @"8",
                @"16",
                @"64",
                @"128",
                @"256",
                @"512",
            };

            /// Set and cleared by software to control APB low-speed clock division factor
            pub const ApbPrescaler = enum(u3) {
                not_divided,
                @"2" = 0b100,
                @"4",
                @"8",
                @"16",
            };

            /// Set and cleared by software to configure the prescaler of the MCO1
            pub const McoPrescaler = enum(u3) {
                not_divided,
                @"2" = 0b100,
                @"3",
                @"4",
                @"5",
            };

            /// Microcontroller clock output
            pub fn McoOutputClock(comptime mco: enum { @"1", @"2" }) type {
                return switch (mco) {
                    .@"1" => enum(u2) { hsi, lse, hse, pll },
                    .@"2" => enum(u2) { sysclk, plli2s, hse, pll },
                };
            }
        };

        /// Peripheral clock enable register
        pub const ahb1enr: *volatile Ahb1Enr = @ptrFromInt(0x4002_3800 + 0x30);
        pub const Ahb1Enr = packed struct(u32) {
            gpioaen: bool = false,
            gpioben: bool = false,
            gpiocen: bool = false,
            gpioden: bool = false,
            gpioeen: bool = false,
            gpiofen: bool = false,
            gpiogen: bool = false,
            gpiohen: bool = false,
            gpioien: bool = false,
            reserved11_9: u3 = 0,
            crcen: bool = false,
            reserved17_13: u5 = 0,
            bkpsramen: bool = false,
            reserved19: u1 = 0,
            ccmdataramen: bool = true,
            dma1en: bool = false,
            dma2en: bool = false,
            reserved24_23: u2 = 0,
            ethmacen: bool = false,
            ethmactxen: bool = false,
            ethmacrxen: bool = false,
            ethmacptpen: bool = false,
            otghsen: bool = false,
            otghsulpien: bool = false,
            reserved31: u1 = 0,
        };

        /// Peripheral clock enable register
        pub const apb1enr: *volatile Apb1Enr = @ptrFromInt(0x4002_3800 + 0x34);
        pub const Apb1Enr = packed struct(u32) {
            tim2en: bool = false,
            tim3en: bool = false,
            tim4en: bool = false,
            tim5en: bool = false,
            tim6en: bool = false,
            tim7en: bool = false,
            tim12en: bool = false,
            tim13en: bool = false,
            tim14en: bool = false,
            reserved10_9: u2 = 0,
            wwdgen: bool = false,
            reserved13_12: u2 = 0,
            spi2en: bool = false,
            spi3en: bool = false,
            reserved16: u1 = 0,
            usart2en: bool = false,
            usart3en: bool = false,
            uart4en: bool = false,
            uart5en: bool = false,
            i2c1en: bool = false,
            i2c2en: bool = false,
            i2c3en: bool = false,
            reserved24: u1 = 0,
            can1en: bool = false,
            can2en: bool = false,
            reserved27: u1 = 0,
            pwren: bool = false,
            dacen: bool = false,
            reserved31_30: u2 = 0,
        };
    };

    /// Flash interface registers
    pub const flash = struct {
        /// Access control register
        pub const acr: *volatile Acr = @ptrFromInt(0x4002_3C00 + 0x00);
        pub const Acr = packed struct(u32) {
            latency: u3 = 0,
            reserved7_3: u5 = 0,
            prften: bool = false,
            icen: bool = false,
            dcen: bool = false,
            icrst: bool = false,
            dcrst: bool = false,
            reserved31_13: u19 = 0,
        };
    };

    /// Arm cortex-m4 registers
    pub const cpu = struct {
        /// Systick registers
        pub const systick = struct {
            /// Control and status register
            pub const csr: *volatile Csr = @ptrFromInt(0xe000_e010 + 0x00);
            pub const Csr = packed struct(u32) {
                enable: bool = true,
                tickint: bool = false,
                clksource: Source,
                reserved15_3: u13 = 0,
                countflag: bool = false,
                reserved31_17: u15 = 0,

                /// Clock source
                pub const Source = enum(u1) { external, internal };
            };

            /// Reload register
            pub const rvr: *volatile Rvr = @ptrFromInt(0xe000_e010 + 0x04);
            pub const Rvr = packed struct(u32) {
                reload: u24 = 0,
                reserved31_24: u8 = 0,

                /// Set the reload to occur on a set period of cycles
                pub fn set(this: *volatile @This(), n: u24) void {
                    this.reload = n - 1;
                }
            };

            /// Current value register
            pub const cvr: *volatile Cvr = @ptrFromInt(0xe000_e010 + 0x08);
            pub const Cvr = packed struct(u32) {
                current: u24 = 0,
                reserved31_24: u8 = 0,
            };

            /// Calibration register
            pub const calib: *volatile Calib = @ptrFromInt(0xe000_e010 + 0x0c);
            pub const Calib = packed struct(u32) {
                tenms: u24,
                reserved29_24: u6 = 0,
                skew: bool = false,
                noref: bool = false,
            };
        };

        /// Application interrupt and reset control register
        pub const aircr: *volatile Aircr = @ptrFromInt(0xe000_ed00 + 0x0c);
        pub const Aircr = packed struct(u32) {
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
        };

        /// System handler priority registers
        pub const shpr: *volatile [12]u8 = @ptrFromInt(0xe000_ed00 + 0x18);

        /// Coprocessor access register
        pub const cpacr: *volatile Cpacr = @ptrFromInt(0xe000_ed00 + 0x88);
        pub const Cpacr = packed struct(u32) {
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
        };

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
            pub const stir: *volatile Stir = @ptrFromInt(0xe000_ef00);
            pub const Stir = packed struct(u32) {
                intid: u8 = 0,
                reserved31_9: u24 = 0,
            };
        };
    };
};
