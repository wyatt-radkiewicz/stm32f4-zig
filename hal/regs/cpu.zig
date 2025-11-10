//! Arm cortex-m4 registers
const std = @import("std");

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
        pub inline fn set(this: *volatile @This(), n: u24) void {
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
