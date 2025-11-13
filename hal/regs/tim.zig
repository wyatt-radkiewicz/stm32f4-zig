//! Timer registers
const packed_array = @import("../packed_array.zig");
const PackedArray = packed_array.PackedArray;

/// Timer number
pub const Tim = enum {
    tim1,
    tim2,
    tim3,
    tim4,
    tim5,
    tim6,
    tim7,
    tim8,
    tim9,
    tim10,
    tim11,
    tim12,
    tim13,
    tim14,

    /// Get timer n
    pub inline fn regs(this: @This()) *volatile this.Regs() {
        return @ptrFromInt(switch (this) {
            .tim1 => 0x4001_0000,
            .tim2,
            .tim3,
            .tim4,
            .tim5,
            .tim6,
            .tim7,
            => 0x4000_0000 + 400 * (this - @intFromEnum(.tim2)),
            .tim8 => 0x4001_0400,
            .tim9, .tim10, .tim11 => 0x4001_4000 + 400 * (this - @intFromEnum(.tim9)),
            .tim12, .tim13, .tim14 => 0x4000_1800 + 400 * (this - @intFromEnum(.tim12)),
        });
    }

    /// Timer register block
    pub fn Regs(comptime _: @This()) type {
        return extern struct {
            cr1: Cr1,
            padding0x17_0x04: [0x14]u8,
            ccmr1: Ccmr,
            ccmr2: Ccmr,
            ccer: u32,
            cnt: u32,
            psc: u32,

            /// control register 1
            pub const Cr1 = packed struct(u32) {
                cen: bool = false,
                udis: bool = false,
                urs: UpdateRequestSource = .default,
                opm: bool = false,
                dir: Direction = .up,
                cms: CenterAlignedMode = .edge,
                apre: bool = false,
                ckd: ClockDivision = .div1,

                /// Where do updates come from
                pub const UpdateRequestSource = enum(u1) { default, underflow_overflow };

                /// Counting direction
                pub const Direction = enum(u1) { up, down };

                /// Center-aligned mode
                pub const CenterAlignedMode = enum(u2) { edge, center_up, center_down, center };

                /// This bit-field indicates the division ratio between the timer clock (CK_INT)
                /// frequency and sampling clock used by the digital filters (ETR, TIx),
                pub const ClockDivision = enum(u2) { @"1", @"2", @"4" };
            };

            /// Capture/compare mode register
            pub const Ccmr = packed struct(u32) {
                mode: PackedArray(CaptureCompareMode, 2, .{ .output = .{} }),
                reserved: u16 = 0,
            };

            /// Capture compare mode
            pub const CaptureCompareMode = packed union {
                output: Output,
                input: u8,

                pub const Output = packed struct(u8) {
                    ccs: Selection = .output,
                    ocfe: bool = false,
                    ocpe: bool = false,
                    ocm: Mode = .frozen,
                    occe: bool = false,

                    /// Capture/compare selection
                    pub const Selection = enum(u2) {
                        output,
                        input_i2c_ti1,
                        input_i2c_ti2,
                        input_i2c_trc,
                    };

                    /// Output mode
                    pub const Mode = enum(u3) {
                        frozen,
                        active_on_match,
                        inactive_on_match,
                        toggle,
                        force_inactive,
                        force_active,
                        pwm1,
                        pwm2,
                    };
                };
            };
        };
    }
};
