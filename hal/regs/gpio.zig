//! Gpio registers
const packed_array = @import("../packed_array.zig");
const PackedArray = packed_array.PackedArray;

/// Get gpio port id
pub inline fn port(n: Port) *volatile Gpio {
    return @ptrFromInt(0x4002_0000 + @as(u32, @intFromEnum(n)) * 0x400);
}

/// Port enumeration
pub const Port = enum { a, b, c, d, e, f, g, h, i };

/// Gpio register block
pub const Gpio = extern struct {
    moder: PackedArray(Moder, 16, .output),
    padding0x13_0x04: [0x10]u8,
    odr: Odr,

    /// Port mode
    pub const Moder = enum(u2) {
        input,
        output,
        alternate,
        analog,
    };

    /// Output data register
    pub const Odr = packed struct(u32) {
        pins: u16,
        reserved31_16: u16,
    };
};
