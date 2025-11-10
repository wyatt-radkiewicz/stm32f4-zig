//! Flash interface registers

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
