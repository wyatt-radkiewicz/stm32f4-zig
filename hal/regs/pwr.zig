//! Power controller registers

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
