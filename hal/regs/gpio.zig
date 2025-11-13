//! Gpio registers
const packed_array = @import("../packed_array.zig");
const PackedArray = packed_array.PackedArray;

/// Gpio ports
pub const Gpio = enum {
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,

    /// Get gpio port id
    pub inline fn regs(this: @This()) *volatile Regs {
        return @ptrFromInt(0x4002_0000 + @as(u32, @intFromEnum(this)) * 0x400);
    }

    /// Gpio register block
    pub const Regs = extern struct {
        moder: PackedArray(Moder, 16, .output),
        padding0x13_0x04: [0x10]u8,
        odr: Odr,
        padding0x1f_0x18: [0x08]u8,
        afr: PackedArray(Af, 16, .system),

        /// Port mode
        pub const Moder = enum(u2) {
            input,
            output,
            alternate,
            analog,
        };

        /// Alternate function
        pub const Af = enum(u4) {
            system,
            tim1_tim2,
            tim3_5,
            tim8_11,
            i2c1_3,
            spi1_spi2,
            spi3,
            usart1_3,
            usart4_6,
            can1_can2_tim12_14,
            otg_fs_otg_hs,
            eth,
            fsmc_sdio_otg_hs,
            dcmi,
            eventout = 15,
            _,
        };

        /// Output data register
        pub const Odr = packed struct(u32) {
            pins: u16,
            reserved31_16: u16,
        };
    };
};
